import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

final doctorProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final profile = await ProfileService.getProfile();
  return profile;
});
