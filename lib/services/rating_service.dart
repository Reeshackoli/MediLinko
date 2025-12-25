import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import 'token_service.dart';

class RatingService {
  final TokenService _tokenService = TokenService();

  /// Submit a rating for a doctor or pharmacist
  Future<bool> submitRating({
    required String targetUserId,
    required int rating,
    String? review,
    String? appointmentId,
    String serviceType = 'general',
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        debugPrint('❌ Not authenticated');
        return false;
      }

      final body = {
        'targetUserId': targetUserId,
        'rating': rating,
        'serviceType': serviceType,
      };

      if (review != null && review.isNotEmpty) {
        body['review'] = review;
      }

      if (appointmentId != null) {
        body['appointmentId'] = appointmentId;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ratings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Rating submitted successfully');
        return true;
      } else {
        debugPrint('❌ Failed to submit rating: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error submitting rating: $e');
      return false;
    }
  }

  /// Get ratings for a doctor/pharmacist
  Future<Map<String, dynamic>?> getRatings(String userId, {int limit = 10, int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ratings/$userId?limit=$limit&page=$page'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching ratings: $e');
      return null;
    }
  }

  /// Get average rating for a user
  Future<Map<String, dynamic>?> getAverageRating(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ratings/$userId/average'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching average rating: $e');
      return null;
    }
  }

  /// Check if current user can rate a target
  Future<Map<String, dynamic>?> canRate(String targetUserId, {String? appointmentId}) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) return null;

      String url = '${ApiConfig.baseUrl}/ratings/can-rate/$targetUserId';
      if (appointmentId != null) {
        url += '?appointmentId=$appointmentId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error checking rate eligibility: $e');
      return null;
    }
  }
}
