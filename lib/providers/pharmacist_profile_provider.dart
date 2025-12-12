import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

final pharmacistProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final response = await ProfileService.getProfile();
  
  // Extract profile from the response structure: { success: true, data: { user: {...}, profile: {...} } }
  if (response['success'] == true && response['data'] != null) {
    return response['data']['profile'] as Map<String, dynamic>?;
  }
  
  return null;
});