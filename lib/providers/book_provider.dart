import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../services/book_service.dart';

// Book Service Provider
final bookServiceProvider = Provider<BookService>((ref) {
  return BookService.instance;
});

// Books Provider with filters
final booksProvider = FutureProvider.family<List<Book>, Map<String, dynamic>>((ref, params) async {
  return await BookService.instance.getBooks(
    search: params['search'],
    status: params['status'],
    category: params['category'],
    sortBy: params['sortBy'],
    ascending: params['ascending'] ?? false,
    limit: params['limit'],
    offset: params['offset'],
    adminView: params['adminView'] ?? false,
  );
});

// Books Count Provider
final booksCountProvider = FutureProvider.family<int, Map<String, dynamic>>((ref, params) async {
  return await BookService.instance.getBooksCount(
    search: params['search'],
    status: params['status'],
    category: params['category'],
    adminView: params['adminView'] ?? false,
  );
});

// Single Book Provider
final bookProvider = FutureProvider.family<Book?, String>((ref, bookId) async {
  return await BookService.instance.getBookById(bookId);
});

// Book Statistics Provider (for admin dashboard)
final bookStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await BookService.instance.getBookStatistics();
});

// Recent Books Provider
final recentBooksProvider = FutureProvider.family<List<Book>, Map<String, dynamic>>((ref, params) async {
  return await BookService.instance.getRecentBooks(
    limit: params['limit'] ?? 5,
    adminView: params['adminView'] ?? false,
  );
});

// Pending Books Provider (for admin)
final pendingBooksProvider = FutureProvider.family<List<Book>, int>((ref, limit) async {
  return await BookService.instance.getPendingBooks(limit: limit);
});

// Categories Provider
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return await BookService.instance.getCategories();
});

// Book Management Actions
class BookManagementNotifier extends StateNotifier<AsyncValue<void>> {
  BookManagementNotifier() : super(const AsyncValue.data(null));

  Future<Book?> createBook({
    required String title,
    required String author,
    required String filePath,
    required String fileType,
    String? description,
    String? category,
    String? productCode,
    String? coverUrl,
    bool isPublished = false,
    bool isFree = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final book = await BookService.instance.createBook(
        title: title,
        author: author,
        filePath: filePath,
        fileType: fileType,
        description: description,
        category: category,
        productCode: productCode,
        coverUrl: coverUrl,
        isPublished: isPublished,
        isFree: isFree,
      );
      state = const AsyncValue.data(null);
      return book;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<Book?> updateBook(
    String bookId, {
    String? title,
    String? author,
    String? description,
    String? category,
    String? productCode,
    String? filePath,
    String? fileType,
    String? coverUrl,
    bool? isPublished,
    bool? isFree,
  }) async {
    state = const AsyncValue.loading();
    try {
      final book = await BookService.instance.updateBook(
        bookId,
        title: title,
        author: author,
        description: description,
        category: category,
        productCode: productCode,
        filePath: filePath,
        fileType: fileType,
        coverUrl: coverUrl,
        isPublished: isPublished,
        isFree: isFree,
      );
      state = const AsyncValue.data(null);
      return book;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<void> togglePublishStatus(String bookId) async {
    state = const AsyncValue.loading();
    try {
      await BookService.instance.togglePublishStatus(bookId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteBook(String bookId) async {
    state = const AsyncValue.loading();
    try {
      await BookService.instance.deleteBook(bookId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> incrementViewCount(String bookId) async {
    try {
      await BookService.instance.incrementViewCount(bookId);
    } catch (error, stackTrace) {
      // Don't update state for view count errors
    }
  }
}

final bookManagementProvider = StateNotifierProvider<BookManagementNotifier, AsyncValue<void>>((ref) {
  return BookManagementNotifier();
});

// Search State Provider
class SearchState {
  final String query;
  final String? status;
  final String? category;
  final String? sortBy;
  final bool ascending;
  final int page;
  final int itemsPerPage;

  const SearchState({
    this.query = '',
    this.status,
    this.category,
    this.sortBy,
    this.ascending = false,
    this.page = 1,
    this.itemsPerPage = 20,
  });

  SearchState copyWith({
    String? query,
    String? status,
    String? category,
    String? sortBy,
    bool? ascending,
    int? page,
    int? itemsPerPage,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      page: page ?? this.page,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  Map<String, dynamic> toParams({bool adminView = false}) {
    return {
      'search': query.isEmpty ? null : query,
      'status': status,
      'category': category,
      'sortBy': sortBy,
      'ascending': ascending,
      'limit': itemsPerPage,
      'offset': (page - 1) * itemsPerPage,
      'adminView': adminView,
    };
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void updateQuery(String query) {
    state = state.copyWith(query: query, page: 1);
  }

  void updateStatus(String? status) {
    state = state.copyWith(status: status, page: 1);
  }

  void updateCategory(String? category) {
    state = state.copyWith(category: category, page: 1);
  }

  void updateSort(String? sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, ascending: ascending, page: 1);
  }

  void updatePage(int page) {
    state = state.copyWith(page: page);
  }

  void reset() {
    state = const SearchState();
  }
}

final searchStateProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});