import 'dart:async';
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
  // [UPDATE] PageController với viewportFraction 0.95 để ảnh hiển thị to, nhìn táng choạng màn hình
  final PageController _bannerController = PageController(viewportFraction: 0.95);
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  // TODO: Dán các đường link ảnh thực tế vào mảng này (thay thế các phần tử bên dưới khi có ảnh chính thức)
  // [UPDATE] Dùng ảnh local từ assets/images — 10/13 ảnh sẵn có
  static const List<String> bannerImages = [
    'assets/images/BeautyPlus-Image-Enhancer-1746946982349.jpg',
    'assets/images/BeautyPlus-Image-Enhancer-1746973210431.jpg',
    'assets/images/BeautyPlus-Image-Enhancer-1746973816417.jpg',
    'assets/images/BeautyPlus-Image-Enhancer-1747146167076.jpeg',
    'assets/images/BeautyPlus-IMAGE-ENHANCER-1767749362526.jpg',
    'assets/images/Betterimage.ai_1747367733153.jpeg',
    'assets/images/HBgKWeXa0AA_IaN.jpg',
    'assets/images/MV5BZmUyZmE5NzktMTdjOC00ZmM5LTljZTEtNDExMTQ5ZjkyNTZlXkEyXkFqcGc@._V1_.jpg',
    'assets/images/z6410262383036_22b24d1d37c15749067b1ccd76b48839.jpg',
    'assets/images/z6432237870621_565d1eee5995767a5bc908ea7a056499.jpg',
  ];

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
    // [UPDATE] Auto-cuộn theo số lượng bannerImages
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % bannerImages.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel(); // [NEW] Dọn Timer tránh memory leak
    _bannerController.dispose();
    super.dispose();
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
                    _buildHeader(currentUser?.name ?? 'User', isAdmin ? 'SUPER ADMIN' : 'EMPLOYEE'),
                    const SizedBox(height: 32),

                    // Auto-Scroller Banner (Mock UI)
                    _buildBannerSection(),
                    const SizedBox(height: 32),

                    // Quick Actions
                    Text('QUICK ACTIONS', style: AppTextStyles.labelMonoSmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),

                    // System Stats
                    Text('SYSTEM STATS', style: AppTextStyles.labelMonoSmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    _buildSystemStats(dashboardProvider, isAdmin),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String name, String roleName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào mừng, $name',
          style: AppTextStyles.headlineLarge.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          'ROLE: $roleName',
          style: AppTextStyles.labelMonoSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // [UPDATE] Tăng chiều cao lên 420px, dùng ảnh local từ assets
  Widget _buildBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: 420, // [UPDATE] Tăng từ 220 lên 420px
          child: PageView.builder(
            controller: _bannerController,
            itemCount: bannerImages.length,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6), // tăng gap nhẹ giữa các slide
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset( // [UPDATE] Đổi từ Image.network sang Image.asset
                    bannerImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 48, color: AppColors.neutral),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // [UPDATE] Dot indicator theo bannerImages.length
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            bannerImages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentBannerIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentBannerIndex
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Tạo Đơn POS',
            icon: Icons.point_of_sale,
            route: AppRoutes.terminal,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Kho Hàng',
            icon: Icons.inventory_2_outlined,
            route: AppRoutes.products,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildActionCard(
            context: context,
            title: 'Đơn Hàng',
            icon: Icons.receipt_long_outlined,
            route: AppRoutes.orders,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStats(DashboardProvider provider, bool isAdmin) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Row(
      children: [
        // [UPDATE] Ẩn thẻ Doanh Thu nếu không phải là Admin
        if (isAdmin) ...[
          Expanded(
            child: _buildStatCard(
              title: 'DOANH THU HÔM NAY', // Sửa lại title theo thiết kế
              value: currencyFormat.format(provider.todayRevenue),
              subtitle: '↗ +15% so với hôm qua',
              subtitleColor: AppColors.primary,
              icon: Icons.payments_outlined,
              borderColor: AppColors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 24),
        ],
        
        Expanded(
          child: _buildStatCard(
            title: 'ĐƠN CHỜ XỬ LÝ',
            value: provider.pendingOrdersCount.toString(),
            subtitle: '● ĐANG XỬ LÝ',
            subtitleColor: AppColors.primary,
            icon: Icons.pending_actions,
            borderColor: AppColors.border,
          ),
        ),
        const SizedBox(width: 24),
        
        Expanded(
          child: _buildStatCard(
            title: 'CẢNH BÁO TỒN KHO',
            value: provider.lowStockCount.toString(),
            subtitle: 'Xem chi tiết →',
            subtitleColor: AppColors.error,
            icon: Icons.warning_amber_rounded,
            borderColor: AppColors.error.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.labelMonoSmall.copyWith(color: AppColors.textSecondary)),
              Icon(icon, color: AppColors.textSecondary, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.displayLarge.copyWith(fontSize: 36, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }
}
