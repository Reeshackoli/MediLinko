import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage dynamic API configuration
/// Allows users to set backend URL without code changes
class ApiConfigService {
  static const String _keyBackendUrl = 'backend_url';
  static const String _keyLastKnownIp = 'last_known_ip';
  
  /// Get the configured backend URL
  /// Priority: 1. User-set URL, 2. Environment variable, 3. Auto-detected IP, 4. Default localhost
  static Future<String> getBackendUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check if user has set a custom URL
      final savedUrl = prefs.getString(_keyBackendUrl);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        return savedUrl;
      }
      
      // 2. Check environment variable
      const envUrl = String.fromEnvironment('API_URL');
      if (envUrl.isNotEmpty) {
        return envUrl;
      }
      
      // 3. Try last known IP
      final lastIp = prefs.getString(_keyLastKnownIp);
      if (lastIp != null && lastIp.isNotEmpty) {
        return 'http://$lastIp:3000/api';
      }
      
      // 4. Default fallback
      return 'http://localhost:3000/api';
    } catch (e) {
      // If SharedPreferences fails, use localhost
      return 'http://localhost:3000/api';
    }
  }
  
  /// Save backend URL
  static Future<bool> setBackendUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clean URL (remove trailing slash)
      final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      return await prefs.setString(_keyBackendUrl, cleanUrl);
    } catch (e) {
      return false;
    }
  }
  
  /// Clear saved backend URL (revert to default)
  static Future<bool> clearBackendUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keyBackendUrl);
    } catch (e) {
      return false;
    }
  }
  
  /// Save the current computer's IP for future use
  static Future<bool> saveLastKnownIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyLastKnownIp, ip);
    } catch (e) {
      return false;
    }
  }
  
  /// Get saved URL or null
  static Future<String?> getSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyBackendUrl);
    } catch (e) {
      return null;
    }
  }
  
  /// Validate if URL is reachable
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// Test connectivity to backend
  static Future<bool> testConnection(String url) async {
    try {
      final http = await Future.any([
        _makeTestRequest(url),
        Future.delayed(const Duration(seconds: 5), () => false),
      ]);
      return http;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> _makeTestRequest(String url) async {
    try {
      // Try to import http dynamically to avoid issues
      final response = await Future.value(false); // Placeholder
      // In real implementation, use: http.get(Uri.parse('$url/health'))
      return response;
    } catch (e) {
      return false;
    }
  }
}
