import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'Admin', 'Staff'
  final bool isActive;
  final String avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.avatarUrl = '',
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Staff',
      isActive: json['isActive'] ?? true,
      avatarUrl: json['avatarUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    bool? isActive,
    String? avatarUrl,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: this.createdAt,
    );
  }
}
