import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';

// Auth State Provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session?.user).value;
});

// User Profile Provider
final userProfileProvider = FutureProvider<app_user.User?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  return await AuthService.instance.getCurrentUserProfile();
});

// Is Admin Provider
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  
  return await AuthService.instance.isCurrentUserAdmin();
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

// Authentication Actions
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await AuthService.instance.signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await AuthService.instance.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await AuthService.instance.updateUserProfile(
        username: username,
        avatarUrl: avatarUrl,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    try {
      // Refresh user profile data
      await AuthService.instance.getCurrentUserProfile();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier();
});

// Users Management Provider (for admin)
final usersProvider = FutureProvider.family<List<app_user.User>, Map<String, dynamic>>((ref, params) async {
  return await AuthService.instance.getAllUsers(
    search: params['search'],
    status: params['status'],
    limit: params['limit'],
    offset: params['offset'],
  );
});

final usersCountProvider = FutureProvider.family<int, Map<String, String?>>((ref, params) async {
  return await AuthService.instance.getUsersCount(
    search: params['search'],
    status: params['status'],
  );
});

// User Management Actions
class UserManagementNotifier extends StateNotifier<AsyncValue<void>> {
  UserManagementNotifier() : super(const AsyncValue.data(null));

  Future<void> toggleUserStatus(String userId) async {
    state = const AsyncValue.loading();
    try {
      await AuthService.instance.toggleUserStatus(userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleAdminStatus(String userId) async {
    state = const AsyncValue.loading();
    try {
      await AuthService.instance.toggleAdminStatus(userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await AuthService.instance.deleteUser(userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, AsyncValue<void>>((ref) {
  return UserManagementNotifier();
});