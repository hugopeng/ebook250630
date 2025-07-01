import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../services/search_service.dart';

// 搜尋狀態
class SearchState {
  final List<Book> results;
  final bool isLoading;
  final String? error;
  final bool hasSearched;
  final String? lastQuery;
  final String? lastCategory;
  final String? lastFileType;
  final double? lastMinRating;
  final bool lastSortByRating;
  final bool lastSortByDate;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
    this.lastQuery,
    this.lastCategory,
    this.lastFileType,
    this.lastMinRating,
    this.lastSortByRating = false,
    this.lastSortByDate = false,
  });

  SearchState copyWith({
    List<Book>? results,
    bool? isLoading,
    String? error,
    bool? hasSearched,
    String? lastQuery,
    String? lastCategory,
    String? lastFileType,
    double? lastMinRating,
    bool? lastSortByRating,
    bool? lastSortByDate,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasSearched: hasSearched ?? this.hasSearched,
      lastQuery: lastQuery ?? this.lastQuery,
      lastCategory: lastCategory ?? this.lastCategory,
      lastFileType: lastFileType ?? this.lastFileType,
      lastMinRating: lastMinRating ?? this.lastMinRating,
      lastSortByRating: lastSortByRating ?? this.lastSortByRating,
      lastSortByDate: lastSortByDate ?? this.lastSortByDate,
    );
  }
}

// 搜尋過濾器
class SearchFilters {
  final String? query;
  final String? category;
  final String? fileType;
  final double? minRating;
  final bool sortByRating;
  final bool sortByDate;
  final int limit;
  final int offset;

  const SearchFilters({
    this.query,
    this.category,
    this.fileType,
    this.minRating,
    this.sortByRating = false,
    this.sortByDate = false,
    this.limit = 20,
    this.offset = 0,
  });

  SearchFilters copyWith({
    String? query,
    String? category,
    String? fileType,
    double? minRating,
    bool? sortByRating,
    bool? sortByDate,
    int? limit,
    int? offset,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      category: category ?? this.category,
      fileType: fileType ?? this.fileType,
      minRating: minRating ?? this.minRating,
      sortByRating: sortByRating ?? this.sortByRating,
      sortByDate: sortByDate ?? this.sortByDate,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  bool get isEmpty {
    return query == null &&
           category == null &&
           fileType == null &&
           minRating == null &&
           !sortByRating &&
           !sortByDate;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    
    if (query != null) map['query'] = query;
    if (category != null) map['category'] = category;
    if (fileType != null) map['file_type'] = fileType;
    if (minRating != null) map['min_rating'] = minRating;
    if (sortByRating) map['sort_by_rating'] = true;
    if (sortByDate) map['sort_by_date'] = true;
    
    map['limit'] = limit;
    map['offset'] = offset;
    
    return map;
  }
}

// 搜尋建議
class SearchSuggestion {
  final String text;
  final SearchSuggestionType type;
  final int count;

  const SearchSuggestion({
    required this.text,
    required this.type,
    this.count = 0,
  });
}

enum SearchSuggestionType {
  title,
  author,
  category,
  recent,
}

// 搜尋狀態管理器
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._searchService) : super(const SearchState());

  final SearchService _searchService;
  
  // 搜尋歷史（最多保存20個）
  List<String> _searchHistory = [];
  
  // 快取搜尋結果（簡單的內存快取）
  final Map<String, List<Book>> _searchCache = {};

  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  // 執行搜尋
  Future<void> searchBooks({
    String? query,
    String? category,
    String? fileType,
    double? minRating,
    bool sortByRating = false,
    bool sortByDate = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final filters = SearchFilters(
      query: query?.trim().isEmpty == true ? null : query?.trim(),
      category: category,
      fileType: fileType,
      minRating: minRating,
      sortByRating: sortByRating,
      sortByDate: sortByDate,
      limit: limit,
      offset: offset,
    );

    // 如果沒有任何搜尋條件，直接返回
    if (filters.isEmpty) {
      print('🚫 搜尋條件為空，不執行搜尋');
      state = state.copyWith(
        results: [],
        hasSearched: false,
        error: null,
      );
      return;
    }
    
    print('✅ 開始執行搜尋，條件: ${filters.query}');

    // 開始載入
    state = state.copyWith(
      isLoading: true,
      error: null,
      lastQuery: query,
      lastCategory: category,
      lastFileType: fileType,
      lastMinRating: minRating,
      lastSortByRating: sortByRating,
      lastSortByDate: sortByDate,
    );

    try {
      // 檢查快取
      final cacheKey = _generateCacheKey(filters);
      if (_searchCache.containsKey(cacheKey) && offset == 0) {
        state = state.copyWith(
          results: _searchCache[cacheKey]!,
          isLoading: false,
          hasSearched: true,
        );
        return;
      }

      // 執行搜尋
      final results = await _searchService.searchBooks(filters);
      print('📊 搜尋完成，找到 ${results.length} 筆結果');
      
      // 更新搜尋歷史
      if (query != null && query.isNotEmpty) {
        _addToSearchHistory(query);
      }
      
      // 快取結果（僅快取前20個結果）
      if (offset == 0 && results.length <= 20) {
        _searchCache[cacheKey] = results;
        
        // 限制快取大小
        if (_searchCache.length > 50) {
          final oldestKey = _searchCache.keys.first;
          _searchCache.remove(oldestKey);
        }
      }

      final newResults = offset == 0 ? results : [...state.results, ...results];
      print('🔄 更新狀態，總結果數: ${newResults.length}');
      
      state = state.copyWith(
        results: newResults,
        isLoading: false,
        hasSearched: true,
      );
      
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
        hasSearched: true,
      );
    }
  }

  // 載入更多結果
  Future<void> loadMoreResults() async {
    if (state.isLoading || !state.hasSearched) return;

    await searchBooks(
      query: state.lastQuery,
      category: state.lastCategory,
      fileType: state.lastFileType,
      minRating: state.lastMinRating,
      sortByRating: state.lastSortByRating,
      sortByDate: state.lastSortByDate,
      offset: state.results.length,
    );
  }

  // 清除搜尋
  void clearSearch() {
    state = const SearchState();
  }

  // 獲取搜尋建議
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      // 返回搜尋歷史
      return _searchHistory
          .map((text) => SearchSuggestion(
                text: text,
                type: SearchSuggestionType.recent,
              ))
          .toList();
    }

    try {
      return await _searchService.getSearchSuggestions(query);
    } catch (error) {
      // 如果獲取建議失敗，返回匹配的搜尋歷史
      return _searchHistory
          .where((text) => text.toLowerCase().contains(query.toLowerCase()))
          .map((text) => SearchSuggestion(
                text: text,
                type: SearchSuggestionType.recent,
              ))
          .toList();
    }
  }

  // 獲取熱門搜尋詞
  Future<List<SearchSuggestion>> getPopularSearches() async {
    try {
      return await _searchService.getPopularSearches();
    } catch (error) {
      return [];
    }
  }

  // 添加到搜尋歷史
  void _addToSearchHistory(String query) {
    _searchHistory.remove(query); // 移除重複項
    _searchHistory.insert(0, query); // 添加到開頭
    
    // 限制歷史數量
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }
  }

  // 生成快取鍵
  String _generateCacheKey(SearchFilters filters) {
    return filters.toMap().toString();
  }

  // 清除快取
  void clearCache() {
    _searchCache.clear();
  }

  // 清除搜尋歷史
  void clearSearchHistory() {
    _searchHistory.clear();
  }

  // 從搜尋歷史中移除項目
  void removeFromSearchHistory(String query) {
    _searchHistory.remove(query);
  }
}

// 提供者
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchNotifier(searchService);
});

// 搜尋建議提供者
final searchSuggestionsProvider = FutureProvider.family<List<SearchSuggestion>, String>((ref, query) {
  final searchNotifier = ref.watch(searchNotifierProvider.notifier);
  return searchNotifier.getSearchSuggestions(query);
});

// 熱門搜尋提供者
final popularSearchesProvider = FutureProvider<List<SearchSuggestion>>((ref) {
  final searchNotifier = ref.watch(searchNotifierProvider.notifier);
  return searchNotifier.getPopularSearches();
});

// 搜尋歷史提供者
final searchHistoryProvider = Provider<List<String>>((ref) {
  final searchNotifier = ref.watch(searchNotifierProvider.notifier);
  return searchNotifier.searchHistory;
});