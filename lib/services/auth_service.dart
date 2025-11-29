import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'token_service.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : null,
      statusCode: json['statusCode'] as int?,
    );
  }
}

class AuthService {
  static final TokenService _tokenService = TokenService();

  // Register new user
  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': fullName,
              'email': email,
              'phone': phone,
              'password': password,
              'role': role.name,
            }),
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        // Save token
        if (responseData['data']['token'] != null) {
          await _tokenService.saveToken(responseData['data']['token']);
        }

        return ApiResponse(
          success: true,
          message: responseData['message'],
          data: responseData['data'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Login user
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token
        if (responseData['data']['token'] != null) {
          await _tokenService.saveToken(responseData['data']['token']);
        }

        return ApiResponse(
          success: true,
          message: responseData['message'],
          data: responseData['data'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Get current user
  static Future<ApiResponse<UserModel>> getMe() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.getMe),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.connectTimeout);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return ApiResponse(
          success: true,
          message: responseData['message'],
          data: UserModel.fromJson(responseData['data']),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to get user data',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Logout
  static Future<void> logout() async {
    await _tokenService.deleteToken();
  }
}
