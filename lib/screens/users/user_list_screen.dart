// =============================================================================
// USER LIST SCREEN (CUSTOMERS / STAFF)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';
import 'widgets/user_form_modal.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _filterRole = 'All'; // All, Admin, Staff

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final allUsers = userProvider.users;
          
          // Thống kê
          final totalUsers = allUsers.length;
          final activeUsers = allUsers.where((u) => u.isActive).length;
          final adminUsers = allUsers.where((u) => u.role == 'Admin').length;

          // Lọc data list
          final displayUsers = _filterRole == 'All' 
              ? allUsers 
              : allUsers.where((u) => u.role == _filterRole).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quản lý Nhân viên', style: AppTextStyles.headlineLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Quản lý tài khoản, phân quyền và trạng thái hoạt động của đội ngũ.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => showAddUserModal(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tạo tài khoản mới'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // THỐNG KÊ (3 CARDS)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard(Icons.badge_outlined, 'Tổng nhân viên', totalUsers.toString())),
                    const SizedBox(width: 24),
                    Expanded(child: _buildStatCard(Icons.check_circle_outline, 'Đang hoạt động', activeUsers.toString(), isHighlight: true)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildStatCard(Icons.admin_panel_settings_outlined, 'Quản trị viên', adminUsers.toString())),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BẢNG DỮ LIỆU
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // TOOLBAR LỌC & SẮP XẾP
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (val) => setState(() => _filterRole = val),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'All', child: Text('Tất cả')),
                                    const PopupMenuItem(value: 'Admin', child: Text('Chỉ Admin')),
                                    const PopupMenuItem(value: 'Staff', child: Text('Chỉ Nhân viên')),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.filter_list, size: 16),
                                        const SizedBox(width: 8),
                                        Text(_filterRole == 'All' ? 'Lọc theo vai trò' : _filterRole),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.all(12),
                                minimumSize: const Size(0, 0),
                              ),
                              child: const Icon(Icons.file_download_outlined, size: 20),
                            ),
                          ],
                        ),
                      ),

                      // TH HEADER
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.border), top: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('NHÂN VIÊN', style: AppTextStyles.labelMonoSmall)),
                            Expanded(flex: 2, child: Text('VAI TRÒ', style: AppTextStyles.labelMonoSmall)),
                            Expanded(flex: 2, child: Text('TRẠNG THÁI', style: AppTextStyles.labelMonoSmall)),
                            const SizedBox(width: 60, child: Text('THAO TÁC', style: AppTextStyles.labelMonoSmall, textAlign: TextAlign.center)),
                          ],
                        ),
                      ),

                      // TBODY LIST
                      Expanded(
                        child: userProvider.isLoading && allUsers.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.separated(
                                itemCount: displayUsers.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final user = displayUsers[index];
                                  final bool isActive = user.isActive;
                                  final String role = user.role;
                                  final bool isAdmin = role == 'Admin';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: AppColors.surfaceElevated,
                                                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                                                child: user.avatarUrl.isEmpty ? Icon(Icons.person, color: isAdmin ? AppColors.primary : AppColors.neutral) : null,
                                              ),
                                              const SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(user.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Text(user.email, style: AppTextStyles.bodySmall),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceElevated,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: isAdmin ? AppColors.primary.withOpacity(0.3) : AppColors.border),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: AppTextStyles.labelMonoSmall.copyWith(
                                                    color: isAdmin ? AppColors.primary : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Switch(
                                                value: isActive,
                                                onChanged: (val) {
                                                  userProvider.toggleUserStatus(user.id, user.isActive);
                                                },
                                                activeColor: AppColors.primary,
                                                activeTrackColor: AppColors.primary.withOpacity(0.3),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(isActive ? 'Mở' : 'Đóng', style: AppTextStyles.bodyMedium),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 60,
                                          child: Icon(Icons.more_horiz, color: AppColors.neutral),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHighlight ? AppColors.secondary.withOpacity(0.15) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isHighlight ? AppColors.secondary : AppColors.tertiary, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelMonoSmall),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.headlineLarge),
            ],
          ),
        ],
      ),
    );
  }
}
