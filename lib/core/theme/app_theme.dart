// =============================================================================
// APP THEME — "Cyber Otaku Admin"
// Bảng màu được thiết kế theo tông: Dark Forest + Neon Cyber Green
// =============================================================================

import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// BẢNG MÀU CHỦ ĐẠO (Brand Colors)
// -----------------------------------------------------------------------------
class AppColors {
  AppColors._(); // Không cho khởi tạo instance

  // --- Primary: Neon Cyber Green ---
  // Dùng cho: Button chính, tiêu đề nổi bật, icon active, highlight
  static const Color primary = Color(0xFF39FF14);
  static const Color primaryDark = Color(0xFF2BC410);   // Hover state
  static const Color primaryLight = Color(0xFF6FFF50);  // Disabled state

  // --- Secondary: Emerald Green ---
  // Dùng cho: Progress bar, accent phụ, badge success
  static const Color secondary = Color(0xFF50C878);

  // --- Tertiary: Soft Pink ---
  // Dùng cho: Nút xóa, destructive actions, cảnh báo nguy hiểm
  static const Color tertiary = Color(0xFFFFD3CE);
  static const Color error = Color(0xFFFF5A5A); // Lỗi rõ hơn

  // --- Neutral: Muted Green-Gray ---
  // Dùng cho: Text phụ, placeholder, border, icon inactive
  static const Color neutral = Color(0xFF6F7B68);

  // --- Backgrounds (Dark Forest palette) ---
  // Background chính — nền toàn app
  static const Color background = Color(0xFF0D1600);
  // Surface — nền card, form, dialog
  static const Color surface = Color(0xFF1A2510);
  // Surface nâng cao hơn — sidebar, elevated card
  static const Color surfaceElevated = Color(0xFF1F2D14);
  // Border — đường viền card, input
  static const Color border = Color(0xFF2A3B1A);

  // --- Text Colors ---
  static const Color textPrimary = Color(0xFFE8F5E0);    // Chữ chính (trắng xanh)
  static const Color textSecondary = Color(0xFF8FA882);  // Chữ phụ
  static const Color textDisabled = Color(0xFF4A5A42);   // Chữ disabled

  // --- Status Colors (cho Order status chips) ---
  static const Color statusNew = Color(0xFF39FF14);       // new_order → Neon Green
  static const Color statusProcessing = Color(0xFF50C878); // processing → Emerald
  static const Color statusCompleted = Color(0xFF2196F3);  // completed → Blue
  static const Color statusCancelled = Color(0xFFFF5A5A); // cancelled → Red
}

// -----------------------------------------------------------------------------
// TYPOGRAPHY (Font system)
// Headline: Geist | Body: Inter | Label: JetBrains Mono
// Lưu ý: Geist không có trên Google Fonts, dùng 'Outfit' thay thế (closest match)
// Inter và JetBrains Mono có trên Google Fonts
// -----------------------------------------------------------------------------
class AppTextStyles {
  AppTextStyles._();

  // Headline — Outfit (thay cho Geist, tương đồng về kiểu dáng modern)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -1,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body — Inter
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Label — JetBrains Mono (cho badge, mã đơn, tag)
  static const TextStyle labelMono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMonoSmall = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  // Button text
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.background, // Chữ tối trên nền xanh neon
    letterSpacing: 0.5,
  );
}

// -----------------------------------------------------------------------------
// MAIN THEME DATA — ThemeData hoàn chỉnh
// -----------------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // --- Color Scheme ---
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        surface: AppColors.surface,
        onPrimary: AppColors.background,  // Chữ trên primary button
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // --- Background ---
      scaffoldBackgroundColor: AppColors.background,

      // --- AppBar ---
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // --- Card ---
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border),
        ),
      ),

      // --- Input Fields ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: const TextStyle(
          color: AppColors.textDisabled,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
        prefixIconColor: AppColors.neutral,
        suffixIconColor: AppColors.neutral,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // --- ElevatedButton (Button chính — xanh neon) ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          textStyle: AppTextStyles.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),

      // --- TextButton ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // --- OutlinedButton ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      // --- Navigation Rail (Side Navigation) ---
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.primary, size: 24),
        unselectedIconTheme: IconThemeData(color: AppColors.neutral, size: 22),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.neutral,
          fontFamily: 'Inter',
          fontSize: 12,
        ),
        indicatorColor: Color(0x2239FF14), // Primary với opacity 13%
      ),

      // --- Chip (cho status badges) ---
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        labelStyle: AppTextStyles.labelMono,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: AppColors.border),
      ),

      // --- SnackBar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // --- Dialog ---
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTextStyles.headlineSmall,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // --- Text Theme ---
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.labelMono,
      ),
    );
  }
}
