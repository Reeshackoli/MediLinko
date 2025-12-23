import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  // Restore user from saved session (from Map)
  void restoreUser(Map<String, dynamic> userData) {
    try {
      final user = UserModel.fromJson(userData);
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  // Restore user from UserModel directly
  void restoreUserModel(UserModel user) {
    state = AsyncValue.data(user);
  }

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
        
        // Save session for persistence
        await SessionManager.saveUserSession(userData);
        
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
    await SessionManager.clearSession();
    state = const AsyncValue.data(null);
  }

  void updateUser(UserModel user) {
    state = AsyncValue.data(user);
  }

  // Refresh user data from backend
  Future<void> refreshUser() async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return;

      // Re-fetch user data would go here if you have an endpoint
      // For now, just reload from session
      final sessionData = await SessionManager.getUserSession();
      if (sessionData != null) {
        restoreUser(sessionData);
      }
    } catch (e) {
      // Keep current state on error
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

// Helper provider to get current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value;
});
