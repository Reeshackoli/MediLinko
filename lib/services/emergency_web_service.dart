import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'session_manager.dart';

/// Service to communicate with the emergencyMed web interface
/// Handles QR URL generation and emergency data synchronization
class EmergencyWebService {
  // Configure this to point to your emergencyMed backend
  static const String _baseUrl = 'http://localhost:5000'; // Change for production
  
  /// Get QR code URL for the current user
  /// This URL points to the emergencyMed web interface
  static Future<String?> getQRCodeUrl() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData == null) {
        debugPrint('❌ No user data found');
        return null;
      }

      final userId = userData['userId'] ?? userData['_id'];
      if (userId == null) {
        debugPrint('❌ No userId found in session');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId/qr-url'),
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
  }

  /// Sync user emergency data to emergencyMed database
  /// Call this when user updates their health profile
  static Future<bool> syncEmergencyData({
    required String userId,
    required Map<String, dynamic> emergencyData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/sync-emergency'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'emergencyData': emergencyData,
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

  /// Register user in emergencyMed system
  /// Call this during MediLinko user registration
  static Future<String?> registerEmergencyUser({
    required String medilinkoUserId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/register-from-medilinko'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'medilinkoUserId': medilinkoUserId,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final emergencyUserId = data['userId'] as String?;
        debugPrint('✅ User registered in emergencyMed: $emergencyUserId');
        return emergencyUserId;
      } else {
        debugPrint('❌ Failed to register in emergencyMed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error registering in emergencyMed: $e');
      return null;
    }
  }

  /// Check if emergencyMed service is available
  static Future<bool> checkServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ EmergencyMed service unavailable: $e');
      return false;
    }
  }

  /// Get emergency profile data from emergencyMed
  /// Used to verify sync status
  static Future<Map<String, dynamic>?> getEmergencyProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>?;
      } else {
        debugPrint('❌ Failed to fetch emergency profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching emergency profile: $e');
      return null;
    }
  }
}
