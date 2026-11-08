import '../core/api/api_client.dart';
import '../models/friendship_model.dart';
import '../utils/json_utils.dart';

/// Gọi Friendship API đã có trong backend (`/api/friends`).
///
/// Backend nhận danh tính qua header `X-Test-User-Id` và **chỉ cho phép khi
/// chạy dev/test** (LaunchMode khác NORMAL). [ApiClient] đã tự gắn header này
/// cùng `X-User-Id`; khi backend chạy production các endpoint sẽ trả 403.
class FriendshipService {
  FriendshipService(this._api);

  final ApiClient _api;

  Future<List<FriendshipModel>> fetchFriends() {
    return _fetchList('/api/friends');
  }

  Future<List<FriendshipModel>> fetchReceivedRequests() {
    return _fetchList('/api/friends/requests/received');
  }

  Future<List<FriendshipModel>> fetchSentRequests() {
    return _fetchList('/api/friends/requests/sent');
  }

  Future<FriendshipModel> sendRequest(String receiverId) async {
    final dynamic response = await _api.post(
      '/api/friends/requests',
      body: <String, dynamic>{'receiverId': receiverId},
    );
    return FriendshipModel.fromJson(asMap(ApiClient.unwrap(response)));
  }

  Future<void> acceptRequest(String requestId) async {
    await _api.put('/api/friends/requests/$requestId/accept');
  }

  Future<void> rejectRequest(String requestId) async {
    await _api.put('/api/friends/requests/$requestId/reject');
  }

  Future<void> cancelRequest(String requestId) async {
    await _api.delete('/api/friends/requests/$requestId/cancel');
  }

  Future<void> unfriend(String friendId) async {
    await _api.delete('/api/friends/$friendId');
  }

  Future<RelationshipModel> fetchStatus(String otherUserId) async {
    final dynamic response = await _api.get('/api/friends/status/$otherUserId');
    return RelationshipModel.fromJson(asMap(ApiClient.unwrap(response)));
  }

  Future<List<FriendshipModel>> _fetchList(String path) async {
    final dynamic response = await _api.get(path);
    return asList(ApiClient.unwrap(response))
        .whereType<Map>()
        .map((dynamic item) => FriendshipModel.fromJson(asMap(item)))
        .toList(growable: false);
  }
}
