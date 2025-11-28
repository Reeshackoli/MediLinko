import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock user data
      final user = UserModel(
        id: '1',
        fullName: 'Test User',
        email: email,
        phone: '1234567890',
        role: email.contains('doctor')
            ? UserRole.doctor
            : email.contains('pharma')
                ? UserRole.pharmacist
                : UserRole.user,
        isProfileComplete: true,
      );
      
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> register(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void logout() {
    state = const AsyncValue.data(null);
  }

  void updateUser(UserModel user) {
    state = AsyncValue.data(user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

// Helper provider to get current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value;
});
