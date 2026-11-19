import '../core/api/api_client.dart';
import '../models/activity_model.dart';
import '../utils/json_utils.dart';

/// Gọi `GET /api/activities` — lịch sử hoạt động của chính người dùng đang
/// đăng nhập (backend lấy danh tính từ JWT, mặc định 7 ngày gần nhất).
class ActivityService {
  ActivityService(this._api);

  final ApiClient _api;

  /// Bỏ trống [from]/[to] để backend tự dùng khoảng 7 ngày gần nhất.
  Future<List<ActivityItem>> fetchActivities({
    DateTime? from,
    DateTime? to,
  }) async {
    final Map<String, String> query = <String, String>{
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };
    final dynamic response = await _api.get(
      '/api/activities',
      query: query.isEmpty ? null : query,
    );
    return asList(ApiClient.unwrap(response))
        .whereType<Map>()
        .map((dynamic item) => ActivityItem.fromApi(asMap(item)))
        .toList(growable: false);
  }
}
