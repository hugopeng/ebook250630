import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import 'supabase_service.dart';

class BookService {
  static BookService? _instance;
  static BookService get instance => _instance ??= BookService._();
  
  BookService._();

  final _supabase = SupabaseService.instance;

  // Get books with filtering, sorting, and pagination
  Future<List<Book>> getBooks({
    String? search,
    String? status,
    String? category,
    String? sortBy,
    bool ascending = false,
    int? limit,
    int? offset,
    bool adminView = false,
  }) async {
    try {
      var query = _supabase.books.select();

      // If not admin view, only show published books
      if (!adminView) {
        query = query.eq('is_published', true);
      }

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        query = query.or('title.ilike.%$search%,author.ilike.%$search%,description.ilike.%$search%');
      }

      // Apply status filter (for admin view)
      if (adminView && status != null && status != 'all') {
        switch (status) {
          case 'published':
            query = query.eq('is_published', true);
            break;
          case 'pending':
            query = query.eq('is_published', false);
            break;
        }
      }

      // Apply category filter
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // Apply sorting
      if (sortBy != null) {
        query = query.order(sortBy, ascending: ascending);
      } else {
        query = query.order('created_at', ascending: false);
      }

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        }
      }

      final response = await query;
      
      return (response as List)
          .map((book) => Book.fromJson(book))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting books: $e');
      }
      return [];
    }
  }

  // Get books count for pagination
  Future<int> getBooksCount({
    String? search,
    String? status,
    String? category,
    bool adminView = false,
  }) async {
    try {
      var query = _supabase.books.select('id');

      if (!adminView) {
        query = query.eq('is_published', true);
      }

      if (search != null && search.isNotEmpty) {
        query = query.or('title.ilike.%$search%,author.ilike.%$search%,description.ilike.%$search%');
      }

      if (adminView && status != null && status != 'all') {
        switch (status) {
          case 'published':
            query = query.eq('is_published', true);
            break;
          case 'pending':
            query = query.eq('is_published', false);
            break;
        }
      }

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query;
      return response.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting books count: $e');
      }
      return 0;
    }
  }

  // Get single book by ID
  Future<Book?> getBookById(String bookId) async {
    try {
      final response = await _supabase.books
          .select()
          .eq('id', bookId)
          .maybeSingle();

      if (response != null) {
        return Book.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting book: $e');
      }
      return null;
    }
  }

  // Create new book
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
    try {
      final currentUser = _supabase.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to create books');
      }

      final bookData = {
        'title': title,
        'author': author,
        'file_path': filePath,
        'file_type': fileType,
        'description': description,
        'category': category,
        'product_code': productCode,
        'cover_url': coverUrl,
        'is_published': isPublished,
        'is_free': isFree,
        'uploader_id': currentUser.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.books
          .insert(bookData)
          .select()
          .single();

      if (kDebugMode) {
        print('✅ Book created successfully: ${response['title']}');
      }

      return Book.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating book: $e');
      }
      return null;
    }
  }

  // Update book
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
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (author != null) updates['author'] = author;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (productCode != null) updates['product_code'] = productCode;
      if (filePath != null) updates['file_path'] = filePath;
      if (fileType != null) updates['file_type'] = fileType;
      if (coverUrl != null) updates['cover_url'] = coverUrl;
      if (isPublished != null) updates['is_published'] = isPublished;
      if (isFree != null) updates['is_free'] = isFree;

      final response = await _supabase.books
          .update(updates)
          .eq('id', bookId)
          .select()
          .single();

      if (kDebugMode) {
        print('✅ Book updated successfully');
      }

      return Book.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating book: $e');
      }
      return null;
    }
  }

  // Toggle book publication status
  Future<bool> togglePublishStatus(String bookId) async {
    try {
      final book = await _supabase.books
          .select('is_published')
          .eq('id', bookId)
          .single();

      final newStatus = !(book['is_published'] as bool);

      await _supabase.books
          .update({
            'is_published': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookId);

      if (kDebugMode) {
        print('✅ Book publish status toggled: $newStatus');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling publish status: $e');
      }
      return false;
    }
  }

  // Delete book
  Future<bool> deleteBook(String bookId) async {
    try {
      await _supabase.books.delete().eq('id', bookId);

      if (kDebugMode) {
        print('✅ Book deleted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting book: $e');
      }
      return false;
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String bookId) async {
    try {
      await _supabase.client.rpc('increment_view_count', params: {'book_id': bookId});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error incrementing view count: $e');
      }
    }
  }

  // Get recent books
  Future<List<Book>> getRecentBooks({int limit = 5, bool adminView = false}) async {
    return getBooks(
      sortBy: 'created_at',
      ascending: false,
      limit: limit,
      adminView: adminView,
    );
  }

  // Get pending books (for admin)
  Future<List<Book>> getPendingBooks({int limit = 5}) async {
    return getBooks(
      status: 'pending',
      sortBy: 'created_at',
      ascending: false,
      limit: limit,
      adminView: true,
    );
  }

  // Get statistics for admin dashboard
  Future<Map<String, int>> getBookStatistics() async {
    try {
      final allBooks = await _supabase.books.select('is_published');
      
      final totalBooks = allBooks.length;
      final publishedBooks = allBooks.where((book) => book['is_published'] == true).length;
      final pendingBooks = totalBooks - publishedBooks;

      return {
        'total': totalBooks,
        'published': publishedBooks,
        'pending': pendingBooks,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting book statistics: $e');
      }
      return {
        'total': 0,
        'published': 0,
        'pending': 0,
      };
    }
  }

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase.books
          .select('category')
          .not('category', 'is', null);

      final categories = <String>{};
      for (final book in response) {
        final category = book['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting categories: $e');
      }
      return [];
    }
  }
}