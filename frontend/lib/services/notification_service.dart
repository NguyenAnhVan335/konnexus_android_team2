import '../core/api/api_client.dart';
import '../data/mock/mock_seed.dart';
import '../models/notification_model.dart';
import '../utils/json_utils.dart';

/// Hợp đồng của module Thông báo.
abstract class NotificationService {
  Future<List<NotificationItem>> fetchNotifications();

  Future<void> markAllAsRead();
}

/// Implementation thật gọi `/api/v1/notifications` của backend.
class ApiNotificationService implements NotificationService {
  ApiNotificationService(this._api);

  final ApiClient _api;

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final dynamic response = await _api.get('/api/v1/notifications');
    final Map<String, dynamic> page = asMap(ApiClient.unwrap(response));
    return asList(page['items'] ?? page['content'])
        .whereType<Map>()
        .map((dynamic item) => NotificationItem.fromApi(asMap(item)))
        .toList(growable: false);
  }

  @override
  Future<void> markAllAsRead() async {
    final List<NotificationItem> items = await fetchNotifications();
    for (final NotificationItem item in items) {
      if (item.isRead) {
        continue;
      }
      await _api.put(
        '/api/v1/notifications',
        body: <String, dynamic>{'notificationId': item.id, 'isRead': true},
      );
    }
  }
}

class MockNotificationService implements NotificationService {
  MockNotificationService() : _items = MockSeed.notifications();

  final List<NotificationItem> _items;

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final List<NotificationItem> items = List<NotificationItem>.from(_items);
    items.sort((NotificationItem a, NotificationItem b) =>
        b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<void> markAllAsRead() async {
    for (int index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
  }
}
