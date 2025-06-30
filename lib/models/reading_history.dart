class ReadingHistory {
  final String id;
  final String bookId;
  final String userId;
  final int currentPage;
  final double progress;
  final DateTime lastReadAt;
  final int readingTimeMinutes;

  const ReadingHistory({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.currentPage,
    required this.progress,
    required this.lastReadAt,
    required this.readingTimeMinutes,
  });

  factory ReadingHistory.fromJson(Map<String, dynamic> json) {
    return ReadingHistory(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      userId: json['user_id'] as String,
      currentPage: json['current_page'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
      readingTimeMinutes: json['reading_time_minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
      'current_page': currentPage,
      'progress': progress,
      'last_read_at': lastReadAt.toIso8601String(),
      'reading_time_minutes': readingTimeMinutes,
    };
  }

  ReadingHistory copyWith({
    String? id,
    String? bookId,
    String? userId,
    int? currentPage,
    double? progress,
    DateTime? lastReadAt,
    int? readingTimeMinutes,
  }) {
    return ReadingHistory(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      currentPage: currentPage ?? this.currentPage,
      progress: progress ?? this.progress,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
    );
  }

  // Helper methods
  String get progressPercentage => '${(progress * 100).toStringAsFixed(1)}%';
  
  bool get isCompleted => progress >= 1.0;
  
  String get readingTime {
    if (readingTimeMinutes < 60) {
      return '${readingTimeMinutes}分鐘';
    } else {
      final hours = readingTimeMinutes ~/ 60;
      final minutes = readingTimeMinutes % 60;
      return '${hours}小時${minutes}分鐘';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingHistory && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReadingHistory{id: $id, bookId: $bookId, userId: $userId, progress: $progress}';
  }
}