import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/prescription_model.dart';
import '../models/appointment_model.dart' show DoctorInfo, PatientInfo;
import 'token_service.dart';

class PrescriptionService {
  static final TokenService _tokenService = TokenService();
  static String get baseUrl => '${ApiConfig.baseUrl}/prescriptions';

  // Create a new prescription
  static Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    required String type,
    required String content,
    String? diagnosis,
    String? notes,
  }) async {
    try {
      final token = await _tokenService.getToken();
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientId': patientId,
          'type': type,
          'content': content,
          'diagnosis': diagnosis ?? '',
          'notes': notes ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'prescription': PrescriptionModel.fromJson(data['prescription']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create prescription',
        };
      }
    } catch (e) {
      print('Create prescription error: $e');
      return {
        'success': false,
        'message': 'Error creating prescription: $e',
      };
    }
  }

  // Get doctor's prescriptions
  static Future<Map<String, dynamic>> getDoctorPrescriptions({String? patientId}) async {
    try {
      final token = await _tokenService.getToken();
      
      String url = '$baseUrl/doctor';
      if (patientId != null) {
        url += '?patientId=$patientId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prescriptions = (data['prescriptions'] as List)
            .map((json) => PrescriptionModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'prescriptions': prescriptions,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch prescriptions',
        };
      }
    } catch (e) {
      print('Get doctor prescriptions error: $e');
      return {
        'success': false,
        'message': 'Error fetching prescriptions: $e',
      };
    }
  }

  // Get patient's prescriptions
  static Future<Map<String, dynamic>> getPatientPrescriptions({String? doctorId}) async {
    try {
      final token = await _tokenService.getToken();
      
      String url = '$baseUrl/patient';
      if (doctorId != null) {
        url += '?doctorId=$doctorId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prescriptions = (data['prescriptions'] as List)
            .map((json) => PrescriptionModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'prescriptions': prescriptions,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch prescriptions',
        };
      }
    } catch (e) {
      print('Get patient prescriptions error: $e');
      return {
        'success': false,
        'message': 'Error fetching prescriptions: $e',
      };
    }
  }

  // Get doctors who have prescribed to a patient
  static Future<Map<String, dynamic>> getPatientDoctors() async {
    try {
      final token = await _tokenService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/patient/doctors'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final doctors = (data['doctors'] as List)
            .map((json) => DoctorInfo.fromJson(json))
            .toList();

        return {
          'success': true,
          'doctors': doctors,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch doctors',
        };
      }
    } catch (e) {
      print('Get patient doctors error: $e');
      return {
        'success': false,
        'message': 'Error fetching doctors: $e',
      };
    }
  }

  // Get doctor's patients
  static Future<Map<String, dynamic>> getDoctorPatients() async {
    try {
      final token = await _tokenService.getToken();
      final url = '$baseUrl/doctor/patients';
      print('📋 Fetching doctor patients from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final patientsData = data['patients'] as List;
        print('👥 Number of patients in response: ${patientsData.length}');
        
        final patients = patientsData
            .map((json) => PatientInfo.fromJson(json))
            .toList();

        print('✅ Successfully parsed ${patients.length} patients');
        return {
          'success': true,
          'patients': patients,
        };
      } else {
        print('❌ Error response: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch patients',
        };
      }
    } catch (e) {
      print('❌ Get doctor patients error: $e');
      return {
        'success': false,
        'message': 'Error fetching patients: $e',
      };
    }
  }
}
