import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();

  late final SupabaseClient _client;
  SupabaseClient get client => _client;
  
  // 使用 EnvironmentService 來管理環境配置
  final EnvironmentService _envService = EnvironmentService.instance;

  // Environment information
  bool get isDevelopment => _envService.isDevelopment;
  bool get isProduction => _envService.isProduction;
  String get environmentName => _envService.environmentName;

  // Table names (正確的命名規則)
  String get usersTable => _envService.usersTable;
  String get booksTable => _envService.booksTable;
  String get ratingsTable => _envService.ratingsTable;
  String get readingHistoryTable => _envService.readingHistoryTable;

  // Storage bucket names (正確的命名規則)
  String get coversBucket => _envService.coversBucket;
  String get avatarsBucket => _envService.avatarsBucket;
  String get filesBucket => _envService.filesBucket;

  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      
      // 驗證環境配置
      if (!_envService.validateConfiguration()) {
        throw Exception('環境配置驗證失敗');
      }

      await Supabase.initialize(
        url: _envService.apiUrl,
        anonKey: _envService.anonKey,
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
        print('🌍 Environment: $environmentName');
        print('📊 Tables: $usersTable, $booksTable, $ratingsTable, $readingHistoryTable');
        print('🗂️ Buckets: $coversBucket, $avatarsBucket, $filesBucket');
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
  StorageFileApi get bookFiles => storage.from(filesBucket);
  StorageFileApi get bookCovers => storage.from(coversBucket);
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
    return getPublicUrl(coversBucket, coverPath);
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