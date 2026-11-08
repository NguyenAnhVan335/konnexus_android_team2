import '../core/api/api_client.dart';
import '../models/user_model.dart';
import '../utils/json_utils.dart';

/// Gọi các endpoint người dùng đã có trong backend:
/// - `GET /api/users` (yêu cầu Bearer token) trả về mảng entity `User`.
/// - `PUT /api/users/{id}` cập nhật hồ sơ của chính mình.
///
/// Backend chưa có `GET /api/users/me` nên hồ sơ hiện tại được lấy từ danh sách
/// người dùng theo id trong token.
class UserService {
  UserService(this._api);

  final ApiClient _api;

  Future<List<UserModel>> fetchUsers() async {
    final dynamic response = await _api.get('/api/users');
    return asList(response)
        .whereType<Map>()
        .map((dynamic item) => UserModel.fromJson(asMap(item)))
        .where((UserModel user) => user.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<UserModel?> findById(String userId) async {
    final List<UserModel> users = await fetchUsers();
    for (final UserModel user in users) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }

  /// [password] là bắt buộc: `UserService.updateUser` của backend gán mật khẩu
  /// trực tiếp từ payload, nếu bỏ trống sẽ ghi đè mật khẩu hiện tại.
  Future<void> updateProfile({
    required String userId,
    required String username,
    required String email,
    required String password,
    String? avatarUrl,
  }) async {
    await _api.put(
      '/api/users/$userId',
      body: <String, dynamic>{
        'username': username.trim(),
        'email': email.trim(),
        'avatar_url': avatarUrl,
        'password': password,
      },
    );
  }

  /// Cập nhật trạng thái online/offline của người dùng hiện tại.
  Future<void> updateStatus(bool online) async {
    await _api.put('/api/users/status?online=$online');
  }
}
