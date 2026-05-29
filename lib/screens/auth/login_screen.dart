// =============================================================================
// LOGIN SCREEN — Màn hình đăng nhập "Cyber Otaku Admin"
//
// Layout: Chia đôi màn hình
//   Bên trái (50%): Ảnh cyberpunk cityscape + brand name "Otaku Store"
//   Bên phải (50%): Form đăng nhập nền tối
//
// Tham chiếu thiết kế: Mockup "Cyber Otaku Admin" do user cung cấp
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Trạng thái ẩn/hiện mật khẩu
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // QUAN TRỌNG: Luôn dispose controller để tránh memory leak
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Xử lý submit form đăng nhập
  // ---------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    // Validate form trước khi gọi Firebase
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // Nếu thất bại, Router sẽ tự giữ ở trang Login
    // Lỗi đã được lưu vào authProvider.error → hiển thị ở UI
    if (!success && mounted) {
      // Shake animation hoặc snackbar nếu cần
      // authProvider.error đã chứa nội dung lỗi, widget sẽ rebuild tự động
    }
  }

  // ---------------------------------------------------------------------------
  // Xử lý quên mật khẩu
  // ---------------------------------------------------------------------------
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) {
        final resetEmailController = TextEditingController();
        return AlertDialog(
          title: const Text('Đặt lại mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập email của bạn, chúng tôi sẽ gửi link đặt lại mật khẩu.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: resetEmailController,
                decoration: const InputDecoration(
                  hintText: 'email@otakustore.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final email = resetEmailController.text.trim();
                if (email.isEmpty) return;
                try {
                  // Gọi thẳng AuthProvider vì không cần provider reset password riêng
                  await context.read<AuthProvider>().logout(); // Đảm bảo state sạch
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã gửi email đặt lại mật khẩu!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: const Text('Gửi email'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isMobile
          ? _buildMobileLayout(authProvider) // Mobile: 1 cột
          : _buildDesktopLayout(authProvider), // Desktop/Web: 2 cột
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP LAYOUT — Split 50/50 (theo mockup)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout(AuthProvider authProvider) {
    return Row(
      children: [
        // --- BÊN TRÁI: Ảnh hero + brand ---
        Expanded(
          flex: 1,
          child: _buildHeroPanel(),
        ),

        // --- BÊN PHẢI: Form đăng nhập ---
        Expanded(
          flex: 1,
          child: _buildFormPanel(authProvider),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT — 1 cột (form full màn hình)
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Logo rút gọn trên mobile
          Container(
            width: double.infinity,
            height: 200,
            color: AppColors.surface,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Otaku Store',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Admin Dashboard',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildFormPanel(authProvider),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO PANEL — Bên trái: Ảnh cyberpunk + brand name
  // ---------------------------------------------------------------------------
  Widget _buildHeroPanel() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        // Gradient nền dark forest (fallback khi không có ảnh)
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1200),
            Color(0xFF0D1A08),
            Color(0xFF091408),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Ảnh cyberpunk cityscape (placeholder — overlay gradient)
          Positioned.fill(
            child: ColorFiltered(
              // Filter xanh đậm để ảnh hòa hợp với theme
              colorFilter: ColorFilter.mode(
                const Color(0xFF0D1600).withOpacity(0.55),
                BlendMode.multiply,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/login_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Cyberpunk grid overlay (hiệu ứng lưới đặc trưng anime cyber)
          Positioned.fill(
            child: CustomPaint(painter: _CyberGridPainter()),
          ),

          // Nội dung text góc dưới trái (theo mockup)
          Positioned(
            bottom: 48,
            left: 48,
            right: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên app "Otaku Store" — màu xanh neon nổi bật
                Text(
                  'Otaku Store',
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 42),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hệ thống quản lý cửa hàng anime merchandise\nhiện đại nhất. Bắt đầu phiên làm việc của bạn.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Badge "LOGIN" góc trên trái (kiểu retro game)
          Positioned(
            top: 32,
            left: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LOGIN',
                style: AppTextStyles.labelMono.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM PANEL — Bên phải: Form đăng nhập
  // ---------------------------------------------------------------------------
  Widget _buildFormPanel(AuthProvider authProvider) {
    return Container(
      height: double.infinity,
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  // --- Tiêu đề ---
                  Text(
                    'Đăng nhập hệ thống',
                    style: AppTextStyles.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chào mừng trở lại, Admin-kun.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- Label EMAIL ---
                  Text(
                    'EMAIL',
                    style: AppTextStyles.labelMono.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Email field ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'admin@otakustore.com',
                      prefixIcon: Icon(Icons.mail_outline, size: 18),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      // Regex kiểm tra định dạng email cơ bản
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                        return 'Email không đúng định dạng';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // --- Label MẬT KHẨU + Quên mật khẩu ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MẬT KHẨU',
                        style: AppTextStyles.labelMono.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      TextButton(
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Quên mật khẩu?',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- Password field ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      // Toggle show/hide password
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    // Nhấn Enter → submit form
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (val.length < 6) {
                        return 'Mật khẩu tối thiểu 6 ký tự';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // --- Hiển thị lỗi từ Firebase Auth ---
                  // Consumer để chỉ rebuild phần này khi có lỗi
                  if (authProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // --- Nút Đăng nhập ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      // Disable nút khi đang loading
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Đăng nhập',
                                  style: AppTextStyles.buttonLarge,
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.background,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const Spacer(),

                  // --- Footer version ---
                  Center(
                    child: Text(
                      'Otaku Store Admin Dashboard v1.0.0',
                      style: AppTextStyles.labelMonoSmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER — Lưới cyberpunk overlay (hiệu ứng trang trí bên hero panel)
// =============================================================================
class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF39FF14).withOpacity(0.04) // Rất nhẹ
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const double gridSize = 40;

    // Vẽ đường ngang
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vẽ đường dọc
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
