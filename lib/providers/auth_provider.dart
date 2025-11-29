import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  // Login with real API
  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        final userData = response.data!['user'];
        final user = UserModel.fromJson(userData);
        state = AsyncValue.data(user);
        return null; // Success
      } else {
        state = AsyncValue.error(response.message ?? 'Login failed', StackTrace.current);
        return response.message ?? 'Login failed';
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return e.toString();
    }
  }

  // Register with real API
  Future<String?> register(UserModel user, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await AuthService.register(
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        password: password,
        role: user.role,
      );

      if (response.success && response.data != null) {
        final userData = response.data!['user'];
        final registeredUser = UserModel.fromJson(userData);
        state = AsyncValue.data(registeredUser);
        return null; // Success
      } else {
        state = AsyncValue.error(response.message ?? 'Registration failed', StackTrace.current);
        return response.message ?? 'Registration failed';
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return e.toString();
    }
  }

  void logout() async {
    await AuthService.logout();
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
