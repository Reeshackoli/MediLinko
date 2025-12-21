import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/appointment_model.dart';
import 'token_service.dart';

class AppointmentService {
  static final TokenService _tokenService = TokenService();

  // Book appointment
  static Future<Map<String, dynamic>> bookAppointment({
    required String doctorId,
    required String date,
    required String time,
    String? symptoms,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        print('❌ No token found');
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final requestBody = {
        'doctorId': doctorId,
        'date': date,
        'time': time,
        'symptoms': symptoms ?? '',
      };

      print('📤 Booking appointment:');
      print('   URL: ${ApiConfig.baseUrl}/appointments/book');
      print('   Body: $requestBody');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/appointments/book'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConfig.connectTimeout);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      print('❌ Booking error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get user appointments
  static Future<Map<String, dynamic>> getUserAppointments({String? status}) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      String url = '${ApiConfig.baseUrl}/appointments';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['success'] == true && responseData['appointments'] != null) {
        final List<AppointmentModel> appointments = (responseData['appointments'] as List)
            .map((json) => AppointmentModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'appointments': appointments,
          'count': responseData['count'] ?? 0,
        };
      }

      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get doctor appointments
  static Future<Map<String, dynamic>> getDoctorAppointments({String? status, String? date}) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        print('❌ No authentication token found for doctor appointments');
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      String url = '${ApiConfig.baseUrl}/appointments/doctor';
      List<String> params = [];
      if (status != null) params.add('status=$status');
      if (date != null) params.add('date=$date');
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      print('📤 Fetching doctor appointments from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.connectTimeout);

      print('📥 Doctor appointments response status: ${response.statusCode}');
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print('📋 Doctor appointments count: ${responseData['count'] ?? 0}');

      if (responseData['success'] == true && responseData['appointments'] != null) {
        final List<AppointmentModel> appointments = (responseData['appointments'] as List)
            .map((json) => AppointmentModel.fromJson(json))
            .toList();

        print('✅ Loaded ${appointments.length} doctor appointments');
        return {
          'success': true,
          'appointments': appointments,
          'count': responseData['count'] ?? 0,
        };
      }

      print('⚠️ Doctor appointments response: ${responseData['message'] ?? 'Unknown error'}');
      return responseData;
    } catch (e) {
      print('❌ Error fetching doctor appointments: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get available slots
  static Future<Map<String, dynamic>> getAvailableSlots({
    required String doctorId,
    required String date,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/appointments/slots?doctorId=$doctorId&date=$date'),
            headers: {
              'Content-Type': 'application/json',
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

  // Update appointment status
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
    String? reason,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        print('❌ No authentication token found');
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final requestBody = {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      print('📤 Updating appointment status:');
      print('   URL: ${ApiConfig.baseUrl}/appointments/$appointmentId/status');
      print('   Appointment ID: $appointmentId');
      print('   Status: $status');
      print('   Reason: ${reason ?? 'N/A'}');
      print('   Token: ${token.substring(0, 20)}...');

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId/status'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(ApiConfig.connectTimeout);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Appointment status updated successfully');
      } else {
        print('⚠️ Server returned non-success status: ${response.statusCode}');
      }
      
      return responseData;
    } catch (e) {
      print('❌ Error updating appointment status: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get appointment stats for doctor
  static Future<Map<String, dynamic>> getAppointmentStats() async {
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
            Uri.parse('${ApiConfig.baseUrl}/appointments/stats'),
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
}
