import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'SoR書庫';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'SoR書庫是一個基於 Flutter + Supabase 的現代化電子書閱讀平台，提供優質的跨平台在線閱讀體驗';
  static const String organizationName = '臺灣雙母語研究學會';
  
  // Colors
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF64748B);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  
  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXl = 16.0;
  
  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Animation Duration
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  // Breakpoints
  static const double mobileBreakpoint = 450;
  static const double tabletBreakpoint = 800;
  static const double desktopBreakpoint = 1920;
  
  // Grid
  static const int mobileGridColumns = 2;
  static const int tabletGridColumns = 3;
  static const int desktopGridColumns = 4;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Upload
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedBookFormats = [
    'pdf', 'epub', 'txt', 'mobi', 'azw3', 'url'
  ];
  static const List<String> allowedImageFormats = [
    'jpg', 'jpeg', 'png', 'webp'
  ];
  
  // Book Format Display Names
  static const Map<String, String> bookFormatNames = {
    'pdf': 'PDF',
    'epub': 'EPUB',
    'txt': 'TXT',
    'mobi': 'MOBI',
    'azw3': 'AZW3',
    'url': 'URL連結',
  };
  
  // Rating
  static const int maxRating = 5;
  static const int minRating = 1;
  
  // Text Limits
  static const int titleMaxLength = 200;
  static const int authorMaxLength = 100;
  static const int descriptionMaxLength = 2000;
  static const int reviewMaxLength = 1000;
  static const int usernameMaxLength = 50;
  static const int urlMaxLength = 2048;
  
  // Cache
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100;
  
  // Error Messages
  static const String genericErrorMessage = '發生未知錯誤，請稍後再試';
  static const String networkErrorMessage = '網路連線異常，請檢查網路設定';
  static const String authErrorMessage = '認證失敗，請重新登入';
  static const String permissionErrorMessage = '權限不足，無法執行此操作';
  static const String invalidUrlMessage = '請輸入有效的網址';
  static const String fileTooLargeMessage = '檔案大小超過限制';
  static const String unsupportedFormatMessage = '不支援的檔案格式';
  
  // Success Messages
  static const String saveSuccessMessage = '儲存成功';
  static const String deleteSuccessMessage = '刪除成功';
  static const String uploadSuccessMessage = '上傳成功';
  
  // Dialog
  static const String confirmTitle = '確認操作';
  static const String cancelButton = '取消';
  static const String confirmButton = '確認';
  static const String deleteConfirmMessage = '確定要刪除此項目嗎？此操作無法復原。';
  
  // Loading
  static const String loadingMessage = '載入中...';
  static const String processingMessage = '處理中...';
  static const String uploadingMessage = '上傳中...';
  static const String validatingMessage = '驗證中...';
  
  // Empty States
  static const String noBooksMessage = '目前沒有書籍';
  static const String noResultsMessage = '找不到符合條件的結果';
  static const String noDataMessage = '暫無資料';
  
  // Categories
  static const List<String> bookCategories = [
    '文學小說',
    '商業理財',
    '心理勵志',
    '醫療保健',
    '藝術設計',
    '人文史地',
    '社會科學',
    '自然科普',
    '電腦資訊',
    '語言學習',
    '考試用書',
    '童書',
    '輕小說',
    '漫畫',
    '其他',
  ];
  
  // Book Status
  static const String statusDraft = 'draft';
  static const String statusPublished = 'published';
  static const String statusArchived = 'archived';
  
  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  
  // Local Storage Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String lastLoginKey = 'last_login';
  static const String userPreferencesKey = 'user_preferences';
  
  // Legal URLs
  static const String privacyPolicyUrl = '/privacy-policy';
  static const String termsOfServiceUrl = '/terms-of-service';
  static const String supportEmail = 'support@sorbooks.com';
  
  // Legal Content
  static const String privacyPolicyTitle = 'SoR書庫隱私政策';
  static const String termsOfServiceTitle = '電子商務約定條款';
  static const String lastUpdatedPrivacy = '2024年12月17日';
  static const String lastUpdatedTerms = '2025年6月17日';
  
  // Regex Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String urlPattern = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
  
  // Feature Flags
  static const bool enableDarkMode = true;
  static const bool enableOfflineReading = false;
  static const bool enableSocialSharing = true;
  static const bool enableAnalytics = true;
  static const bool enableNotifications = true;
  static const bool enableUrlBooks = true;
  
  // Environment
  static const String developmentEnvironment = 'development';
  static const String productionEnvironment = 'production';
  
  // Copyright
  static const String copyrightText = '© 2024 SoR書庫 - 保留所有權利';
  static const String organizationFullName = '臺灣雙母語研究學會';
  
  // URL Book Specific
  static const String urlBookDescription = '外部連結書籍';
  static const String openInBrowserText = '在瀏覽器中開啟';
  static const String copyLinkText = '複製連結';
  static const String invalidLinkText = '無效連結';
}