import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Function(String?)? _onNotificationTapCallback;

  // Initialize notification service with callback
  static Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_isInitialized) return;

    _onNotificationTapCallback = onNotificationTap;

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

    _isInitialized = true;
    debugPrint('✅ Notification service initialized');
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
}
