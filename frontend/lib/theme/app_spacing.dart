import 'package:flutter/material.dart';

/// Khoảng cách, bo góc dùng chung để giao diện nhất quán giữa các màn hình.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(14));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(10));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
}
