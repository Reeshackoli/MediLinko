import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../core/constants/api_config.dart';
import 'token_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.notification?.title}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static Function(String?)? _onNotificationTapCallback;
  static String? _fcmToken;

  // Initialize notification service with FCM
  static Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_isInitialized) return;

    _onNotificationTapCallback = onNotificationTap;

    // Initialize timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Set to IST

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapBackground,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Initialize Firebase Cloud Messaging
    await _initializeFCM();

    _isInitialized = true;
    debugPrint('✅ Notification service initialized with FCM');
  }

  // Initialize Firebase Cloud Messaging
  static Future<void> _initializeFCM() async {
    try {
      // Request notification permissions (iOS & Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📱 FCM Permission: ${settings.authorizationStatus}');

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $_fcmToken');

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken ?? '');

      // Save token to backend (will try to save, skip if no auth token yet)
      if (_fcmToken != null) {
        await _saveFCMTokenToBackend(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _saveFCMTokenToBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      // Check if app was opened from a terminated state notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageTap(initialMessage);
      }

      // Set foreground notification presentation options (iOS)
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('✅ FCM initialized successfully');
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getFCMToken() async {
    if (_fcmToken != null) return _fcmToken;
    
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  // Save FCM token to backend
  static Future<void> _saveFCMTokenToBackend(String token) async {
    try {
      debugPrint('💾 Attempting to save FCM token to backend...');
      
      final authToken = await TokenService().getToken();
      if (authToken == null) {
        debugPrint('⚠️ No auth token available to save FCM token');
        return;
      }

      debugPrint('✅ Auth token found, proceeding with FCM token save');

      final deviceType = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown';
      
      debugPrint('📤 Sending request to ${ApiConfig.baseUrl}/fcm/save-token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm/save-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'device': deviceType,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('💾 FCM token saved to backend successfully');
      } else {
        debugPrint('⚠️ Failed to save FCM token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token to backend: $e');
    }
  }

  // Handle foreground messages (when app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      _showLocalNotificationFromFCM(message);
    }
  }

  // Handle background message tap (when user taps notification)
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint('👆 User tapped notification: ${message.data}');
    
    // Route to appropriate screen based on notification type
    final type = message.data['type'];
    _onNotificationTapCallback?.call(type);
  }

  // Show local notification from FCM message
  static Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      message.data['channel_id'] ?? 'high_importance_channel',
      message.data['channel_name'] ?? 'High Importance Notifications',
      channelDescription: 'Important notifications from MediLinko',
      importance: Importance.high,
      priority: Priority.high,
      icon: android?.smallIcon ?? '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    const medicineChannel = AndroidNotificationChannel(
      'medicine_alerts',
      'Medicine Reminders',
      description: 'Notifications for medicine reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const appointmentChannel = AndroidNotificationChannel(
      'appointment_alerts',
      'Appointment Updates',
      description: 'Notifications for appointment status changes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Critical notifications from MediLinko',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(medicineChannel);
      await androidPlugin.createNotificationChannel(appointmentChannel);
      await androidPlugin.createNotificationChannel(highImportanceChannel);
      debugPrint('✅ Notification channels created');
    }
  }

  // Handle notification tap (foreground)
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Notification tapped (foreground): ${response.payload}');
    _onNotificationTapCallback?.call(response.payload);
  }

  // Handle notification tap (background) - must be top-level function
  @pragma('vm:entry-point')
  static void _onNotificationTapBackground(NotificationResponse response) {
    debugPrint('🔔 Notification tapped (background): ${response.payload}');
    _onNotificationTapCallback?.call(response.payload);
  }

  // ==================== MEDICINE REMINDERS ====================

  // Schedule medicine reminder (daily recurring)
  static Future<void> scheduleMedicineReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'medicine_alerts',
      'Medicine Reminders',
      channelDescription: 'Daily medicine reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '💊 Medicine Reminder',
      '$medicineName - $dosage',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    // Save reminder to SharedPreferences
    await _saveReminderToPrefs(id, medicineName, dosage, time);

    debugPrint('✅ Medicine reminder scheduled: $medicineName at ${time.format}');
  }

  // Cancel medicine reminder
  static Future<void> cancelMedicineReminder(int id) async {
    await _notifications.cancel(id);
    await _removeReminderFromPrefs(id);
    debugPrint('❌ Medicine reminder cancelled: ID $id');
  }

  // Get all scheduled reminders
  static Future<List<Map<String, dynamic>>> getScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('reminder_'));
    
    List<Map<String, dynamic>> reminders = [];
    for (String key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        // Parse stored reminder data (format: "medicineName|dosage|hour|minute")
        final parts = data.split('|');
        if (parts.length == 4) {
          reminders.add({
            'id': int.parse(key.replaceAll('reminder_', '')),
            'medicineName': parts[0],
            'dosage': parts[1],
            'hour': int.parse(parts[2]),
            'minute': int.parse(parts[3]),
          });
        }
      }
    }
    
    return reminders;
  }

  // Save reminder to SharedPreferences
  static Future<void> _saveReminderToPrefs(
    int id,
    String medicineName,
    String dosage,
    TimeOfDay time,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = '$medicineName|$dosage|${time.hour}|${time.minute}';
    await prefs.setString('reminder_$id', data);
  }

  // Remove reminder from SharedPreferences
  static Future<void> _removeReminderFromPrefs(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reminder_$id');
  }

  // ==================== APPOINTMENT NOTIFICATIONS ====================

  // Show new appointment notification (for doctors)
  static Future<void> showNewAppointmentNotification({
    required String patientName,
    required String date,
    required String time,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'appointment_alerts',
      'Appointment Updates',
      channelDescription: 'New appointment requests',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🔔 New Appointment Request',
      '$patientName requested an appointment on $date at $time',
      details,
      payload: 'appointment_request',
    );
  }

  // Show appointment status notification (for patients)
  static Future<void> showAppointmentStatusNotification({
    required String status,
    required String doctorName,
    required String date,
    required String time,
  }) async {
    final emoji = status == 'approved' ? '✅' : '❌';
    
    const androidDetails = AndroidNotificationDetails(
      'appointment_alerts',
      'Appointment Updates',
      channelDescription: 'Appointment status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$emoji Appointment $status',
      'Dr. $doctorName has $status your appointment on $date at $time',
      details,
      payload: 'appointment_status',
    );
  }

  // Show emergency notification with full-screen intent
  static Future<void> showEmergencyNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Critical fall detection emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '🚨 EMERGENCY: Fall Detected',
      'A fall has been detected. Emergency contacts have been notified.',
      details,
      payload: 'emergency',
    );
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    if (_isInitialized) {
      final settings = await _firebaseMessaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    return false;
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('❌ All notifications cancelled');
  }
}
