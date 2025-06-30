import 'package:json_annotation/json_annotation.dart';

part 'rating.g.dart';

@JsonSerializable()
class Rating {
  final String id;
  final String bookId;
  final String userId;
  final int rating;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Rating({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);
  Map<String, dynamic> toJson() => _$RatingToJson(this);

  Rating copyWith({
    String? id,
    String? bookId,
    String? userId,
    int? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get hasReview => review != null && review!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rating && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Rating{id: $id, bookId: $bookId, userId: $userId, rating: $rating}';
  }
}