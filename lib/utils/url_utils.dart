import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class UrlUtils {
  // Launch URL in browser
  static Future<bool> launchUrl(String url) async {
    try {
      if (!isValidUrl(url)) {
        return false;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Launch URL in app (WebView)
  static Future<bool> launchUrlInApp(String url) async {
    try {
      if (!isValidUrl(url)) {
        return false;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Copy URL to clipboard
  static Future<void> copyToClipboard(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }

  // Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      return uri != null && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty &&
             RegExp(AppConstants.urlPattern).hasMatch(url);
    } catch (e) {
      return false;
    }
  }

  // Format URL for display (truncate if too long)
  static String formatUrlForDisplay(String url, {int maxLength = 50}) {
    if (url.length <= maxLength) {
      return url;
    }
    
    // Try to show domain and end of path
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final domain = uri.host;
      final path = uri.path;
      
      if (domain.length + path.length <= maxLength - 3) {
        return '$domain$path';
      }
      
      if (domain.length <= maxLength - 6) {
        final remainingLength = maxLength - domain.length - 6;
        final truncatedPath = path.length > remainingLength 
            ? '...${path.substring(path.length - remainingLength)}'
            : path;
        return '$domain$truncatedPath';
      }
    }
    
    // Fallback: simple truncation
    return '${url.substring(0, maxLength - 3)}...';
  }

  // Extract domain from URL
  static String? getDomain(String url) {
    try {
      final uri = Uri.tryParse(url);
      return uri?.host;
    } catch (e) {
      return null;
    }
  }

  // Add protocol if missing
  static String ensureProtocol(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  // Check if URL is accessible (ping-like functionality)
  static Future<bool> isUrlAccessible(String url) async {
    try {
      if (!isValidUrl(url)) {
        return false;
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final request = await client.headUrl(Uri.parse(url));
      final response = await request.close();
      
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Generate preview URL for popular services
  static String? getPreviewUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      final host = uri.host.toLowerCase();
      
      // YouTube
      if (host.contains('youtube.com') || host.contains('youtu.be')) {
        String? videoId;
        if (host.contains('youtube.com')) {
          videoId = uri.queryParameters['v'];
        } else if (host.contains('youtu.be')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        }
        
        if (videoId != null) {
          return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
        }
      }
      
      // Vimeo
      if (host.contains('vimeo.com')) {
        final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        if (videoId != null) {
          return 'https://vumbnail.com/$videoId.jpg';
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get URL type/category
  static String getUrlType(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return '網頁';

      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();
      
      // Video platforms
      if (host.contains('youtube.com') || host.contains('youtu.be')) {
        return 'YouTube影片';
      }
      if (host.contains('vimeo.com')) {
        return 'Vimeo影片';
      }
      if (host.contains('bilibili.com')) {
        return 'Bilibili影片';
      }
      
      // Document platforms
      if (host.contains('docs.google.com')) {
        return 'Google文件';
      }
      if (host.contains('drive.google.com')) {
        return 'Google雲端硬碟';
      }
      if (host.contains('dropbox.com')) {
        return 'Dropbox';
      }
      
      // Reading platforms
      if (host.contains('medium.com')) {
        return 'Medium文章';
      }
      if (host.contains('github.com')) {
        return 'GitHub';
      }
      
      // File extensions
      if (path.endsWith('.pdf')) {
        return 'PDF文件';
      }
      if (path.endsWith('.doc') || path.endsWith('.docx')) {
        return 'Word文件';
      }
      if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
        return 'PowerPoint簡報';
      }
      if (path.endsWith('.zip') || path.endsWith('.rar')) {
        return '壓縮檔案';
      }
      
      return '網頁';
    } catch (e) {
      return '網頁';
    }
  }

  // Check if URL requires special handling
  static bool requiresSpecialHandling(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return false;

      final host = uri.host.toLowerCase();
      
      // Social media platforms that might need special handling
      final specialPlatforms = [
        'facebook.com',
        'twitter.com',
        'x.com',
        'instagram.com',
        'linkedin.com',
        'tiktok.com',
        'weibo.com',
      ];
      
      return specialPlatforms.any((platform) => host.contains(platform));
    } catch (e) {
      return false;
    }
  }

  // Generate sharing URL
  static Map<String, String> getShareUrls(String url, String title) {
    final encodedUrl = Uri.encodeComponent(url);
    final encodedTitle = Uri.encodeComponent(title);
    
    return {
      'facebook': 'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
      'twitter': 'https://twitter.com/intent/tweet?url=$encodedUrl&text=$encodedTitle',
      'linkedin': 'https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl',
      'line': 'https://social-plugins.line.me/lineit/share?url=$encodedUrl',
      'telegram': 'https://t.me/share/url?url=$encodedUrl&text=$encodedTitle',
      'whatsapp': 'https://wa.me/?text=$encodedTitle%20$encodedUrl',
    };
  }

  // Clean URL (remove tracking parameters)
  static String cleanUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final cleanParams = Map<String, String>.from(uri.queryParameters);
      
      // Common tracking parameters to remove
      final trackingParams = [
        'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
        'fbclid', 'gclid', 'ref', 'source', 'campaign',
      ];
      
      for (final param in trackingParams) {
        cleanParams.remove(param);
      }
      
      return uri.replace(queryParameters: cleanParams.isEmpty ? null : cleanParams).toString();
    } catch (e) {
      return url;
    }
  }
}