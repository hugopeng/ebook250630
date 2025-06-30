import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentService {
  static EnvironmentService? _instance;
  static EnvironmentService get instance => _instance ??= EnvironmentService._();
  
  EnvironmentService._();

  // 環境判斷
  bool get isDevelopment {
    // 1. 優先檢查 Vercel 環境變數 (部署時會自動設置)
    final vercelEnv = dotenv.env['VERCEL_ENV'];
    if (vercelEnv != null) {
      return vercelEnv != 'production';
    }
    
    // 2. 檢查自定義環境變數
    final environment = dotenv.env['ENVIRONMENT'];
    if (environment != null) {
      return environment.toLowerCase() == 'development';
    }
    
    // 3. 預設：Debug 模式為開發環境
    return kDebugMode;
  }

  bool get isProduction => !isDevelopment;

  String get environmentName => isDevelopment ? 'Development' : 'Production';

  // 資料表名稱
  String get usersTable => isDevelopment ? '_dev_users' : 'users';
  String get booksTable => isDevelopment ? '_dev_books' : 'books';
  String get ratingsTable => isDevelopment ? '_dev_ratings' : 'ratings';
  String get readingHistoryTable => isDevelopment ? '_dev_reading_history' : 'reading_history';

  // Storage Bucket 名稱
  String get coversBucket => isDevelopment ? '-dev-covers' : 'covers';
  String get avatarsBucket => isDevelopment ? '-dev-avatars' : 'avatars';
  String get filesBucket => isDevelopment ? '-dev-files' : 'files';

  // API 配置
  String get apiUrl => dotenv.env['SUPABASE_URL'] ?? '';
  String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  String get serviceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  // 應用程式資訊
  String get appName => dotenv.env['APP_NAME'] ?? 'SoR書庫';
  String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  // 除錯資訊
  Map<String, dynamic> getDebugInfo() {
    return {
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'environmentName': environmentName,
      'kDebugMode': kDebugMode,
      'vercelEnv': dotenv.env['VERCEL_ENV'],
      'environment': dotenv.env['ENVIRONMENT'],
      'tables': {
        'users': usersTable,
        'books': booksTable,
        'ratings': ratingsTable,
        'reading_history': readingHistoryTable,
      },
      'buckets': {
        'covers': coversBucket,
        'avatars': avatarsBucket,
        'files': filesBucket,
      },
    };
  }

  // 環境配置檢查
  bool validateConfiguration() {
    final requiredVars = [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
    ];

    for (final varName in requiredVars) {
      if (dotenv.env[varName] == null || dotenv.env[varName]!.isEmpty) {
        if (kDebugMode) {
          print('❌ Missing required environment variable: $varName');
        }
        return false;
      }
    }

    if (kDebugMode) {
      print('✅ Environment configuration validated');
      print('🌍 Environment: $environmentName');
      print('📊 Tables: ${getDebugInfo()['tables']}');
      print('🗂️ Buckets: ${getDebugInfo()['buckets']}');
    }

    return true;
  }
}