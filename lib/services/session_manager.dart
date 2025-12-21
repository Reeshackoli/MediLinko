import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionManager {
  static const String _userDataKey = 'user_session_data';
  static const String _emergencyDataKey = 'emergency_data';

  // Save user session with critical medical data
  static Future<void> saveUserSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    
    // Extract and save emergency data separately for background service access
    await saveEmergencyData(
      name: userData['fullName'] ?? 'Unknown',
      bloodGroup: userData['bloodGroup'] ?? 'Unknown',
      allergies: userData['allergies'] ?? 'None listed',
      emergencyContactName: userData['emergencyContactName'] ?? 'Not set',
      emergencyContactPhone: userData['emergencyContactPhone'] ?? 'Not set',
      emergencyContactName2: userData['emergencyContactName2'] ?? '',
      emergencyContactPhone2: userData['emergencyContactPhone2'] ?? '',
    );
  }

  // Save emergency data for background service
  static Future<void> saveEmergencyData({
    required String name,
    required String bloodGroup,
    required String allergies,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String emergencyContactName2 = '',
    String emergencyContactPhone2 = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final emergencyData = {
      'name': name,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactName2': emergencyContactName2,
      'emergencyContactPhone2': emergencyContactPhone2,
    };
    await prefs.setString(_emergencyDataKey, jsonEncode(emergencyData));
  }

  // Get user session
  static Future<Map<String, dynamic>?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // Get emergency data (accessible from background service)
  static Future<Map<String, dynamic>?> getEmergencyData() async {
    final prefs = await SharedPreferences.getInstance();
    final emergencyData = prefs.getString(_emergencyDataKey);
    if (emergencyData != null) {
      return jsonDecode(emergencyData);
    }
    return null;
  }

  // Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_emergencyDataKey);
  }

  // Check if session exists
  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userDataKey);
  }
}
