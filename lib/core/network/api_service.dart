import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';

class ApiService {
  // Use ApiConfig for automatic production/development URL switching
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParameters);
      final headers = await _getHeaders(requiresAuth);
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint);
      final headers = await _getHeaders(requiresAuth);
      final response = await http.post(uri, headers: headers, body: json.encode(body));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint);
      final headers = await _getHeaders(requiresAuth);
      final response = await http.put(uri, headers: headers, body: json.encode(body));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(baseUrl + endpoint);
      final headers = await _getHeaders(requiresAuth);
      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, String>> _getHeaders(bool requiresAuth) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (requiresAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      return {'success': false, 'message': data['message'] ?? 'Request failed', 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Failed to parse response: $e', 'statusCode': response.statusCode};
    }
  }
}
