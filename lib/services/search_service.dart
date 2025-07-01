import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../providers/search_provider.dart';
import 'supabase_service.dart';

class SearchService {
  final SupabaseService _supabase = SupabaseService.instance;

  // 搜尋書籍
  Future<List<Book>> searchBooks(SearchFilters filters) async {
    try {
      dynamic query = _supabase.books.select();

      // 文字搜尋 (書名、作者或描述)
      if (filters.query != null && filters.query!.isNotEmpty) {
        query = query.or('title.ilike.%${filters.query}%,author.ilike.%${filters.query}%,description.ilike.%${filters.query}%');
      }

      // 分類篩選
      if (filters.category != null && filters.category!.isNotEmpty) {
        query = query.eq('category', filters.category!);
      }

      // 檔案類型篩選
      if (filters.fileType != null && filters.fileType!.isNotEmpty) {
        query = query.eq('file_type', filters.fileType!);
      }

      // 評分篩選
      if (filters.minRating != null) {
        query = query.gte('average_rating', filters.minRating!);
      }

      // 只顯示已發布的書籍
      query = query.eq('is_published', true);

      // 分頁
      query = query.range(filters.offset, filters.offset + filters.limit - 1);

      // 排序
      if (filters.sortByRating) {
        query = query.order('average_rating', ascending: false);
      } else if (filters.sortByDate) {
        query = query.order('created_at', ascending: false);
      } else {
        // 預設按創建時間降序排列
        query = query.order('created_at', ascending: false);
      }

      if (kDebugMode) {
        print('🔍 執行搜尋查詢...');
        print('📝 搜尋關鍵字: ${filters.query}');
        print('📊 分類篩選: ${filters.category}');
        print('📁 檔案類型: ${filters.fileType}');
      }

      final response = await query;

      if (kDebugMode) {
        print('🔍 搜尋結果: ${response.length} 筆');
        if (response.isNotEmpty) {
          print('📚 第一筆結果: ${response.first}');
        }
      }

      return (response as List)
          .map((json) => Book.fromJson(json))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('❌ 搜尋失敗: $e');
      }
      throw Exception('搜尋失敗: $e');
    }
  }

  // 獲取搜尋建議
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final suggestions = <SearchSuggestion>[];

      // 搜尋相關書名
      final titleResults = await _supabase.books
          .select('title')
          .ilike('title', '%$query%')
          .eq('is_published', true)
          .limit(5);

      for (final item in titleResults) {
        suggestions.add(SearchSuggestion(
          text: item['title'] as String,
          type: SearchSuggestionType.title,
        ));
      }

      // 搜尋相關作者
      final authorResults = await _supabase.books
          .select('author')
          .ilike('author', '%$query%')
          .eq('is_published', true)
          .limit(5);

      final uniqueAuthors = <String>{};
      for (final item in authorResults) {
        final author = item['author'] as String;
        if (uniqueAuthors.add(author)) {
          suggestions.add(SearchSuggestion(
            text: author,
            type: SearchSuggestionType.author,
          ));
        }
      }

      return suggestions;

    } catch (e) {
      if (kDebugMode) {
        print('❌ 獲取搜尋建議失敗: $e');
      }
      return [];
    }
  }

  // 獲取熱門搜尋詞
  Future<List<SearchSuggestion>> getPopularSearches() async {
    try {
      // 獲取最受歡迎的書籍
      final popularBooks = await _supabase.books
          .select('title, author, total_ratings')
          .eq('is_published', true)
          .gte('total_ratings', 1)
          .order('total_ratings', ascending: false)
          .limit(10);

      final suggestions = <SearchSuggestion>[];

      for (final book in popularBooks) {
        final title = book['title'] as String;
        final totalRatings = book['total_ratings'] as int? ?? 0;

        suggestions.add(SearchSuggestion(
          text: title,
          type: SearchSuggestionType.title,
          count: totalRatings,
        ));
      }

      return suggestions;

    } catch (e) {
      if (kDebugMode) {
        print('❌ 獲取熱門搜尋失敗: $e');
      }
      return [];
    }
  }
}