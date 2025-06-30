import '../constants/app_constants.dart';

class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入電子郵件';
    }
    
    if (!RegExp(AppConstants.emailPattern).hasMatch(value.trim())) {
      return '請輸入有效的電子郵件格式';
    }
    
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入網址';
    }
    
    if (value.trim().length > AppConstants.urlMaxLength) {
      return '網址長度不能超過 ${AppConstants.urlMaxLength} 個字元';
    }
    
    if (!RegExp(AppConstants.urlPattern).hasMatch(value.trim())) {
      return '請輸入有效的網址格式 (http:// 或 https://)';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String fieldName = '此欄位'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName不能為空';
    }
    return null;
  }

  // Text length validation
  static String? validateLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String fieldName = '此欄位',
  }) {
    if (value == null) return null;
    
    final length = value.trim().length;
    
    if (minLength != null && length < minLength) {
      return '$fieldName至少需要 $minLength 個字元';
    }
    
    if (maxLength != null && length > maxLength) {
      return '$fieldName不能超過 $maxLength 個字元';
    }
    
    return null;
  }

  // Book title validation
  static String? validateBookTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入書名';
    }
    
    if (value.trim().length > AppConstants.titleMaxLength) {
      return '書名不能超過 ${AppConstants.titleMaxLength} 個字元';
    }
    
    return null;
  }

  // Author validation
  static String? validateAuthor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入作者';
    }
    
    if (value.trim().length > AppConstants.authorMaxLength) {
      return '作者名稱不能超過 ${AppConstants.authorMaxLength} 個字元';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String? value) {
    if (value != null && value.trim().length > AppConstants.descriptionMaxLength) {
      return '描述不能超過 ${AppConstants.descriptionMaxLength} 個字元';
    }
    
    return null;
  }

  // Review validation
  static String? validateReview(String? value) {
    if (value != null && value.trim().length > AppConstants.reviewMaxLength) {
      return '評論不能超過 ${AppConstants.reviewMaxLength} 個字元';
    }
    
    return null;
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入使用者名稱';
    }
    
    if (value.trim().length > AppConstants.usernameMaxLength) {
      return '使用者名稱不能超過 ${AppConstants.usernameMaxLength} 個字元';
    }
    
    // Check for valid characters (letters, numbers, underscore, hyphen)
    if (!RegExp(r'^[a-zA-Z0-9_\-\u4e00-\u9fff]+$').hasMatch(value.trim())) {
      return '使用者名稱只能包含字母、數字、底線、連字號和中文字元';
    }
    
    return null;
  }

  // Rating validation
  static String? validateRating(int? value) {
    if (value == null) {
      return '請選擇評分';
    }
    
    if (value < AppConstants.minRating || value > AppConstants.maxRating) {
      return '評分必須在 ${AppConstants.minRating} 到 ${AppConstants.maxRating} 星之間';
    }
    
    return null;
  }

  // File format validation
  static String? validateFileFormat(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      return '請選擇檔案';
    }
    
    final extension = fileName.split('.').last.toLowerCase();
    
    if (!AppConstants.allowedBookFormats.contains(extension)) {
      return '不支援的檔案格式。支援格式：${AppConstants.allowedBookFormats.join(', ')}';
    }
    
    return null;
  }

  // Image format validation
  static String? validateImageFormat(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      return null; // Image is optional
    }
    
    final extension = fileName.split('.').last.toLowerCase();
    
    if (!AppConstants.allowedImageFormats.contains(extension)) {
      return '不支援的圖片格式。支援格式：${AppConstants.allowedImageFormats.join(', ')}';
    }
    
    return null;
  }

  // File size validation (in bytes)
  static String? validateFileSize(int? sizeInBytes) {
    if (sizeInBytes == null) return null;
    
    if (sizeInBytes > AppConstants.maxFileSize) {
      final maxSizeMB = AppConstants.maxFileSize / (1024 * 1024);
      return '檔案大小不能超過 ${maxSizeMB.toStringAsFixed(0)}MB';
    }
    
    return null;
  }

  // Category validation
  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請選擇分類';
    }
    
    if (!AppConstants.bookCategories.contains(value)) {
      return '請選擇有效的分類';
    }
    
    return null;
  }

  // Password validation (for future authentication enhancements)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '請輸入密碼';
    }
    
    if (value.length < 8) {
      return '密碼至少需要 8 個字元';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return '密碼必須包含至少一個大寫字母';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return '密碼必須包含至少一個小寫字母';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return '密碼必須包含至少一個數字';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return '請確認密碼';
    }
    
    if (value != password) {
      return '密碼確認不一致';
    }
    
    return null;
  }

  // Product code validation (optional field)
  static String? validateProductCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    // Basic format validation for product codes
    if (!RegExp(r'^[A-Z0-9\-_]+$').hasMatch(value.trim())) {
      return '產品代碼只能包含大寫字母、數字、連字號和底線';
    }
    
    if (value.trim().length > 50) {
      return '產品代碼不能超過 50 個字元';
    }
    
    return null;
  }

  // Generic number validation
  static String? validateNumber(
    String? value, {
    required String fieldName,
    double? min,
    double? max,
    bool isRequired = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '請輸入$fieldName' : null;
    }
    
    final number = double.tryParse(value.trim());
    if (number == null) {
      return '$fieldName必須是有效的數字';
    }
    
    if (min != null && number < min) {
      return '$fieldName不能小於 $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName不能大於 $max';
    }
    
    return null;
  }

  // Helper method to check if URL is accessible
  static bool isValidUrl(String url) {
    try {
      return Uri.tryParse(url) != null && 
             RegExp(AppConstants.urlPattern).hasMatch(url);
    } catch (e) {
      return false;
    }
  }

  // Helper method to sanitize input
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Helper method to check if string contains only whitespace
  static bool isEmptyOrWhitespace(String? value) {
    return value == null || value.trim().isEmpty;
  }
}