import 'package:flutter/foundation.dart';
import '../models/reading_history.dart';
import 'supabase_service.dart';

class ReadingHistoryService {
  final SupabaseService _supabase = SupabaseService.instance;

  // 獲取用戶的所有閱讀歷史
  Future<List<ReadingHistory>> getUserReadingHistories() async {
    try {
      if (!_supabase.isAuthenticated) {
        throw Exception('用戶未登入');
      }

      final response = await _supabase.readingHistory
          .select('''
            *,
            ${_supabase.booksTable}!inner(
              id, title, author, cover_url, file_type
            )
          ''')
          .eq('user_id', _supabase.currentUser!.id)
          .order('last_read_at', ascending: false);

      if (kDebugMode) {
        print('📚 載入閱讀歷史: ${response.length} 筆記錄');
      }

      return (response as List)
          .map((json) => ReadingHistory.fromJson(json))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('❌ 載入閱讀歷史失敗: $e');
      }
      throw Exception('載入閱讀歷史失敗: $e');
    }
  }

  // 獲取特定書籍的閱讀歷史
  Future<ReadingHistory?> getReadingHistory(String bookId) async {
    try {
      if (!_supabase.isAuthenticated) {
        return null;
      }

      final response = await _supabase.readingHistory
          .select()
          .eq('user_id', _supabase.currentUser!.id)
          .eq('book_id', bookId)
          .maybeSingle();

      if (response == null) return null;

      return ReadingHistory.fromJson(response);

    } catch (e) {
      if (kDebugMode) {
        print('❌ 載入書籍閱讀歷史失敗: $e');
      }
      return null;
    }
  }

  // 更新閱讀進度
  Future<void> updateReadingProgress(
    String bookId,
    int currentPage,
    double progress,
  ) async {
    try {
      if (!_supabase.isAuthenticated) {
        throw Exception('用戶未登入');
      }

      final userId = _supabase.currentUser!.id;
      final now = DateTime.now().toIso8601String();

      // 檢查是否已存在閱讀記錄
      final existing = await _supabase.readingHistory
          .select('id')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      if (existing != null) {
        // 更新現有記錄
        await _supabase.readingHistory
            .update({
              'current_page': currentPage,
              'progress': progress,
              'last_read_at': now,
            })
            .eq('user_id', userId)
            .eq('book_id', bookId);
      } else {
        // 創建新記錄
        await _supabase.readingHistory.insert({
          'user_id': userId,
          'book_id': bookId,
          'current_page': currentPage,
          'progress': progress,
          'last_read_at': now,
          'reading_time_minutes': 0,
        });
      }

      if (kDebugMode) {
        print('✅ 閱讀進度已更新: 書籍 $bookId, 頁面 $currentPage, 進度 ${(progress * 100).toStringAsFixed(1)}%');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ 更新閱讀進度失敗: $e');
      }
      throw Exception('更新閱讀進度失敗: $e');
    }
  }

  // 增加閱讀時間
  Future<void> addReadingTime(String bookId, int minutes) async {
    try {
      if (!_supabase.isAuthenticated) {
        throw Exception('用戶未登入');
      }

      final userId = _supabase.currentUser!.id;

      // 獲取現在的閱讀時間
      final existing = await _supabase.readingHistory
          .select('reading_time_minutes')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();

      if (existing != null) {
        final currentTime = existing['reading_time_minutes'] as int? ?? 0;
        await _supabase.readingHistory
            .update({
              'reading_time_minutes': currentTime + minutes,
              'last_read_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('book_id', bookId);
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ 更新閱讀時間失敗: $e');
      }
      // 不拋出異常，避免影響閱讀體驗
    }
  }

  // 刪除閱讀歷史
  Future<void> deleteReadingHistory(String bookId) async {
    try {
      if (!_supabase.isAuthenticated) {
        throw Exception('用戶未登入');
      }

      await _supabase.readingHistory
          .delete()
          .eq('user_id', _supabase.currentUser!.id)
          .eq('book_id', bookId);

      if (kDebugMode) {
        print('✅ 閱讀歷史已刪除: 書籍 $bookId');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ 刪除閱讀歷史失敗: $e');
      }
      throw Exception('刪除閱讀歷史失敗: $e');
    }
  }

  // 清除所有閱讀歷史
  Future<void> clearAllReadingHistory() async {
    try {
      if (!_supabase.isAuthenticated) {
        throw Exception('用戶未登入');
      }

      await _supabase.readingHistory
          .delete()
          .eq('user_id', _supabase.currentUser!.id);

      if (kDebugMode) {
        print('✅ 所有閱讀歷史已清除');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ 清除閱讀歷史失敗: $e');
      }
      throw Exception('清除閱讀歷史失敗: $e');
    }
  }

  // 獲取閱讀統計
  Future<Map<String, dynamic>> getReadingStatistics() async {
    try {
      if (!_supabase.isAuthenticated) {
        throw Exception('用戶未登入');
      }

      final userId = _supabase.currentUser!.id;

      // 獲取總閱讀時間
      final timeResponse = await _supabase.readingHistory
          .select('reading_time_minutes')
          .eq('user_id', userId);

      final totalReadingTime = (timeResponse as List)
          .fold<int>(0, (sum, item) => sum + (item['reading_time_minutes'] as int? ?? 0));

      // 獲取閱讀書籍數量
      final booksResponse = await _supabase.readingHistory
          .select('book_id')
          .eq('user_id', userId);

      final totalBooks = booksResponse.length;

      // 獲取完成的書籍數量（進度 >= 95%）
      final completedResponse = await _supabase.readingHistory
          .select('id')
          .eq('user_id', userId)
          .gte('progress', 0.95);

      final completedBooks = completedResponse.length;

      // 獲取平均閱讀進度
      final progressResponse = await _supabase.readingHistory
          .select('progress')
          .eq('user_id', userId);

      final averageProgress = (progressResponse as List).isNotEmpty
          ? (progressResponse.fold<double>(0, (sum, item) => sum + (item['progress'] as double? ?? 0)) / progressResponse.length)
          : 0.0;

      return {
        'totalReadingTime': totalReadingTime,
        'totalBooks': totalBooks,
        'completedBooks': completedBooks,
        'averageProgress': averageProgress,
        'completionRate': totalBooks > 0 ? completedBooks / totalBooks : 0.0,
      };

    } catch (e) {
      if (kDebugMode) {
        print('❌ 獲取閱讀統計失敗: $e');
      }
      return {
        'totalReadingTime': 0,
        'totalBooks': 0,
        'completedBooks': 0,
        'averageProgress': 0.0,
        'completionRate': 0.0,
      };
    }
  }

  // 獲取最近閱讀的書籍
  Future<List<ReadingHistory>> getRecentReadingBooks({int limit = 10}) async {
    try {
      if (!_supabase.isAuthenticated) {
        return [];
      }

      final response = await _supabase.readingHistory
          .select('''
            *,
            ${_supabase.booksTable}!inner(
              id, title, author, cover_url, file_type
            )
          ''')
          .eq('user_id', _supabase.currentUser!.id)
          .order('last_read_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ReadingHistory.fromJson(json))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('❌ 獲取最近閱讀書籍失敗: $e');
      }
      return [];
    }
  }

  // 獲取正在閱讀的書籍（進度 > 0 且 < 95%）
  Future<List<ReadingHistory>> getCurrentlyReadingBooks() async {
    try {
      if (!_supabase.isAuthenticated) {
        return [];
      }

      final response = await _supabase.readingHistory
          .select('''
            *,
            ${_supabase.booksTable}!inner(
              id, title, author, cover_url, file_type
            )
          ''')
          .eq('user_id', _supabase.currentUser!.id)
          .gt('progress', 0)
          .lt('progress', 0.95)
          .order('last_read_at', ascending: false);

      return (response as List)
          .map((json) => ReadingHistory.fromJson(json))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('❌ 獲取正在閱讀書籍失敗: $e');
      }
      return [];
    }
  }
}