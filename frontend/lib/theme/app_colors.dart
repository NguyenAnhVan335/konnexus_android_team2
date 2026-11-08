import 'package:flutter/material.dart';

/// Bảng màu của ứng dụng.
///
/// Màu chủ đạo #0E526D, nền trắng, nền phụ xám rất nhạt. Các màu trạng thái
/// (thành công/cảnh báo/lỗi) chỉ dùng khi thật sự cần.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF0E526D);
  static const Color primaryDark = Color(0xFF083A4D);
  static const Color primaryLight = Color(0xFF1B6C8C);
  static const Color primarySoft = Color(0xFFE7EFF3);

  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F7F8);
  static const Color border = Color(0xFFE2E7EA);

  static const Color textPrimary = Color(0xFF1B2A32);
  static const Color textSecondary = Color(0xFF5C6B73);
  static const Color textMuted = Color(0xFF8B989F);

  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFC0392B);

  static const Color darkBackground = Color(0xFF0D171C);
  static const Color darkSurface = Color(0xFF14232A);
  static const Color darkBorder = Color(0xFF25363F);
  static const Color darkTextPrimary = Color(0xFFEAF0F2);
  static const Color darkTextSecondary = Color(0xFFA9B7BE);

  /// Các màu nhấn cho phần "Màu theme" trong Cài đặt.
  static const List<Color> accentOptions = <Color>[
    primary,
    Color(0xFF2F5D8A),
    Color(0xFF2E7D5B),
    Color(0xFF6C4F86),
  ];

  static const List<String> accentNames = <String>[
    'Xanh Konexus',
    'Xanh biển',
    'Xanh lá',
    'Tím',
  ];

  static const List<String> accentKeys = <String>[
    'teal',
    'blue',
    'green',
    'purple'
  ];

  static Color accentFromKey(String? key) {
    final int index = accentKeys.indexOf(key ?? 'teal');
    return accentOptions[index < 0 ? 0 : index];
  }

  static int accentIndexFromKey(String? key) {
    final int index = accentKeys.indexOf(key ?? 'teal');
    return index < 0 ? 0 : index;
  }
}
