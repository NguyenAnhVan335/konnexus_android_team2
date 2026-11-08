import '../core/api/api_client.dart';
import '../models/interaction_model.dart';
import '../utils/json_utils.dart';

/// Cảm xúc và bình luận (`/api/v1/posts/...`) của backend.
class InteractionService {
  InteractionService(this._api);

  final ApiClient _api;

  /// Thả/đổi/gỡ cảm xúc bài viết. Trả về `true` nếu đang giữ cảm xúc, `false` nếu đã gỡ.
  Future<bool> toggleReaction({
    required String postId,
    required String type,
  }) async {
    final dynamic response = await _api.post(
      '/api/v1/posts/$postId/reactions',
      body: <String, dynamic>{'type': type},
    );
    return asBool(ApiClient.unwrap(response));
  }

  Future<CommentModel> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    final dynamic response = await _api.post(
      '/api/v1/posts/$postId/comments',
      body: <String, dynamic>{
        'content': content.trim(),
        if (parentCommentId != null && parentCommentId.isNotEmpty)
          'parentId': parentCommentId,
      },
    );
    return CommentModel.fromJson(asMap(ApiClient.unwrap(response)));
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    final dynamic response = await _api.get('/api/v1/posts/$postId/comments');
    final Map<String, dynamic> page = asMap(ApiClient.unwrap(response));
    return asList(page['items'])
        .whereType<Map>()
        .map((dynamic item) => CommentModel.fromJson(asMap(item)))
        .toList(growable: false);
  }

  /// Chỉnh sửa nội dung bình luận (chỉ tác giả bình luận).
  Future<CommentModel> editComment({
    required String commentId,
    required String content,
  }) async {
    final dynamic response = await _api.put(
      '/api/v1/posts/comments/$commentId',
      body: <String, dynamic>{'content': content.trim()},
    );
    return CommentModel.fromJson(asMap(ApiClient.unwrap(response)));
  }

  /// Xóa mềm bình luận (tác giả bình luận hoặc chủ bài viết).
  Future<void> deleteComment(String commentId) async {
    await _api.delete('/api/v1/posts/comments/$commentId');
  }

  /// Thả/đổi/gỡ cảm xúc bình luận. Trả về `true` nếu đang giữ cảm xúc.
  Future<bool> toggleCommentReaction({
    required String commentId,
    required String type,
  }) async {
    final dynamic response = await _api.post(
      '/api/v1/posts/comments/$commentId/reactions',
      body: <String, dynamic>{'type': type},
    );
    return asBool(ApiClient.unwrap(response));
  }
}
