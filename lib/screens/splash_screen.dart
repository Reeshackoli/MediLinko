import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Check if user has a saved token
      final tokenService = TokenService();
      final token = await tokenService.getToken();
      
      if (token != null && token.isNotEmpty) {
        // Try to get user info with saved token
        final response = await AuthService.getMe();
        
        if (response.success && response.data != null) {
          // User is logged in, restore session
          ref.read(authProvider.notifier).restoreUserModel(response.data!);
          
          // Navigate to appropriate dashboard based on role
          final user = response.data!;
          if (user.role == UserRole.user) {
            context.go('/user-dashboard');
          } else if (user.role == UserRole.doctor) {
            context.go('/doctor-dashboard');
          } else if (user.role == UserRole.pharmacist) {
            context.go('/pharmacist-dashboard');
          } else {
            context.go('/');
          }
          
          debugPrint('✅ User session restored - navigating to dashboard');
          return;
        } else {
          // Token invalid, clear it
          await tokenService.deleteToken();
          debugPrint('❌ Token invalid, cleared');
        }
      }
    } catch (e) {
      debugPrint('Error checking auth: $e');
    }
    
    // No valid session, go to onboarding
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.05),
              Colors.white,
              AppTheme.secondaryTeal.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo for splash screen
              Container(
                width: 250,
                height: 250,
                padding: const EdgeInsets.all(30),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.health_and_safety,
                        size: 120,
                        color: AppTheme.primaryBlue,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
              const SizedBox(height: 24),
              // App tagline
              Text(
                AppConstants.appTagline,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
