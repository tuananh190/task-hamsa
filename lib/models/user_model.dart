import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // [UPDATE] Luôn lưu dạng lowercase: 'admin', 'employee'
  final bool isActive;
  final String avatarUrl;
  final String phone; // [UPDATE] Thêm field SĐT
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.avatarUrl = '',
    this.phone = '', // [UPDATE]
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: (json['role'] ?? 'employee').toLowerCase(), // [UPDATE] Chuẩn hóa về lowercase
      isActive: json['isActive'] ?? true,
      avatarUrl: json['avatarUrl'] ?? '',
      phone: json['phone'] ?? '', // [UPDATE]
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role, // [UPDATE] Đã là lowercase từ fromJson/copyWith
      'isActive': isActive,
      'avatarUrl': avatarUrl,
      'phone': phone, // [UPDATE]
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    bool? isActive,
    String? avatarUrl,
    String? phone, // [UPDATE]
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone, // [UPDATE]
      createdAt: this.createdAt,
    );
  }
}
