import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Cấu hình ThemeData cho chế độ sáng/tối theo màu nhấn đang chọn.
class AppTheme {
  const AppTheme._();

  static ThemeData light(Color accent) => _build(accent, Brightness.light);

  static ThemeData dark(Color accent) => _build(accent, Brightness.dark);

  static ThemeData _build(Color accent, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color surface = isDark ? AppColors.darkSurface : AppColors.white;
    final Color onSurface =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final Color outline = isDark ? AppColors.darkBorder : AppColors.border;
    final Color fill = isDark ? AppColors.darkSurface : AppColors.surfaceMuted;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.danger,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: AppSpacing.fieldRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      textTheme: base.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      iconTheme: IconThemeData(color: onSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fill,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor:
            isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        suffixIconColor:
            isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        border: border(outline),
        enabledBorder: border(outline),
        disabledBorder: border(outline),
        focusedBorder: border(accent, width: 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: outline,
          disabledForegroundColor:
              isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.fieldRadius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size.fromHeight(46),
          side: BorderSide(color: outline),
          shape: const RoundedRectangleBorder(
              borderRadius: AppSpacing.fieldRadius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape:
            const RoundedRectangleBorder(borderRadius: AppSpacing.fieldRadius),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      listTileTheme: ListTileThemeData(
        iconColor:
            isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        textColor: onSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
    );
  }
}

/// Kiểu chữ dùng lại cho các khối nội dung (không phụ thuộc ThemeData).
class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(fontSize: 14, height: 1.4);

  static const TextStyle caption = TextStyle(fontSize: 12, height: 1.35);

  static const TextStyle label =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

  static const TextStyle brand = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );
}
