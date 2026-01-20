import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'session_manager.dart';

/// Service to communicate with MediLinko backend for emergency features
/// The backend forwards requests to emergencyMed service
class EmergencyWebService {
  // MediLinko backend URL - always use production (local backend not running)
  static const String _baseUrl = 'https://medilinko.onrender.com';  // Production backend
  
  /// Get QR code URL for the current user via MediLinko backend
  static Future<String?> getQRCodeUrl() async {
    try {
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
        debugPrint('✅ QR URL fetched: $qrUrl');
        return qrUrl;
      } else {
        debugPrint('❌ Failed to fetch QR URL: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching QR URL: $e');
      return null;
    }
  }  /// Sync user emergency data via MediLinko backend
  /// Backend forwards to emergencyMed service
  static Future<bool> syncEmergencyData({
    required String userId,
    required Map<String, dynamic> emergencyData,
  }) async {
    try {
      final userData = await SessionManager.getUserSession();
      final token = userData?['token'];
      
      if (token == null) {
        debugPrint('❌ No auth token found');
        return false;
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
        debugPrint('✅ Emergency data synced successfully');
        return true;
      } else {
        debugPrint('❌ Failed to sync emergency data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error syncing emergency data: $e');
      return false;
    }
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
