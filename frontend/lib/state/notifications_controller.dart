import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Trạng thái module Thông báo (dữ liệu hiện do [MockNotificationService] cung cấp).
class NotificationsController extends AppChangeNotifier {
  NotificationsController(this._service);

  final NotificationService _service;

  List<NotificationItem> _items = <NotificationItem>[];
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get items => _items;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get unreadCount =>
      _items.where((NotificationItem item) => !item.isRead).length;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchNotifications();
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _items = _items
        .map((NotificationItem item) => item.copyWith(isRead: true))
        .toList(growable: false);
    notifyListeners();
  }
}
