import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import 'token_service.dart';

class ProfileService {
  static final TokenService _tokenService = TokenService();

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.profile),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Update complete profile
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      print('📤 Updating profile with data:');
      print('   Keys: ${profileData.keys.toList()}');
      if (profileData.containsKey('availableTimings')) {
        print('   ✅ availableTimings: ${profileData['availableTimings']}');
      }
      if (profileData.containsKey('availableDays')) {
        print('   ⚠️ OLD FORMAT - availableDays: ${profileData['availableDays']}');
      }
      if (profileData.containsKey('timeSlots')) {
        print('   ⚠️ OLD FORMAT - timeSlots: ${profileData['timeSlots']}');
      }

      final response = await http
          .put(
            Uri.parse(ApiConfig.profile),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(profileData),
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Update wizard step (partial update)
  static Future<Map<String, dynamic>> updateWizardStep(
      Map<String, dynamic> stepData) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http
          .patch(
            Uri.parse(ApiConfig.wizardStep),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(stepData),
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get health profile for a specific user (used by doctors to view patient profiles)
  static Future<Map<String, dynamic>> getHealthProfile(String userId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      print('📤 Fetching patient health profile: $userId');

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/profile/patient/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.connectTimeout);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      print('❌ Error fetching health profile: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}