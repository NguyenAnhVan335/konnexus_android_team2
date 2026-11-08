import 'package:flutter/widgets.dart';

/// Truy cập `Navigator` gốc từ tầng không có `BuildContext`.
///
/// Dùng khi phiên đăng nhập hết hạn (HTTP 401): cần đóng toàn bộ màn hình đang
/// mở để lộ màn hình đăng nhập, kể cả khi người dùng đang ở màn hình con.
class AppNavigator {
  const AppNavigator._();

  /// Gắn vào `MaterialApp.navigatorKey`.
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Đóng mọi route đang mở, trở về route gốc (`AppGate`).
  static void popToRoot() {
    final NavigatorState? navigator = key.currentState;
    if (navigator == null) {
      return;
    }
    navigator.popUntil((Route<dynamic> route) => route.isFirst);
  }
}
