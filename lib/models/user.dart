import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final bool isAdmin;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const User({
    required this.id,
    this.username,
    this.email,
    this.avatarUrl,
    this.isAdmin = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    bool? isAdmin,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, isAdmin: $isAdmin, isActive: $isActive}';
  }
}