import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class FileUtils {
  // Get file extension
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  // Get file name without extension
  static String getFileNameWithoutExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length <= 1) return fileName;
    return parts.sublist(0, parts.length - 1).join('.');
  }

  // Get MIME type
  static String? getMimeType(String fileName) {
    return lookupMimeType(fileName);
  }

  // Check if file is a book format
  static bool isBookFile(String fileName) {
    final extension = getFileExtension(fileName);
    return AppConstants.allowedBookFormats.contains(extension);
  }

  // Check if file is an image
  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return AppConstants.allowedImageFormats.contains(extension);
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Validate file size
  static bool isValidFileSize(int bytes) {
    return bytes <= AppConstants.maxFileSize;
  }

  // Generate unique file name
  static String generateUniqueFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalFileName);
    final nameWithoutExt = getFileNameWithoutExtension(originalFileName);
    return '${nameWithoutExt}_$timestamp.$extension';
  }

  // Sanitize file name for storage
  static String sanitizeFileName(String fileName) {
    // Remove or replace invalid characters
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  // Get file type display name
  static String getFileTypeDisplay(String fileName) {
    final extension = getFileExtension(fileName);
    return AppConstants.bookFormatNames[extension] ?? extension.toUpperCase();
  }

  // Check if file exists
  static Future<bool> fileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Delete file
  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
      return false;
    }
  }

  // Copy file
  static Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      final destinationFile = File(destinationPath);
      
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        return await destinationFile.exists();
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error copying file: $e');
      }
      return false;
    }
  }

  // Read file as bytes
  static Future<Uint8List?> readFileAsBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading file: $e');
      }
      return null;
    }
  }

  // Write bytes to file
  static Future<bool> writeBytesToFile(String path, Uint8List bytes) async {
    try {
      final file = File(path);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error writing file: $e');
      }
      return false;
    }
  }

  // Get app documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Get app cache directory
  static Future<Directory> getAppCacheDirectory() async {
    return await getTemporaryDirectory();
  }

  // Create directory if it doesn't exist
  static Future<Directory> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  // Get file info
  static Future<Map<String, dynamic>?> getFileInfo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'path': path,
          'name': path.split('/').last,
          'size': stat.size,
          'modified': stat.modified,
          'type': stat.type,
          'mimeType': getMimeType(path),
          'extension': getFileExtension(path),
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting file info: $e');
      }
      return null;
    }
  }

  // List files in directory
  static Future<List<FileSystemEntity>> listFilesInDirectory(
    String directoryPath, {
    bool recursive = false,
    String? extension,
  }) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }

      final entities = await directory.list(recursive: recursive).toList();
      
      if (extension != null) {
        return entities.where((entity) {
          if (entity is File) {
            return getFileExtension(entity.path) == extension.toLowerCase();
          }
          return false;
        }).toList();
      }
      
      return entities;
    } catch (e) {
      if (kDebugMode) {
        print('Error listing files: $e');
      }
      return [];
    }
  }

  // Calculate directory size
  static Future<int> getDirectorySize(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating directory size: $e');
      }
      return 0;
    }
  }

  // Clean up old cache files
  static Future<void> cleanupOldCacheFiles({
    Duration maxAge = const Duration(days: 7),
  }) async {
    try {
      final cacheDir = await getAppCacheDirectory();
      final cutoffTime = DateTime.now().subtract(maxAge);
      
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up cache files: $e');
      }
    }
  }

  // Compress file (if needed for large files)
  static Future<String?> compressFile(String filePath) async {
    // This would typically use a compression library
    // For now, just return the original path
    return filePath;
  }

  // Extract text from file (basic implementation)
  static Future<String?> extractTextFromFile(String filePath) async {
    try {
      final extension = getFileExtension(filePath);
      
      if (extension == 'txt') {
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsString();
        }
      }
      
      // For other formats (PDF, EPUB), you would need specialized libraries
      // This is a placeholder for future implementation
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting text from file: $e');
      }
      return null;
    }
  }

  // Generate file hash (for deduplication)
  static Future<String?> generateFileHash(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        // You would use a proper hash function here (like crypto package)
        // This is a simple placeholder
        return bytes.length.toString() + file.lastModifiedSync().millisecondsSinceEpoch.toString();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating file hash: $e');
      }
      return null;
    }
  }

  // Check if file is corrupted (basic check)
  static Future<bool> isFileCorrupted(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return true;
      }
      
      final stat = await file.stat();
      if (stat.size == 0) {
        return true;
      }
      
      // Try to read the first few bytes
      final bytes = await file.openRead(0, 100).toList();
      return bytes.isEmpty;
    } catch (e) {
      return true;
    }
  }
}