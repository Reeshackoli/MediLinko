import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/api_config.dart';
import 'services/token_service.dart';
import 'services/notification_service.dart';

// Global navigator key for background navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global flag to track if session check is done
bool sessionCheckDone = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API configuration from saved preferences
  await ApiConfig.initialize();
  
  // Initialize notification service with callback
  await NotificationService.initialize(onNotificationTap: _handleNotificationTap);
  
  // Check session before starting app
  await _initializeSession();
  
  runApp(const ProviderScope(child: MyApp()));
}

// Handle notification tap from background
void _handleNotificationTap(String? payload) {
  debugPrint('🔔 Notification tapped with payload: $payload');
  
  if (payload == 'EMERGENCY_MODE') {
    // Force navigate to emergency screen
    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/emergency',
        (route) => false,
      );
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
