import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
    // Skip FCM on web platform
    if (kIsWeb) {
      debugPrint('⚠️ FCM not supported on web platform');
      return;
    }
    
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

      // Save token to backend immediately
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
        debugPrint('⚠️ No auth token found, cannot save FCM token');
        return;
      }

      debugPrint('✅ Auth token found, proceeding with FCM token save');

      final deviceType = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown';
      
      debugPrint('📤 Sending request to ${ApiConfig.baseUrl}/fcm/save-token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm/save-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
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

    // Determine channel based on notification type
    String channelId = 'high_importance_channel';
    String channelName = 'High Importance Notifications';
    
    final notificationType = message.data['type'];
    if (notificationType == 'medicine_reminder') {
      channelId = 'medicine_reminders';
      channelName = 'Medicine Reminders';
    } else if (notificationType == 'appointment') {
      channelId = 'appointment_alerts';
      channelName = 'Appointment Alerts';
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
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
      payload: jsonEncode(message.data),
    );
  }

  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    const medicineChannel = AndroidNotificationChannel(
      'medicine_reminders',
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

  // Show high-priority full-screen intent notification for emergency
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
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      color: Color(0xFFFF0000), // Red color
      ledColor: Color(0xFFFF0000),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'MEDICAL EMERGENCY',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      sound: 'default',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Emergency notification ID
      '🚨 MEDICAL EMERGENCY',
      'Fall detected! Tap to view emergency profile',
      details,
      payload: 'EMERGENCY_MODE',
    );

    debugPrint('🚨 Emergency notification sent with payload');
  }

  // Cancel emergency notification
  static Future<void> cancelEmergencyNotification() async {
    await _notifications.cancel(999);
    debugPrint('✅ Emergency notification cancelled');
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }
    
    final iosImpl = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return false;
  }

  // Schedule daily medicine reminder
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

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'medicine_alerts',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
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

    try {
      await _notifications.zonedSchedule(
        id,
        '💊 Medicine Reminder',
        '$medicineName - $dosage',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'medicine_$id',
      );

      debugPrint('✅ Medicine reminder scheduled: $medicineName at ${time.hour}:${time.minute}');
    } catch (e) {
      debugPrint('❌ Error scheduling medicine reminder: $e');
      rethrow;
    }
  }

  // Cancel medicine reminder
  static Future<void> cancelMedicineReminder(int id) async {
    await _notifications.cancel(id);
    debugPrint('✅ Medicine reminder cancelled: ID $id');
  }

  // Test notification (immediate)
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'medicine_alerts',
      'Medicine Reminders',
      channelDescription: 'Test notification',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
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
      999999,
      '🔔 Test Notification',
      'If you see this, notifications are working!',
      details,
      payload: 'test',
    );

    debugPrint('✅ Test notification sent');
  }

  // Get all scheduled notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Show appointment notification (for doctor - new appointment request)
  static Future<void> showNewAppointmentNotification({
    required String patientName,
    required String date,
    required String time,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'appointment_alerts',
      'Appointment Updates',
      channelDescription: 'Notifications for appointment status changes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
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
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '📅 New Appointment Request',
      'Patient: $patientName\n$date at $time',
      details,
      payload: 'appointment_new',
    );

    debugPrint('✅ New appointment notification sent');
  }

  // Show appointment status notification (for patient - appointment approved)
  static Future<void> showAppointmentStatusNotification({
    required String status,
    required String doctorName,
    required String date,
    required String time,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'appointment_alerts',
      'Appointment Updates',
      channelDescription: 'Notifications for appointment status changes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
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

    String title, body;
    if (status == 'approved') {
      title = '✅ Appointment Approved!';
      body = 'Dr. $doctorName\n$date at $time\nCheck details in app';
    } else if (status == 'rejected') {
      title = '❌ Appointment Rejected';
      body = 'Dr. $doctorName\n$date at $time';
    } else {
      title = '📅 Appointment Update';
      body = 'Status: $status\nDr. $doctorName';
    }

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: 'appointment_status_$status',
    );

    debugPrint('✅ Appointment status notification sent: $status');
  }

  // Schedule appointment reminder (1 hour before)
  static Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String doctorName,
    required DateTime scheduledTime,
  }) async {
    final scheduledTz = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'appointment_channel',
      'Appointment Notifications',
      channelDescription: 'Appointment reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
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
      appointmentId.hashCode,
      '⏰ Appointment Reminder',
      'Your appointment with Dr. $doctorName is in 1 hour',
      scheduledTz,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'appointment_reminder_$appointmentId',
    );

    debugPrint('✅ Appointment reminder scheduled for $scheduledTime');
  }
}
