import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/interaction_model.dart';
import '../models/post_model.dart';
import '../services/interaction_service.dart';
import '../services/post_service.dart';
import 'session_controller.dart';

/// Chi tiết một bài viết: nội dung + cảm xúc + bình luận.
class PostDetailController extends AppChangeNotifier {
  PostDetailController({
    required this.postId,
    required PostService postService,
    required InteractionService interactionService,
    required SessionController session,
    PostModel? initialPost,
  })  : _postService = postService,
        _interactionService = interactionService,
        _session = session,
        _post = initialPost;

  final String postId;
  final PostService _postService;
  final InteractionService _interactionService;
  final SessionController _session;

  PostModel? _post;
  List<CommentModel> _comments = <CommentModel>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  PostModel? get post => _post;

  List<CommentModel> get comments => _comments;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get error => _error;

  bool get isOwner => _post?.author.id == _session.userId;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final PostModel detail = await _postService.fetchPost(postId);
      _post = detail;
      try {
        _comments = await _interactionService.fetchComments(postId);
      } on ApiException {
        _comments = <CommentModel>[];
      }
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String emojiType) async {
    final PostModel? current = _post;
    if (current == null) {
      return;
    }
    final bool liked = await _interactionService.toggleReaction(
      postId: current.id,
      type: emojiType,
    );
    final int delta = liked == current.liked ? 0 : (liked ? 1 : -1);
    final int likeCount = current.likeCount + delta;
    _post = current.withReaction(
      liked: liked,
      likeCount: likeCount < 0 ? 0 : likeCount,
      myReaction: liked ? emojiType : null,
    );
    notifyListeners();
  }

  Future<void> addComment(String content, {String? parentCommentId}) async {
    final String text = content.trim();
    if (text.isEmpty) {
      return;
    }
    _isSubmitting = true;
    notifyListeners();
    try {
      final CommentModel comment = await _interactionService.addComment(
        postId: postId,
        content: text,
        parentCommentId: parentCommentId,
      );
      _comments = <CommentModel>[
        ..._comments,
        CommentModel(
          id: comment.id,
          postId: postId,
          content: comment.content.isEmpty ? text : comment.content,
          parentId: comment.parentId ?? parentCommentId,
          image: comment.image,
          author: PostAuthor(
            id: _session.userId ?? '',
            username: _session.displayName,
            avatarUrl: _session.avatarUrl,
          ),
          createdAt: comment.createdAt ?? DateTime.now(),
        ),
      ];
      final PostModel? current = _post;
      if (current != null) {
        _post = current.copyWith(commentCount: current.commentCount + 1);
      }
    } on ApiException catch (error) {
      _error = error.userMessage;
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool isCommentOwner(CommentModel comment) =>
      comment.author?.id == _session.userId;

  Future<void> editComment(String commentId, String content) async {
    final String text = content.trim();
    if (text.isEmpty) {
      return;
    }
    final CommentModel updated = await _interactionService.editComment(
      commentId: commentId,
      content: text,
    );
    _comments = _comments
        .map((CommentModel c) =>
            c.id == commentId ? c.copyWith(content: updated.content) : c)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> deleteComment(String commentId) async {
    await _interactionService.deleteComment(commentId);
    _comments = _comments
        .where((CommentModel c) => c.id != commentId)
        .toList(growable: false);
    final PostModel? current = _post;
    if (current != null && current.commentCount > 0) {
      _post = current.copyWith(commentCount: current.commentCount - 1);
    }
    notifyListeners();
  }

  Future<void> toggleCommentReaction(CommentModel comment, String type) async {
    final bool active = await _interactionService.toggleCommentReaction(
      commentId: comment.id,
      type: type,
    );
    final bool hadReaction = comment.myReaction != null;
    final int delta = active ? (hadReaction ? 0 : 1) : -1;
    final int count = comment.reactionCount + delta;
    _comments = _comments
        .map((CommentModel c) => c.id == comment.id
            ? c.withReaction(
                count: count < 0 ? 0 : count,
                type: active ? type : null,
              )
            : c)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> deletePost() async {
    await _postService.deletePost(postId);
  }
}
