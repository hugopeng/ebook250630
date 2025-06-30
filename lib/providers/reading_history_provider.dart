import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reading_history.dart';
import '../services/reading_history_service.dart';

// 閱讀歷史狀態
class ReadingHistoryState {
  final List<ReadingHistory> histories;
  final bool isLoading;
  final String? error;

  const ReadingHistoryState({
    this.histories = const [],
    this.isLoading = false,
    this.error,
  });

  ReadingHistoryState copyWith({
    List<ReadingHistory>? histories,
    bool? isLoading,
    String? error,
  }) {
    return ReadingHistoryState(
      histories: histories ?? this.histories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// 閱讀歷史狀態管理器
class ReadingHistoryNotifier extends StateNotifier<ReadingHistoryState> {
  ReadingHistoryNotifier(this._readingHistoryService) 
      : super(const ReadingHistoryState());

  final ReadingHistoryService _readingHistoryService;

  // 獲取用戶的閱讀歷史
  Future<void> loadReadingHistories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final histories = await _readingHistoryService.getUserReadingHistories();
      state = state.copyWith(
        histories: histories,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // 獲取特定書籍的閱讀歷史
  Future<ReadingHistory?> getReadingHistory(String bookId) async {
    try {
      return await _readingHistoryService.getReadingHistory(bookId);
    } catch (error) {
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
      await _readingHistoryService.updateReadingProgress(
        bookId,
        currentPage,
        progress,
      );
      
      // 更新本地狀態
      final updatedHistories = state.histories.map((history) {
        if (history.bookId == bookId) {
          return history.copyWith(
            currentPage: currentPage,
            progress: progress,
            lastReadAt: DateTime.now(),
          );
        }
        return history;
      }).toList();

      // 如果是新的閱讀記錄，添加到列表
      if (!updatedHistories.any((h) => h.bookId == bookId)) {
        final newHistory = ReadingHistory(
          id: '', // 會由服務生成
          bookId: bookId,
          userId: '', // 會由服務填入
          currentPage: currentPage,
          progress: progress,
          lastReadAt: DateTime.now(),
          readingTimeMinutes: 0,
        );
        updatedHistories.insert(0, newHistory);
      }

      state = state.copyWith(histories: updatedHistories);
    } catch (error) {
      // 靜默處理錯誤，不影響閱讀體驗
    }
  }

  // 增加閱讀時間
  Future<void> addReadingTime(String bookId, int minutes) async {
    try {
      await _readingHistoryService.addReadingTime(bookId, minutes);
      
      // 更新本地狀態
      final updatedHistories = state.histories.map((history) {
        if (history.bookId == bookId) {
          return history.copyWith(
            readingTimeMinutes: history.readingTimeMinutes + minutes,
            lastReadAt: DateTime.now(),
          );
        }
        return history;
      }).toList();

      state = state.copyWith(histories: updatedHistories);
    } catch (error) {
      // 靜默處理錯誤
    }
  }

  // 刪除閱讀歷史
  Future<void> deleteReadingHistory(String bookId) async {
    try {
      await _readingHistoryService.deleteReadingHistory(bookId);
      
      final updatedHistories = state.histories
          .where((history) => history.bookId != bookId)
          .toList();
      
      state = state.copyWith(histories: updatedHistories);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // 清除所有閱讀歷史
  Future<void> clearAllReadingHistory() async {
    try {
      await _readingHistoryService.clearAllReadingHistory();
      state = state.copyWith(histories: []);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // 獲取閱讀統計
  Map<String, dynamic> getReadingStats() {
    final histories = state.histories;
    
    if (histories.isEmpty) {
      return {
        'totalBooks': 0,
        'totalReadingTime': 0,
        'averageProgress': 0.0,
        'completedBooks': 0,
        'recentBooks': <ReadingHistory>[],
      };
    }

    final totalBooks = histories.length;
    final totalReadingTime = histories.fold<int>(
      0, 
      (sum, history) => sum + history.readingTimeMinutes,
    );
    
    final averageProgress = histories.fold<double>(
      0, 
      (sum, history) => sum + history.progress,
    ) / histories.length;
    
    final completedBooks = histories
        .where((history) => history.progress >= 0.95)
        .length;
    
    final recentBooks = histories
        .where((history) => history.lastReadAt
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList()
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

    return {
      'totalBooks': totalBooks,
      'totalReadingTime': totalReadingTime,
      'averageProgress': averageProgress,
      'completedBooks': completedBooks,
      'recentBooks': recentBooks.take(5).toList(),
    };
  }
}

// 提供者
final readingHistoryServiceProvider = Provider<ReadingHistoryService>((ref) {
  return ReadingHistoryService();
});

final readingHistoryNotifierProvider = 
    StateNotifierProvider<ReadingHistoryNotifier, ReadingHistoryState>((ref) {
  final readingHistoryService = ref.watch(readingHistoryServiceProvider);
  return ReadingHistoryNotifier(readingHistoryService);
});

// 特定書籍的閱讀歷史提供者
final bookReadingHistoryProvider = 
    FutureProvider.family<ReadingHistory?, String>((ref, bookId) {
  final notifier = ref.watch(readingHistoryNotifierProvider.notifier);
  return notifier.getReadingHistory(bookId);
});

// 閱讀統計提供者
final readingStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(readingHistoryNotifierProvider.notifier);
  return notifier.getReadingStats();
});