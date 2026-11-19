import '../core/api/api_client.dart';
import '../models/admin_model.dart';
import '../models/page_data.dart';
import '../utils/json_utils.dart';

/// Gọi các endpoint quản trị `/api/admin/*` (yêu cầu JWT có role ADMIN).
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<AdminDashboard> getDashboard() async {
    final dynamic response = await _api.get('/api/admin/dashboard');
    return AdminDashboard.fromJson(asMap(ApiClient.unwrap(response)));
  }

  /// Bật/tắt trợ lý Charles.
  Future<void> toggleBot(bool enabled) async {
    await _api.post(
      '/api/admin/bot/toggle',
      body: <String, dynamic>{'enabled': enabled},
    );
  }

  /// Danh sách người dùng. Backend hiện trả toàn bộ danh sách nên `keyword`,
  /// `page`, `size` được áp dụng phía client để khớp hợp đồng phân trang.
  Future<PageData<AdminUser>> getUsers({
    int page = 0,
    int size = 10,
    String keyword = '',
  }) async {
    final dynamic response = await _api.get('/api/admin/users/list');
    final List<AdminUser> all = asList(ApiClient.unwrap(response))
        .whereType<Map>()
        .map((dynamic item) => AdminUser.fromJson(asMap(item)))
        .where((AdminUser user) => user.id.isNotEmpty)
        .toList(growable: false);

    final String query = keyword.trim().toLowerCase();
    final List<AdminUser> filtered = query.isEmpty
        ? all
        : all.where((AdminUser user) {
            final String username = user.username.toLowerCase();
            final String email = (user.email ?? '').toLowerCase();
            return username.contains(query) || email.contains(query);
          }).toList(growable: false);

    filtered.sort((AdminUser a, AdminUser b) =>
        a.username.toLowerCase().compareTo(b.username.toLowerCase()));

    return _paginate<AdminUser>(filtered, page, size);
  }

  /// Danh sách phòng chat (phân trang phía client như [getUsers]).
  Future<PageData<AdminRoom>> getRooms({int page = 0, int size = 10}) async {
    final dynamic response = await _api.get('/api/admin/rooms/list');
    final List<AdminRoom> all = asList(ApiClient.unwrap(response))
        .whereType<Map>()
        .map((dynamic item) => AdminRoom.fromJson(asMap(item)))
        .where((AdminRoom room) => room.id.isNotEmpty)
        .toList(growable: false);

    all.sort((AdminRoom a, AdminRoom b) {
      final DateTime? at = a.createdAt;
      final DateTime? bt = b.createdAt;
      if (at == null && bt == null) {
        return 0;
      }
      if (at == null) {
        return 1;
      }
      if (bt == null) {
        return -1;
      }
      return bt.compareTo(at);
    });

    return _paginate<AdminRoom>(all, page, size);
  }

  PageData<T> _paginate<T>(List<T> items, int page, int size) {
    final int safePage = page < 0 ? 0 : page;
    final int safeSize = size <= 0 ? items.length : size;
    final int total = items.length;
    final int totalPages = total == 0 ? 0 : (total / safeSize).ceil();
    final int start = safePage * safeSize;
    final int end = (start + safeSize) > total ? total : start + safeSize;
    final List<T> content = start >= total
        ? <T>[]
        : items.sublist(start, end).toList(growable: false);
    return PageData<T>(
      content: content,
      page: safePage,
      size: safeSize,
      totalElements: total,
      totalPages: totalPages,
    );
  }
}
