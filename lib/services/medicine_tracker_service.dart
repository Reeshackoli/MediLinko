import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../core/constants/api_config.dart';
import '../models/user_medicine.dart';
import 'token_service.dart';
import 'notification_service_fcm.dart';

class MedicineTrackerService {
  static final TokenService _tokenService = TokenService();

  static Future<Map<String, dynamic>> addMedicine({
    required String medicineName,
    required String dosage,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    required List<MedicineDose> doses,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final requestBody = {
        'medicineName': medicineName,
        'dosage': dosage,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        'doses': doses.map((d) => d.toJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Schedule notifications for each dose
        try {
          for (var dose in doses) {
            final timeParts = dose.time.split(' ');
            final hourMinute = timeParts[0].split(':');
            int hour = int.parse(hourMinute[0]);
            final minute = int.parse(hourMinute[1]);
            
            // Convert to 24-hour format
            if (timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM' && hour != 12) {
              hour += 12;
            } else if (timeParts.length > 1 && timeParts[1].toUpperCase() == 'AM' && hour == 12) {
              hour = 0;
            }
            
            // Generate unique ID within 32-bit range (use hash of medicine name + time)
            final uniqueString = '$medicineName-${dose.time}';
            final notificationId = uniqueString.hashCode.abs() % 2147483647; // Max 32-bit int
            
            await NotificationService.scheduleMedicineReminder(
              id: notificationId,
              medicineName: medicineName,
              dosage: dosage,
              time: TimeOfDay(hour: hour, minute: minute),
            );
          }
        } catch (notifError) {
          // Log notification error but don't fail the whole operation
          debugPrint('⚠️ Error scheduling notifications: $notifError');
          // Medicine was still added successfully to database
        }
        
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to add medicine');
      }
    } catch (e) {
      debugPrint('❌ Error adding medicine: $e');
      throw Exception('Error adding medicine: $e');
    }
  }

  static Future<Map<String, List<dynamic>>> getCalendar({
    required int month,
    required int year,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicine-reminders/calendar?month=$month&year=$year'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final calendarData = data['data'] as Map<String, dynamic>;
        return calendarData.map((key, value) => MapEntry(key, value as List<dynamic>));
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch calendar');
      }
    } catch (e) {
      throw Exception('Error fetching calendar: $e');
    }
  }

  static Future<List<dynamic>> getMedicinesByDate(String date) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicine/by-date?date=$date'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] as List<dynamic>;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch medicines');
      }
    } catch (e) {
      throw Exception('Error fetching medicines: $e');
    }
  }

  static Future<Map<String, dynamic>> updateMedicine({
    required String medicineId,
    required String medicineName,
    required String dosage,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    required List<MedicineDose> doses,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final requestBody = {
        'medicineName': medicineName,
        'dosage': dosage,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (notes != null) 'notes': notes,
        'doses': doses.map((d) => d.toJson()).toList(),
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/$medicineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update medicine');
      }
    } catch (e) {
      debugPrint('❌ Error updating medicine: $e');
      throw Exception('Error updating medicine: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteMedicine(String medicineId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      debugPrint('📤 Deleting medicine: ${ApiConfig.baseUrl}/user-medicines/$medicineId');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/user-medicines/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to delete medicine');
      }
    } catch (e) {
      debugPrint('❌ Error deleting medicine: $e');
      throw Exception('Error deleting medicine: $e');
    }
  }
}
