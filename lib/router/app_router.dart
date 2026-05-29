// =============================================================================
// APP ROUTER — Hệ thống điều hướng với phân quyền tự động
// Dùng go_router v17 (đã có trong pubspec.yaml)
//
// Logic routing:
//   Chưa đăng nhập           → redirect /login
//   Đã đăng nhập (admin)     → /home (4 tab)
//   Đã đăng nhập (employee)  → /home (3 tab, không có /users)
//   Employee vào /users       → redirect /home
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/main_layout.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/products/product_form_screen.dart';
import '../screens/orders/order_list_screen.dart';
import '../screens/orders/create_order_screen.dart';
import '../screens/users/user_list_screen.dart';
import '../screens/profile/profile_screen.dart';

// -----------------------------------------------------------------------------
// ROUTE NAMES — Dùng constant thay vì hard-code string để tránh typo
// -----------------------------------------------------------------------------
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String terminal = '/terminal'; // Thêm mới cho Terminal (POS)
  static const String products = '/products';
  static const String productAdd = '/products/add';
  static const String productEdit = '/products/edit';
  static const String orders = '/orders';
  static const String orderCreate = '/orders/create';
  static const String users = '/users';
  static const String profile = '/profile';
}

// -----------------------------------------------------------------------------
// ROUTER PROVIDER — Trả về GoRouter đã cấu hình đầy đủ
// authProvider được truyền vào để router lắng nghe thay đổi auth state
// -----------------------------------------------------------------------------
GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    // Mỗi khi authProvider thay đổi (login/logout/role change), router refresh
    refreshListenable: authProvider,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: false, // Bật true khi cần debug navigation

    // -------------------------------------------------------------------------
    // REDIRECT GUARD — Chạy trước mỗi lần điều hướng
    // -------------------------------------------------------------------------
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = authProvider.isLoading;
      final isAuthenticated = authProvider.isAuthenticated;
      final isAdmin = authProvider.isAdmin;

      // Đang tải thông tin user → không redirect, đợi
      if (isLoading) return null;

      final isOnLoginPage = state.matchedLocation == AppRoutes.login;

      // Chưa đăng nhập → bắt buộc về Login
      if (!isAuthenticated && !isOnLoginPage) {
        return AppRoutes.login;
      }

      // Đã đăng nhập mà vẫn ở Login page → vào Home
      if (isAuthenticated && isOnLoginPage) {
        return AppRoutes.home;
      }

      // Employee cố vào trang Users (chỉ dành cho Admin) → về Home
      if (!isAdmin && state.matchedLocation.startsWith(AppRoutes.users)) {
        return AppRoutes.home;
      }

      // Các trường hợp còn lại → cho đi bình thường
      return null;
    },

    // -------------------------------------------------------------------------
    // ROUTES — Định nghĩa toàn bộ màn hình
    // -------------------------------------------------------------------------
    routes: [
      // --- Login ---
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // --- Main Shell (chứa Navigation Rail + các tab) ---
      // ShellRoute giúp Navigation Sidebar không bị rebuild khi chuyển tab
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Tab 1: Terminal (POS / Tạo đơn)
          GoRoute(
            path: AppRoutes.terminal,
            name: 'terminal',
            builder: (context, state) => const CreateOrderScreen(),
          ),

          // Tab 2: Sản phẩm (Inventory)
          GoRoute(
            path: AppRoutes.products,
            name: 'products',
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'productAdd',
                builder: (context, state) => const ProductFormScreen(),
              ),
              GoRoute(
                path: 'edit',
                name: 'productEdit',
                builder: (context, state) => ProductFormScreen(
                  product: state.extra as dynamic,
                ),
              ),
            ],
          ),

          // Tab 3: Đơn hàng (Orders)
          GoRoute(
            path: AppRoutes.orders,
            name: 'orders',
            builder: (context, state) => const OrderListScreen(),
          ),

          // Tab 4: Nhân viên (chỉ Admin)
          GoRoute(
            path: AppRoutes.users,
            name: 'users',
            builder: (context, state) => const UserListScreen(),
          ),

          // Tab 5: Profile / Settings
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Redirect /home → /terminal (màn hình mặc định)
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            redirect: (context, state) => AppRoutes.terminal,
          ),
        ],
      ),
    ],

    // -------------------------------------------------------------------------
    // ERROR PAGE — Hiện khi route không tồn tại
    // -------------------------------------------------------------------------
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0D1600),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF39FF14), size: 64),
            const SizedBox(height: 16),
            Text(
              '404 — Trang không tồn tại',
              style: const TextStyle(
                color: Color(0xFFE8F5E0),
                fontSize: 20,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: const TextStyle(color: Color(0xFF6F7B68), fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: const Color(0xFF0D1600),
              ),
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Về trang chính'),
            ),
          ],
        ),
      ),
    ),
  );
}
