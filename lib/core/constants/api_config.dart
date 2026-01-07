import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Base URL for API - Now dynamically configurable!
  // Users can set this from Settings screen without changing code
  // 
  // Priority:
  // 1. User-configured URL (from Settings)
  // 2. Environment variable: flutter run --dart-define=API_URL=http://YOUR_IP:3000/api
  // 3. Default: Current computer IP (changes with WiFi)
  //
  // EASY SETUP OPTIONS:
  // - Option A: Set in app Settings screen (recommended for physical devices)
  // - Option B: Use your Render.com URL (for production)
  // - Option C: Current computer IP: 10.40.93.175 (for local testing)
  
  // PRODUCTION: Change this to your Render.com URL after deployment
  static String _cachedUrl = 'https://medilinko-api.onrender.com/api';
  static bool _isInitialized = false;
  
  /// Get base URL synchronously (use this in your code)
  static String get baseUrl => _cachedUrl;
  
  /// Initialize from stored preferences (call at app startup)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check if user has set a custom URL
      final savedUrl = prefs.getString('backend_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _cachedUrl = savedUrl;
        _isInitialized = true;
        return;
      }
      
      // 2. Check environment variable
      const envUrl = String.fromEnvironment('API_URL');
      if (envUrl.isNotEmpty) {
        _cachedUrl = envUrl;
        _isInitialized = true;
        return;
      }
      
      // 3. Use default IP
      const myDeviceIp = String.fromEnvironment('MY_IP', defaultValue: '10.40.93.175');
      _cachedUrl = 'http://$myDeviceIp:3000/api';
      _isInitialized = true;
    } catch (e) {
      // If anything fails, use default
      _cachedUrl = 'http://10.40.93.175:3000/api';
      _isInitialized = true;
    }
  }
  
  /// Manually update backend URL (called from Settings screen)
  static Future<void> setUrl(String url) async {
    try {
      final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      _cachedUrl = cleanUrl;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_url', cleanUrl);
    } catch (e) {
      // If save fails, at least update the cached value
      _cachedUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }
  
  /// Reset to default IP
  static Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('backend_url');
      
      const myDeviceIp = String.fromEnvironment('MY_IP', defaultValue: '10.40.93.175');
      _cachedUrl = 'http://$myDeviceIp:3000/api';
    } catch (e) {
      _cachedUrl = 'http://10.40.93.175:3000/api';
    }
  }
  
  /// Get saved URL from preferences
  static Future<String?> getSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('backend_url');
    } catch (e) {
      return null;
    }
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
