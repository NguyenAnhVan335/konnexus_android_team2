import 'package:flutter/foundation.dart';

/// Lớp cơ sở cho mọi controller của ứng dụng.
///
/// Lý do tồn tại: khi backend trả `401`, ứng dụng đăng xuất và đóng các màn
/// hình đang mở, nhưng request đã gửi trước đó vẫn có thể hoàn tất muộn. Khi
/// đó controller của màn hình đã bị `dispose` sẽ nhận kết quả và gọi
/// `notifyListeners()`, làm Flutter ném lỗi
/// "A ... was used after being disposed".
///
/// Ghi đè [notifyListeners] để bỏ qua an toàn sau khi đã [dispose].
abstract class AppChangeNotifier extends ChangeNotifier {
  bool _isDisposed = false;

  /// `true` sau khi [dispose] đã được gọi.
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
