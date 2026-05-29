// =============================================================================
// PROFILE SCREEN — Cài Đặt Cá Nhân
// Thiết kế: 2 cột. Trái: Avatar. Phải: Form sửa thông tin và mật khẩu.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _isUploading = false;
  String? _tempAvatarUrl;

  @override
  void initState() {
    super.initState();
    // Load current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _phoneController.text = '+84 123 456 789';
        _tempAvatarUrl = user.avatarUrl;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cài Đặt Cá Nhân', style: AppTextStyles.headlineLarge),
            Text(
              'Quản lý thông tin hồ sơ và bảo mật của bạn.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CỘT TRÁI: Avatar & Vai trò
            Expanded(
              flex: 1,
              child: _buildAvatarCard(user, isAdmin),
            ),
            const SizedBox(width: 32),
            // CỘT PHẢI: Form
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildPasswordCard(),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (user == null) return;
                      
                      // 1. Cập nhật thông tin User model
                      final updatedUser = user.copyWith(
                        name: _nameController.text,
                        avatarUrl: _tempAvatarUrl ?? user.avatarUrl,
                      );
                      
                      // 2. Gọi Provider để lưu (Truyền null cho File vì ảnh đã upload xong rồi)
                      final success = await context.read<ProfileProvider>().updateProfile(updatedUser, null);
                      
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lưu thông tin thành công!')),
                        );
                        // 3. Reload lại dữ liệu AuthProvider để đổi avatar ở Sidebar
                        context.read<AuthProvider>().reloadUser();
                      } else if (mounted) {
                        final error = context.read<ProfileProvider>().error ?? 'Lỗi không xác định';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $error')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save, color: AppColors.background, size: 18),
                    label: const Text('LƯU THAY ĐỔI'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCard(dynamic user, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Avatar có viền neon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: (_tempAvatarUrl != null && _tempAvatarUrl!.isNotEmpty)
                  ? NetworkImage(_tempAvatarUrl!)
                  : null,
              child: (_tempAvatarUrl == null || _tempAvatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user?.name ?? 'Người dùng',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin ? 'Quản trị viên' : 'Nhân viên',
            style: AppTextStyles.labelMono.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              if (_isUploading) return;
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setState(() => _isUploading = true);
                try {
                  Uint8List bytes = await pickedFile.readAsBytes();
                  
                  // Gọi API ImgBB để upload
                  const String imgbbApiKey = "baced8954215221e4686fc77f51f50ab"; 
                  final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
                  final request = http.MultipartRequest('POST', uri);
                  request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'avatar.png'));
                  
                  final response = await request.send();
                  final responseData = await response.stream.bytesToString();
                  final jsonResponse = jsonDecode(responseData);
                  
                  if (jsonResponse['success'] == true) {
                    String downloadUrl = jsonResponse['data']['url'];
                    if (mounted) {
                      setState(() {
                        _tempAvatarUrl = downloadUrl;
                        _isUploading = false;
                      });
                    }
                  } else {
                    throw Exception(jsonResponse['error']['message'] ?? 'Upload thất bại');
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isUploading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
                  }
                }
              }
            },
            icon: _isUploading 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload, size: 18),
            label: Text(_isUploading ? 'ĐANG TẢI...' : 'TẢI ẢNH LÊN'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              const Text('Sửa thông tin', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TÊN HIỂN THỊ', style: AppTextStyles.labelMonoSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Nhập tên của bạn'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SỐ ĐIỆN THOẠI', style: AppTextStyles.labelMonoSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(hintText: '+84 xxx xxx xxx'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              const Text('Đổi mật khẩu', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text('MẬT KHẨU CŨ', style: AppTextStyles.labelMonoSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _oldPasswordController,
            obscureText: _obscureOld,
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: AppColors.neutral),
                onPressed: () => setState(() => _obscureOld = !_obscureOld),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('MẬT KHẨU MỚI', style: AppTextStyles.labelMonoSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppColors.neutral),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
