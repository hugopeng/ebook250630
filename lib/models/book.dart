// 書籍模型類別

class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? fileUrl;
  final String filePath;
  final String fileType;
  final String? category;
  final String? productCode;
  final bool isPublished;
  final bool isFree;
  final double? averageRating;
  final int totalRatings;
  final int viewCount;
  final String? uploaderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.fileUrl,
    required this.filePath,
    required this.fileType,
    this.category,
    this.productCode,
    this.isPublished = false,
    this.isFree = true,
    this.averageRating,
    this.totalRatings = 0,
    this.viewCount = 0,
    this.uploaderId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      fileUrl: json['file_url'] as String?,
      filePath: json['file_path'] as String,
      fileType: json['file_type'] as String,
      category: json['category'] as String?,
      productCode: json['product_code'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      isFree: json['is_free'] as bool? ?? true,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalRatings: json['total_ratings'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      uploaderId: json['uploader_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_url': coverUrl,
      'file_url': fileUrl,
      'file_path': filePath,
      'file_type': fileType,
      'category': category,
      'product_code': productCode,
      'is_published': isPublished,
      'is_free': isFree,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'view_count': viewCount,
      'uploader_id': uploaderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    String? fileUrl,
    String? filePath,
    String? fileType,
    String? category,
    String? productCode,
    bool? isPublished,
    bool? isFree,
    double? averageRating,
    int? totalRatings,
    int? viewCount,
    String? uploaderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      category: category ?? this.category,
      productCode: productCode ?? this.productCode,
      isPublished: isPublished ?? this.isPublished,
      isFree: isFree ?? this.isFree,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      viewCount: viewCount ?? this.viewCount,
      uploaderId: uploaderId ?? this.uploaderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isUrl => fileType == 'url';
  
  String get formattedRating => averageRating != null 
      ? averageRating!.toStringAsFixed(1) 
      : '0.0';
  
  String get statusText => isPublished ? '已發布' : '待審核';
  
  String get fileTypeDisplay {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'epub':
        return 'EPUB';
      case 'txt':
        return 'TXT';
      case 'mobi':
        return 'MOBI';
      case 'azw3':
        return 'AZW3';
      case 'url':
        return 'URL';
      default:
        return fileType.toUpperCase();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Book{id: $id, title: $title, author: $author, isPublished: $isPublished}';
  }
}