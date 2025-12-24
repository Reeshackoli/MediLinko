import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/doctor_location_model.dart';

class MapService {
  /// Get nearby doctors based on location
  static Future<Map<String, dynamic>> getNearbyDoctors({
    required double latitude,
    required double longitude,
    double radius = 5000, // Default 5km radius
    String? specialization,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radius.toString(),
        if (specialization != null && specialization.isNotEmpty)
          'specialization': specialization,
      };

      // Build URI with query parameters
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/doctors/nearby')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Parse doctors list
        final List<dynamic> doctorsJson = responseData['data'] ?? [];
        final List<DoctorLocationModel> doctors = doctorsJson
            .map((json) => DoctorLocationModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'doctors': doctors,
          'count': doctors.length,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch doctors',
          'doctors': <DoctorLocationModel>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'doctors': <DoctorLocationModel>[],
      };
    }
  }

  /// Get all doctors (fallback when location not available)
  static Future<Map<String, dynamic>> getAllDoctors({
    String? specialization,
    String? city,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (specialization != null && specialization.isNotEmpty) {
        queryParams['specialization'] = specialization;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/users/doctors')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.connectTimeout);
      
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> doctorsJson = responseData['data'] ?? [];
        
        final List<DoctorLocationModel> doctors = doctorsJson
            .where((json) => json['clinicLatitude'] != null && json['clinicLongitude'] != null)
            .map((json) => DoctorLocationModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'doctors': doctors,
          'count': doctors.length,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch doctors',
          'doctors': <DoctorLocationModel>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'doctors': <DoctorLocationModel>[],
      };
    }
  }
}
