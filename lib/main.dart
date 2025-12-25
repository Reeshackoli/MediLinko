import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/api_config.dart';
import 'services/token_service.dart';
import 'services/notification_service.dart';

// Global navigator key for background navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global flag to track if session check is done
bool sessionCheckDone = false;

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background FCM message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Request notification permissions for Android 13+
  await _requestNotificationPermissions();
  
  // Create notification channels
  await _createNotificationChannels();
  
  // Initialize API configuration from saved preferences
  await ApiConfig.initialize();
  
  // Initialize notification service with callback
  await NotificationService.initialize(onNotificationTap: _handleNotificationTap);
  
  // Check session before starting app
  await _initializeSession();
  
  runApp(const ProviderScope(child: MyApp()));
}

// Request notification permissions (Android 13+)
Future<void> _requestNotificationPermissions() async {
  final status = await Permission.notification.request();
  if (status.isGranted) {
    debugPrint('✅ Notification permission granted');
  } else if (status.isDenied) {
    debugPrint('⚠️ Notification permission denied');
  } else if (status.isPermanentlyDenied) {
    debugPrint('❌ Notification permission permanently denied');
    await openAppSettings();
  }
}

// Create notification channels for Android
Future<void> _createNotificationChannels() async {
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  
  // Medicine channel (High importance, sound enabled)
  const AndroidNotificationChannel medicineChannel = AndroidNotificationChannel(
    'medicine_reminders',
    'Medicine Reminders',
    description: 'Daily medicine reminder notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
  
  // Appointment channel (High importance, default sound)
  const AndroidNotificationChannel appointmentChannel = AndroidNotificationChannel(
    'appointment_channel',
    'Appointment Notifications',
    description: 'Appointment updates and reminders',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
  
  final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(medicineChannel);
    await androidPlugin.createNotificationChannel(appointmentChannel);
    debugPrint('✅ Notification channels created');
  }
}

// Handle notification tap from background
void _handleNotificationTap(String? payload) {
  debugPrint('🔔 Notification tapped with payload: $payload');
  
  if (payload == null) return;
  
  if (payload == 'EMERGENCY_MODE') {
    // Force navigate to emergency screen
    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/emergency',
        (route) => false,
      );
    });
  } else if (payload == 'medicine_reminder' || payload.contains('medicine_reminder')) {
    // Navigate to medicine tracker
    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamed('/medicine-tracker');
    });
  } else if (payload.contains('appointment')) {
    // Navigate to appointments
    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamed('/appointments');
    });
  }
}

Future<void> _initializeSession() async {
  try {
    final tokenService = TokenService();
    final token = await tokenService.getToken();
    
    if (token != null && token.isNotEmpty) {
      debugPrint('✅ Token found in storage');
    } else {
      debugPrint('❌ No token found');
    }
  } catch (e) {
    debugPrint('Error initializing session: $e');
  } finally {
    sessionCheckDone = true;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MediLinko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}