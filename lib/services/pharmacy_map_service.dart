import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/pharmacy_location_model.dart';

class PharmacyMapService {
  static Future<List<PharmacyLocationModel>> fetchAllPharmacies() async {
    try {
      final url = '${ApiConfig.baseUrl}/users/pharmacies';
      print('🌐 Fetching pharmacies from: $url');
      
      final response = await http.get(
        Uri.parse(url),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> pharmaciesJson = data['data'] ?? [];
        
        print('📊 Total pharmacies from API: ${pharmaciesJson.length}');
        if (pharmaciesJson.isNotEmpty) {
          print('📋 First pharmacy sample: ${pharmaciesJson.first}');
        }
        
        final pharmacies = pharmaciesJson
            .map((json) => PharmacyLocationModel.fromJson(json))
            .where((p) => p.latitude != 0.0 && p.longitude != 0.0)
            .toList();
            
        print('✅ Pharmacies after filtering: ${pharmacies.length}');
        return pharmacies;
      } else {
        throw Exception('Failed to load pharmacies');
      }
    } catch (e) {
      print('❌ Error fetching all pharmacies: $e');
      throw Exception('Error fetching pharmacies: $e');
    }
  }

  static Future<List<PharmacyLocationModel>> fetchNearbyPharmacies({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/nearby-pharmacies?lat=$latitude&lng=$longitude&radius=$radius'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> pharmaciesJson = data['data'] ?? [];
        
        return pharmaciesJson
            .map((json) => PharmacyLocationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load nearby pharmacies');
      }
    } catch (e) {
      print('Error fetching nearby pharmacies: $e');
      throw Exception('Error fetching nearby pharmacies: $e');
    }
  }
}
