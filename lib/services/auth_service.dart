import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import 'supabase_service.dart';
import 'environment_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();

  final _supabaseService = SupabaseService.instance;
  SupabaseClient get _supabase => _supabaseService.client;
  
  // Auth state
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign in with Google (using Supabase Auth)
  Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.ebook250630://login-callback/',
      );
      
      if (kDebugMode) {
        print('✅ Google sign in initiated');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google sign in error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out error: $e');
      }
      rethrow;
    }
  }

  // Get or create user profile
  Future<app_user.User?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final user = currentUser!;
      
      // First, try to get existing profile
      final existingProfile = await _supabaseService.users
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile != null) {
        return app_user.User.fromJson({
          ...existingProfile,
          'email': user.email,
        });
      }

      // If no profile exists, create one
      final newProfile = {
        'id': user.id,
        'email': user.email,
        'username': user.userMetadata?['full_name'] ?? 
                   user.email?.split('@').first ?? 
                   'User',
        'avatar_url': user.userMetadata?['avatar_url'],
        'is_admin': false,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.users
          .insert(newProfile)
          .select()
          .single();

      if (kDebugMode) {
        print('✅ Created new user profile: ${response['username']}');
      }

      return app_user.User.fromJson({
        ...response,
        'email': user.email,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting/creating user profile: $e');
      }
      return null;
    }
  }

  // Update user profile
  Future<app_user.User?> updateUserProfile({
    String? username,
    String? avatarUrl,
  }) async {
    if (!isAuthenticated) return null;

    try {
      final user = currentUser!;
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final response = await _supabaseService.users
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();

      if (kDebugMode) {
        print('✅ Updated user profile');
      }

      return app_user.User.fromJson({
        ...response,
        'email': user.email,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      return null;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    if (!isAuthenticated) return false;
    
    try {
      final profile = await _supabaseService.users
          .select('is_admin')
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      return profile?['is_admin'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking admin status: $e');
      }
      return false;
    }
  }

  // Admin functions
  Future<List<app_user.User>> getAllUsers({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _supabaseService.users.select();

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        query = query.or('username.ilike.%$search%,email.ilike.%$search%');
      }

      // Apply status filter
      if (status != null && status != 'all') {
        switch (status) {
          case 'active':
            query = query.eq('is_active', true);
            break;
          case 'inactive':
            query = query.eq('is_active', false);
            break;
          case 'admin':
            query = query.eq('is_admin', true);
            break;
        }
      }

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        }
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      
      return (response as List)
          .map((user) => app_user.User.fromJson(user))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting users: $e');
      }
      return [];
    }
  }

  Future<int> getUsersCount({String? search, String? status}) async {
    try {
      if (kDebugMode) {
        print('🔍 Starting users count query with search: $search, status: $status');
      }
      
      dynamic query = _supabaseService.users.select('id');

      if (search != null && search.isNotEmpty) {
        query = query.or('username.ilike.%$search%,email.ilike.%$search%');
      }

      if (status != null && status != 'all') {
        switch (status) {
          case 'active':
            query = query.eq('is_active', true);
            break;
          case 'inactive':
            query = query.eq('is_active', false);
            break;
          case 'admin':
            query = query.eq('is_admin', true);
            break;
        }
      }

      if (kDebugMode) {
        print('🔍 Executing users count query...');
      }

      final response = await query.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ Users count query timed out after 15 seconds');
          }
          throw Exception('Database query timeout');
        },
      );
      
      final count = response.length;
      if (kDebugMode) {
        print('✅ Users count query successful: $count users');
      }
      
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting users count: $e');
        print('❌ Error type: ${e.runtimeType}');
      }
      return 0;
    }
  }

  Future<bool> toggleUserStatus(String userId) async {
    try {
      final user = await _supabaseService.users
          .select('is_active')
          .eq('id', userId)
          .single();

      final newStatus = !(user['is_active'] as bool);

      await _supabaseService.users
          .update({
            'is_active': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (kDebugMode) {
        print('✅ User status toggled: $newStatus');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling user status: $e');
      }
      return false;
    }
  }

  Future<bool> toggleAdminStatus(String userId) async {
    try {
      final user = await _supabaseService.users
          .select('is_admin')
          .eq('id', userId)
          .single();

      final newStatus = !(user['is_admin'] as bool);

      await _supabaseService.users
          .update({
            'is_admin': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (kDebugMode) {
        print('✅ Admin status toggled: $newStatus');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling admin status: $e');
      }
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _supabaseService.users.delete().eq('id', userId);

      if (kDebugMode) {
        print('✅ User deleted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting user: $e');
      }
      return false;
    }
  }
}