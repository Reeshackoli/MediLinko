import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL for API - Production first with local fallback
  // 
  // Production: https://medilinko.onrender.com/api
  // Development: http://10.0.2.2:3000/api (Android emulator)
  //
  // The app will automatically try production URL first.
  // If it fails, it will fall back to local development URL.
  
  /// Primary production URL
  static const String _productionUrl = 'https://medilinko.onrender.com/api';
  
  /// Fallback development URL for Android emulator
  static const String _developmentUrl = 'http://10.0.2.2:3000/api';
  
  /// Get base URL based on debug mode
  /// Production builds always use production URL
  /// For now, always use production URL (local backend not running)
  static String get baseUrl => _productionUrl; // Always use production
  
  /// Get production URL (always available)
  static String get productionUrl => _productionUrl;
  
  /// Get development URL (for local testing)
  static String get developmentUrl => _developmentUrl;
  
  /// Initialize API config (kept for compatibility, but no longer needed)
  static Future<void> initialize() async {
    // No initialization needed anymore
    // Kept for backward compatibility
  }
  
  // API Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get getMe => '$baseUrl/auth/me';
  static String get profile => '$baseUrl/profile';
  static String get wizardStep => '$baseUrl/profile/wizard';
  static String get doctors => '$baseUrl/users/doctors';
  static String get pharmacies => '$baseUrl/users/pharmacies';
  static String get health => '$baseUrl/health';
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
