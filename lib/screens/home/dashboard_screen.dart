import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../router/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<DashboardProvider>().loadDashboardData(
            isAdmin: authProvider.isAdmin,
            employeeId: authProvider.currentUser?.id,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final currentUser = authProvider.currentUser;
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dashboardProvider.loadDashboardData(
                isAdmin: isAdmin,
                employeeId: currentUser?.id,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(currentUser?.name ?? 'User'),
                    const SizedBox(height: 32),

                    if (isAdmin)
                      _buildAdminDashboard(dashboardProvider)
                    else
                      _buildEmployeeDashboard(dashboardProvider, context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: AppTextStyles.headlineLarge.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          'Chào buổi sáng, $name. Chúc bạn một ngày làm việc hiệu quả!',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // =========================================================================
  // ADMIN DASHBOARD
  // =========================================================================
  Widget _buildAdminDashboard(DashboardProvider provider) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Cards
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            _buildStatCard(
              title: 'DOANH THU TỔNG', // [UPDATE] Đổi tên tiêu đề
              value: currencyFormat.format(provider.todayRevenue),
              icon: Icons.attach_money,
              color: AppColors.primary,
            ),
            _buildStatCard(
              title: 'ĐƠN CHỜ XỬ LÝ',
              value: provider.pendingOrdersCount.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: 'SẢN PHẨM SẮP HẾT',
              value: provider.lowStockCount.toString(),
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Recent Orders List
        Text('ĐƠN HÀNG GẦN ĐÂY', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: provider.recentOrders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Chưa có đơn hàng nào.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.recentOrders.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = provider.recentOrders[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      title: Text(order.id, style: AppTextStyles.bodyMedium),
                      subtitle: Text(
                        '${order.customerName} • ${currencyFormat.format(order.totalAmount)}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: _buildStatusBadge(order.status),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // =========================================================================
  // EMPLOYEE DASHBOARD
  // =========================================================================
  Widget _buildEmployeeDashboard(DashboardProvider provider, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.terminal),
                icon: const Icon(Icons.point_of_sale, size: 28),
                label: const Text('TẠO ĐƠN HÀNG MỚI (POS)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  textStyle: AppTextStyles.buttonLarge,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.products),
                icon: const Icon(Icons.inventory_2_outlined, size: 28),
                label: const Text('QUẢN LÝ KHO'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  textStyle: AppTextStyles.buttonLarge,
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Grid Cards
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3,
          children: [
            _buildStatCard(
              title: 'SỐ ĐƠN ĐÃ TẠO HÔM NAY',
              value: provider.employeeTodayOrdersCount.toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.primary,
            ),
            _buildStatCard(
              title: 'ĐƠN CHỜ ĐÓNG GÓI (HỆ THỐNG)',
              value: provider.pendingOrdersCount.toString(),
              icon: Icons.inventory_outlined,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // UI HELPERS
  // =========================================================================
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.labelMonoSmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 28, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'new_order':
        color = Colors.blue;
        text = 'MỚI';
        break;
      case 'processing':
        color = Colors.orange;
        text = 'CHỜ XỬ LÝ';
        break;
      case 'completed':
        color = AppColors.primary;
        text = 'HOÀN THÀNH';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'ĐÃ HỦY';
        break;
      default:
        color = AppColors.neutral;
        text = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelMonoSmall.copyWith(color: color),
      ),
    );
  }
}
