import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;
    final currentUser = authProvider.currentUser;

    final currentLocation = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(currentLocation, isAdmin);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(
            context: context,
            isAdmin: isAdmin,
            selectedIndex: selectedIndex,
            currentUser: currentUser,
            authProvider: authProvider,
          ),
          
          // Content Area
          Expanded(child: child),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location, bool isAdmin) {
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.terminal)) return 1;
    if (location.startsWith(AppRoutes.products)) return 2;
    if (location.startsWith(AppRoutes.orders)) return 3;
    if (isAdmin) {
      if (location.startsWith(AppRoutes.users)) return 4;
    }
    return 0; // Default về Dashboard
  }

  Widget _buildSidebar({
    required BuildContext context,
    required bool isAdmin,
    required int selectedIndex,
    required dynamic currentUser,
    required AuthProvider authProvider,
  }) {
    final List<_NavItem> navItems = [
      const _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Trang chủ', // [UPDATE] Đổi từ "Dashboard" -> "Trang chủ"
        route: AppRoutes.dashboard,
      ),
      const _NavItem(
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale,
        label: 'Bán hàng / Tạo đơn', // [UPDATE]
        route: AppRoutes.terminal,
      ),
      const _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Kho hàng', // [UPDATE]
        route: AppRoutes.products,
      ),
      const _NavItem(
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart,
        label: 'Đơn hàng', // [UPDATE]
        route: AppRoutes.orders,
      ),
      if (isAdmin)
        const _NavItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'Quản lý nhân viên', // [UPDATE]
          route: AppRoutes.users,
        ),
    ];

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.background, // Màu nền đen kịt như thiết kế
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo "Otaku Store"
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Otaku\nStore',
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 32,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAdmin ? AppColors.error.withOpacity(0.15) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdmin ? AppColors.error : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                        size: 16,
                        color: isAdmin ? AppColors.error : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAdmin ? 'Vai trò: ADMIN' : 'Vai trò: EMPLOYEE',
                        style: AppTextStyles.labelMono.copyWith(
                          color: isAdmin ? AppColors.error : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == selectedIndex;
                return _buildNavItem(context, item, isSelected);
              }).toList(),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Footer User Profile
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceElevated,
                    backgroundImage: currentUser.avatarUrl != null &&
                            currentUser.avatarUrl.isNotEmpty
                        ? NetworkImage(currentUser.avatarUrl)
                        : null,
                    child: currentUser.avatarUrl == null ||
                            currentUser.avatarUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.neutral)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isAdmin ? 'Quản lý' : 'Nhân viên',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Footer (Settings & Logout)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: Column(
              children: [
                _buildNavItem(
                  context,
                  const _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Cài đặt', // [UPDATE]
                    route: AppRoutes.profile,
                  ),
                  GoRouterState.of(context).matchedLocation.startsWith(AppRoutes.profile),
                ),
                const SizedBox(height: 8),
                // Nút Logout
                InkWell(
                  onTap: () => _confirmLogout(context, authProvider),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: AppColors.tertiary, size: 20),
                        const SizedBox(width: 16),
                        Text(
                          'Đăng xuất', // [UPDATE]
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.tertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (item.route.isNotEmpty) {
            context.go(item.route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng Analytics sắp ra mắt!')),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
                : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                item.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn kết thúc phiên làm việc không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
