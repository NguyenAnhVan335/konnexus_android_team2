import 'package:flutter/material.dart';

/// Logo Konnexus dùng chung cho splash, màn hình đăng nhập và các nơi hiển thị
/// thương hiệu trong app.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  /// Kích thước cạnh (logo là ảnh vuông).
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logoKonnexus.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
