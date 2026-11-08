import '../config/api_config.dart';
import '../core/api/api_client.dart';
import '../models/page_data.dart';
import '../models/post_model.dart';
import '../utils/json_utils.dart';

/// Gọi Post API đã hoàn thiện trong backend (`/api/v1/posts`).
///
/// Header xác thực (`X-User-Id`) do [ApiClient] tự gắn từ phiên đăng nhập.
class PostService {
  PostService(this._api);

  final ApiClient _api;

  Future<PageData<PostModel>> fetchFeed({
    int page = 0,
    int size = ApiConfig.pageSize,
  }) async {
    final dynamic response = await _api.get(
      '/api/v1/posts/feed',
      query: <String, String>{'page': '$page', 'size': '$size'},
    );
    return PageData<PostModel>.fromJson(
        ApiClient.unwrap(response), PostModel.fromJson);
  }

  Future<PageData<PostModel>> fetchTrending({
    int page = 0,
    int size = ApiConfig.pageSize,
    int days = 7,
  }) async {
    final dynamic response = await _api.get(
      '/api/v1/posts/trending',
      query: <String, String>{
        'page': '$page',
        'size': '$size',
        'days': '$days',
      },
    );
    return PageData<PostModel>.fromJson(
        ApiClient.unwrap(response), PostModel.fromJson);
  }

  Future<PageData<PostModel>> fetchUserPosts(
    String userId, {
    int page = 0,
    int size = ApiConfig.pageSize,
  }) async {
    final dynamic response = await _api.get(
      '/api/v1/posts/user/$userId',
      query: <String, String>{'page': '$page', 'size': '$size'},
    );
    return PageData<PostModel>.fromJson(
        ApiClient.unwrap(response), PostModel.fromJson);
  }

  /// Tìm kiếm bài viết theo từ khóa (`GET /api/v1/posts/search`).
  Future<PageData<PostModel>> searchPosts(
    String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    final dynamic response = await _api.get(
      '/api/v1/posts/search',
      query: <String, String>{
        'keyword': keyword,
        'page': '$page',
        'size': '$size',
      },
    );
    return PageData<PostModel>.fromJson(
        ApiClient.unwrap(response), PostModel.fromJson);
  }

  Future<PostModel> fetchPost(String id) async {
    final dynamic response = await _api.get('/api/v1/posts/$id');
    return PostModel.fromJson(asMap(ApiClient.unwrap(response)));
  }

  Future<PostModel> createPost({
    String? content,
    required PostPrivacy privacy,
    List<PostMedia> media = const <PostMedia>[],
  }) async {
    final dynamic response = await _api.post(
      '/api/v1/posts',
      body: <String, dynamic>{
        'content': _trimToNull(content),
        'privacy': privacy.apiValue,
        'media_list': _mediaPayload(media),
      },
    );
    return PostModel.fromJson(asMap(ApiClient.unwrap(response)));
  }

  Future<PostModel> updatePost(
    String id, {
    String? content,
    required PostPrivacy privacy,
    required List<PostMedia> media,
  }) async {
    final dynamic response = await _api.put(
      '/api/v1/posts/$id',
      body: <String, dynamic>{
        'content': _trimToNull(content),
        'privacy': privacy.apiValue,
        'media_list': _mediaPayload(media),
      },
    );
    return PostModel.fromJson(asMap(ApiClient.unwrap(response)));
  }

  /// Xoá mềm theo contract hiện tại: `DELETE /api/v1/posts/{id}`.
  Future<void> deletePost(String id) async {
    await _api.delete('/api/v1/posts/$id');
  }

  List<Map<String, dynamic>> _mediaPayload(List<PostMedia> media) {
    final List<Map<String, dynamic>> payload = <Map<String, dynamic>>[];
    for (int index = 0; index < media.length; index++) {
      payload.add(media[index].toRequestJson(index));
    }
    return payload;
  }

  String? _trimToNull(String? value) {
    final String text = (value ?? '').trim();
    return text.isEmpty ? null : text;
  }
}
