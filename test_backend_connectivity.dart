import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Quick test to verify backend connectivity
/// Run this to check if the app can reach the backend
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 Testing Backend Connectivity...\n');
  
  // Check what URL the app will use
  final isDebugMode = kDebugMode;
  final productionUrl = 'https://medilinko.onrender.com/api';
  final developmentUrl = 'http://10.0.2.2:3000/api';
  final currentUrl = isDebugMode ? developmentUrl : productionUrl;
  
  print('📱 Build Mode: ${isDebugMode ? "DEBUG" : "RELEASE"}');
  print('🌐 Current URL: $currentUrl\n');
  
  // Test production backend
  print('🧪 Testing Production Backend: $productionUrl/health');
  await testBackend('$productionUrl/health');
  
  print('\n' + '='*50 + '\n');
  
  // Test login endpoint
  print('🧪 Testing Login Endpoint: $productionUrl/auth/login');
  await testLogin(productionUrl);
}

Future<void> testBackend(String url) async {
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      print('✅ SUCCESS! Backend is reachable');
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
    } else {
      print('⚠️  Backend responded but with error');
      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ FAILED! Cannot reach backend');
    print('   Error: $e');
    print('\n💡 Possible issues:');
    print('   1. Backend is not deployed or down');
    print('   2. Wrong URL configured');
    print('   3. Network connectivity issue');
    print('   4. CORS or firewall blocking');
  }
}

Future<void> testLogin(String baseUrl) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'test@test.com',
        'password': 'test123',
      }),
    ).timeout(Duration(seconds: 10));
    
    print('📬 Login endpoint responded');
    print('   Status: ${response.statusCode}');
    
    if (response.statusCode == 400 || response.statusCode == 401) {
      print('✅ Endpoint is working! (Invalid credentials expected)');
    } else if (response.statusCode == 200) {
      print('✅ Endpoint is working! (Test user exists)');
    } else {
      print('⚠️  Unexpected response: ${response.body}');
    }
  } catch (e) {
    print('❌ Login endpoint failed');
    print('   Error: $e');
  }
}
