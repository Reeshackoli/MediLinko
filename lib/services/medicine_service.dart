import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import 'token_service.dart';

class MedicineService {
  static final TokenService _tokenService = TokenService();

  static Future<Map<String, dynamic>> addMedicine({
    required String medicineName,
    required String batchNumber,
    required DateTime expiryDate,
    required int quantity,
    required double price,
    String? manufacturer,
    String? category,
    int lowStockLevel = 10,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'medicineName': medicineName,
          'batchNumber': batchNumber,
          'expiryDate': expiryDate.toIso8601String(),
          'quantity': quantity,
          'price': price,
          if (manufacturer != null) 'manufacturer': manufacturer,
          if (category != null) 'category': category,
          'lowStockLevel': lowStockLevel,
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

  static Future<Map<String, dynamic>> getAllMedicines({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicines?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
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
    String? batchNumber,
    DateTime? expiryDate,
    int? quantity,
    double? price,
    String? manufacturer,
    String? category,
    int? lowStockLevel,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> updateData = {};
      if (medicineName != null) updateData['medicineName'] = medicineName;
      if (batchNumber != null) updateData['batchNumber'] = batchNumber;
      if (expiryDate != null) updateData['expiryDate'] = expiryDate.toIso8601String();
      if (quantity != null) updateData['quantity'] = quantity;
      if (price != null) updateData['price'] = price;
      if (manufacturer != null) updateData['manufacturer'] = manufacturer;
      if (category != null) updateData['category'] = category;
      if (lowStockLevel != null) updateData['lowStockLevel'] = lowStockLevel;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/medicines/$medicineId'),
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
        Uri.parse('${ApiConfig.baseUrl}/medicines/$medicineId'),
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

  static Future<Map<String, dynamic>> getLowStockAlerts() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicines/alerts/low-stock'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch low stock alerts');
      }
    } catch (e) {
      throw Exception('Error fetching low stock alerts: $e');
    }
  }

  static Future<Map<String, dynamic>> getExpiringMedicines() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicines/alerts/expiring'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch expiring medicines');
      }
    } catch (e) {
      throw Exception('Error fetching expiring medicines: $e');
    }
  }

  static Future<Map<String, dynamic>> recordSale({
    required String medicineId,
    required int quantitySold,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = '${ApiConfig.baseUrl}/medicines/$medicineId/sale';
      print('🔵 POST $url');
      print('🔵 Body: {"quantitySold": $quantitySold}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'quantitySold': quantitySold,
        }),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to record sale');
      }
    } catch (e) {
      print('❌ Error in recordSale: $e');
      throw Exception('Error recording sale: $e');
    }
  }
}
