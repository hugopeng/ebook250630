import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
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
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

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