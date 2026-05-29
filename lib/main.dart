
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/profile_provider.dart';

void main() async {
  // Bước 1: Đảm bảo Flutter engine đã khởi động trước khi gọi native code
  // BẮT BUỘC khi dùng async trong main()
  WidgetsFlutterBinding.ensureInitialized();

  // Bước 2: Kết nối Firebase
  // DefaultFirebaseOptions.currentPlatform tự chọn config đúng (web/android/ios)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const OtakuStoreApp());
}

class OtakuStoreApp extends StatelessWidget {
  const OtakuStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bước 3: MultiProvider — Đăng ký toàn bộ state management
    // Thứ tự quan trọng: AuthProvider phải đứng đầu vì Router phụ thuộc vào nó
    return MultiProvider(
      providers: [
        // AuthProvider: Quản lý toàn bộ trạng thái đăng nhập
        // Được tạo ngay khi app mở → tự động lắng nghe Firebase Auth state
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // UserProvider: Quản lý danh sách nhân viên (chỉ Admin dùng)
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // ProductProvider: Quản lý danh sách + pagination sản phẩm
        ChangeNotifierProvider(create: (_) => ProductProvider()),

        // CartProvider: Giỏ hàng in-memory (không lưu vào Firestore)
        // Sẽ bị xóa khi tạo đơn thành công hoặc khi logout
        ChangeNotifierProvider(create: (_) => CartProvider()),

        // OrderProvider: Quản lý đơn hàng, cần CartProvider nên phụ thuộc vào nó
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // ProfileProvider: Cập nhật profile + avatar + đổi mật khẩu
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],

      // Builder để truy cập AuthProvider sau khi đã khởi tạo
      child: Builder(
        builder: (context) {
          // Bước 4: Tạo Router với AuthProvider
          // Router cần tham chiếu đến AuthProvider để refreshListenable hoạt động
          final authProvider = context.read<AuthProvider>();
          final router = createAppRouter(authProvider);

          return MaterialApp.router(
            // --- App Info ---
            title: 'Otaku Store — Admin Dashboard',

            // --- Theme ---
            theme: AppTheme.darkTheme,    // Light theme (nếu cần)
            darkTheme: AppTheme.darkTheme, // Dark theme chính
            themeMode: ThemeMode.dark,    // Luôn dùng dark mode

            // --- Router ---
            routerConfig: router,

            // --- Debug ---
            debugShowCheckedModeBanner: false, // Ẩn banner "DEBUG" góc phải
          );
        },
      ),
    );
  }
}
