import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/user_medicine.dart';
import 'token_service.dart';

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

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medicine/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'medicineName': medicineName,
          'dosage': dosage,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (notes != null) 'notes': notes,
          'doses': doses.map((d) => d.toJson()).toList(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to add medicine');
      }
    } catch (e) {
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
        Uri.parse('${ApiConfig.baseUrl}/medicine/calendar?month=$month&year=$year'),
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
    String? medicineName,
    String? dosage,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    List<MedicineDose>? doses,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> updateData = {};
      if (medicineName != null) updateData['medicineName'] = medicineName;
      if (dosage != null) updateData['dosage'] = dosage;
      if (startDate != null) updateData['startDate'] = startDate.toIso8601String();
      if (endDate != null) updateData['endDate'] = endDate.toIso8601String();
      if (notes != null) updateData['notes'] = notes;
      if (doses != null) updateData['doses'] = doses.map((d) => d.toJson()).toList();

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/medicine/update/$medicineId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update medicine');
      }
    } catch (e) {
      throw Exception('Error updating medicine: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteMedicine(String medicineId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/medicine/delete/$medicineId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to delete medicine');
      }
    } catch (e) {
      throw Exception('Error deleting medicine: $e');
    }
  }
}
