import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

// Provider to fetch and cache user's health profile
final healthProfileProvider = FutureProvider.autoDispose((ref) async {
  final response = await ProfileService.getProfile();
  
  if (response['success'] == true && response['data'] != null) {
    // Return the profile part of the response
    return response['data']['profile'] as Map<String, dynamic>?;
  }
  
  return null;
});
