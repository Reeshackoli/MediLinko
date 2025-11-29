import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';

class UserService {
  // Get all doctors
  static Future<Map<String, dynamic>> getDoctors({
    String? specialization,
    String? city,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (specialization != null) queryParams['specialization'] = specialization;
      if (city != null) queryParams['city'] = city;

      final uri = Uri.parse(ApiConfig.doctors).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
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

  // Get doctor by ID
  static Future<Map<String, dynamic>> getDoctorById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.doctors}/$id'),
            headers: {'Content-Type': 'application/json'},
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

  // Get all pharmacies
  static Future<Map<String, dynamic>> getPharmacies({String? city}) async {
    try {
      final queryParams = <String, String>{};
      if (city != null) queryParams['city'] = city;

      final uri = Uri.parse(ApiConfig.pharmacies).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
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

  // Get pharmacy by ID
  static Future<Map<String, dynamic>> getPharmacyById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.pharmacies}/$id'),
            headers: {'Content-Type': 'application/json'},
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
