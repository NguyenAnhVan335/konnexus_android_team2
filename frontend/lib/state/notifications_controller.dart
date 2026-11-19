import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Trạng thái module Thông báo (dữ liệu từ `/api/v1/notifications`).
///
/// Đây là controller dùng chung (singleton trong `AppServices`) để badge trên
/// chuông app bar và màn hình Thông báo luôn đồng bộ trạng thái đã đọc.
class NotificationsController extends AppChangeNotifier {
  NotificationsController(this._service);

  final NotificationService _service;

  List<NotificationItem> _items = <NotificationItem>[];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  List<NotificationItem> get items => _items;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get unreadCount =>
      _items.where((NotificationItem item) => !item.isRead).length;

  /// Tải lần đầu nếu chưa có dữ liệu (gọi từ app bar/MainShell).
  Future<void> ensureLoaded() async {
    if (_hasLoaded || _isLoading) {
      return;
    }
    await load();
  }

  Future<void> load() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchNotifications();
      _hasLoaded = true;
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Làm mới im lặng (heartbeat) — không bật trạng thái loading.
  Future<void> refreshQuietly() async {
    if (_isLoading) {
      return;
    }
    try {
      _items = await _service.fetchNotifications();
      _hasLoaded = true;
      notifyListeners();
    } on ApiException {
      // Bỏ qua: badge chỉ là thông tin phụ, không nên làm phiền người dùng.
    }
  }

  /// Đánh dấu một thông báo đã đọc (bấm vào thông báo).
  Future<void> markAsRead(String notificationId) async {
    final int index = _items
        .indexWhere((NotificationItem item) => item.id == notificationId);
    if (index == -1 || _items[index].isRead) {
      return;
    }
    await _service.markAsRead(notificationId);
    _items = List<NotificationItem>.from(_items)
      ..[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    if (_items.every((NotificationItem item) => item.isRead)) {
      return;
    }
    await _service.markAllAsRead();
    _items = _items
        .map((NotificationItem item) => item.copyWith(isRead: true))
        .toList(growable: false);
    notifyListeners();
  }

  /// Xoá trạng thái khi đăng xuất để phiên sau không thấy dữ liệu cũ.
  void clear() {
    _items = <NotificationItem>[];
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }
}
