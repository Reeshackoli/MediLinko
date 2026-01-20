import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

/// Service to communicate with MediLinko backend for emergency features
/// The backend forwards requests to emergencyMed service
class EmergencyWebService {
  // MediLinko backend URL - always use production (local backend not running)
  static const String _baseUrl = 'https://medilinko.onrender.com';  // Production backend
  
  // Emergency web frontend URL for QR codes
  static const String _webFrontendUrl = 'https://medilinkoweb-emergency-frontend.onrender.com';
  
  // Key for storing emergency user ID
  static const String _emergencyUserIdKey = 'emergency_user_id';
  
  /// Get QR code URL for the current user
  /// First tries to use cached emergency user ID, then fetches from backend
  static Future<String?> getQRCodeUrl() async {
    try {
      // First check if we have a cached emergency user ID
      final prefs = await SharedPreferences.getInstance();
      final cachedEmergencyUserId = prefs.getString(_emergencyUserIdKey);
      
      if (cachedEmergencyUserId != null && cachedEmergencyUserId.isNotEmpty) {
        final qrUrl = '$_webFrontendUrl/profile/$cachedEmergencyUserId';
        debugPrint('✅ Using cached emergency user ID: $cachedEmergencyUserId');
        debugPrint('✅ QR URL: $qrUrl');
        return qrUrl;
      }
      
      // If no cached ID, try to fetch from backend
      final userData = await SessionManager.getUserSession();
      if (userData == null) {
        debugPrint('❌ No user data found');
        return null;
      }

      final token = userData['token'];
      if (token == null) {
        debugPrint('❌ No auth token found');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/emergency/qr-url'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final qrUrl = data['qrUrl'] as String?;
        final emergencyUserId = data['emergencyUserId'] as String?;
        
        // Cache the emergency user ID for future use
        if (emergencyUserId != null) {
          await prefs.setString(_emergencyUserIdKey, emergencyUserId);
          debugPrint('✅ Cached emergency user ID: $emergencyUserId');
        }
        
        debugPrint('✅ QR URL fetched: $qrUrl');
        return qrUrl;
      } else {
        debugPrint('❌ Failed to fetch QR URL: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching QR URL: $e');
      return null;
    }
  }  /// Sync user emergency data via MediLinko backend
  /// Backend forwards to emergencyMed service
  /// Returns the emergency user ID if sync is successful
  static Future<String?> syncEmergencyData({
    required String userId,
    required Map<String, dynamic> emergencyData,
  }) async {
    try {
      final userData = await SessionManager.getUserSession();
      final token = userData?['token'];
      
      if (token == null) {
        debugPrint('❌ No auth token found');
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/emergency/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'healthProfile': emergencyData,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final emergencyUserId = data['emergencyUserId'] as String?;
        
        // Save emergency user ID for QR code generation
        if (emergencyUserId != null && emergencyUserId.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_emergencyUserIdKey, emergencyUserId);
          debugPrint('✅ Emergency data synced. User ID: $emergencyUserId');
          return emergencyUserId;
        }
        
        debugPrint('✅ Emergency data synced successfully (no user ID returned)');
        return null;
      } else {
        debugPrint('❌ Failed to sync emergency data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error syncing emergency data: $e');
      return null;
    }
  }
  
  /// Get cached emergency user ID
  static Future<String?> getCachedEmergencyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emergencyUserIdKey);
  }
  
  /// Clear cached emergency user ID (e.g., on logout)
  static Future<void> clearCachedEmergencyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emergencyUserIdKey);
  }

  /// Check if emergency service is available via MediLinko backend
  static Future<bool> checkServiceHealth() async {
    try {
      final userData = await SessionManager.getUserSession();
      final token = userData?['token'];
      
      if (token == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/emergency/service-status'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Emergency service unavailable: $e');
      return false;
    }
  }
}
