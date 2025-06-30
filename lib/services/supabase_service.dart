import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();

  late final SupabaseClient _client;
  SupabaseClient get client => _client;

  // Environment-based table names
  String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  bool get isDevelopment => environment == 'development';

  // Table names with environment prefix
  String get usersTable => isDevelopment ? 'users_dev' : 'users';
  String get booksTable => isDevelopment ? 'books_dev' : 'books';
  String get ratingsTable => isDevelopment ? 'ratings_dev' : 'ratings';
  String get readingHistoryTable => isDevelopment ? 'reading_history_dev' : 'reading_history';

  // Storage bucket names with environment suffix
  String get bookFilesBucket => isDevelopment ? 'book-files-dev' : 'book-files';
  String get bookCoversBucket => isDevelopment ? 'book-covers-dev' : 'book-covers';
  String get avatarsBucket => isDevelopment ? 'avatars-dev' : 'avatars';

  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Missing Supabase configuration in .env file');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 10,
        ),
      );

      _client = Supabase.instance.client;

      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
        print('🌍 Environment: $environment');
        print('📊 Tables: $usersTable, $booksTable, $ratingsTable, $readingHistoryTable');
        print('🗂️ Buckets: $bookFilesBucket, $bookCoversBucket, $avatarsBucket');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Supabase: $e');
      }
      rethrow;
    }
  }

  // Auth shortcuts
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  bool get isAuthenticated => currentUser != null;

  // Database shortcuts
  SupabaseQueryBuilder get users => _client.from(usersTable);
  SupabaseQueryBuilder get books => _client.from(booksTable);
  SupabaseQueryBuilder get ratings => _client.from(ratingsTable);
  SupabaseQueryBuilder get readingHistory => _client.from(readingHistoryTable);

  // Storage shortcuts
  SupabaseStorageClient get storage => _client.storage;
  StorageFileApi get bookFiles => storage.from(bookFilesBucket);
  StorageFileApi get bookCovers => storage.from(bookCoversBucket);
  StorageFileApi get avatars => storage.from(avatarsBucket);

  // Helper methods for common operations
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;
    
    try {
      final response = await users
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user profile: $e');
      }
      return null;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?['is_admin'] == true;
  }

  // File URL helpers
  String getPublicUrl(String bucket, String path) {
    return storage.from(bucket).getPublicUrl(path);
  }

  String? getCoverUrl(String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) return null;
    return getPublicUrl(bookCoversBucket, coverPath);
  }

  String? getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return null;
    return getPublicUrl(avatarsBucket, avatarPath);
  }

  // Error handling helper
  String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return error.message;
    } else if (error is StorageException) {
      return error.message;
    } else if (error is AuthException) {
      return error.message;
    } else {
      return error.toString();
    }
  }

  // Realtime subscription helpers
  RealtimeChannel subscribeTo(String table, {
    required void Function(PostgrestResponse) callback,
    PostgrestFilterBuilder? filter,
  }) {
    return _client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) => callback(payload as PostgrestResponse),
        )
        .subscribe();
  }

  void unsubscribe(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}