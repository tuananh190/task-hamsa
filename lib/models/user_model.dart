class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role; // 'admin' or 'employee'
  final bool isActive;
  final String avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'employee',
      isActive: json['isActive'] ?? true,
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'avatarUrl': avatarUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    bool? isActive,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
