import '../utils/json_utils.dart';
import 'post_model.dart';

/// Tóm tắt cảm xúc của một bài viết (`reactions` trong PostDetailResponse).
class ReactionSummary {
  const ReactionSummary({
    required this.total,
    required this.byType,
    this.myReaction,
  });

  final int total;
  final Map<String, int> byType;
  final String? myReaction;

  factory ReactionSummary.fromJson(Map<String, dynamic> json) {
    final Map<String, int> counts = <String, int>{};
    asMap(json['by_type']).forEach((String key, dynamic value) {
      counts[key] = asInt(value);
    });
    return ReactionSummary(
      total: asInt(json['total']),
      byType: counts,
      myReaction: asString(json['my_reaction']),
    );
  }

  static const ReactionSummary empty = ReactionSummary(
    total: 0,
    byType: <String, int>{},
  );
}

/// Bình luận: dùng chung cho `comments` của PostDetailResponse và
/// `GET /api/comments/post/{postId}` (entity PostComment).
///
/// `author` có thể null với bình luận cũ chưa có tác giả.
class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.content,
    this.parentId,
    this.image,
    this.author,
    this.createdAt,
    this.reactionCount = 0,
    this.myReaction,
  });

  final String id;
  final String postId;
  final String content;
  final String? parentId;
  final String? image;
  final PostAuthor? author;
  final DateTime? createdAt;
  final int reactionCount;
  final String? myReaction;

  bool get isReply => parentId != null && parentId!.isNotEmpty;

  CommentModel copyWith({String? content}) {
    return CommentModel(
      id: id,
      postId: postId,
      content: content ?? this.content,
      parentId: parentId,
      image: image,
      author: author,
      createdAt: createdAt,
      reactionCount: reactionCount,
      myReaction: myReaction,
    );
  }

  CommentModel withReaction({required int count, String? type}) {
    return CommentModel(
      id: id,
      postId: postId,
      content: content,
      parentId: parentId,
      image: image,
      author: author,
      createdAt: createdAt,
      reactionCount: count,
      myReaction: type,
    );
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final String authorId =
        asString(json['authorId']) ?? asString(json['author_id']) ?? '';
    final String authorName =
        asString(json['authorUsername']) ?? asString(json['author_name']) ?? '';
    final String authorAvatar = asString(json['authorAvatarUrl']) ??
        asString(json['author_avatar_url']) ??
        '';
    return CommentModel(
      id: asString(json['id']) ?? '',
      postId: asString(json['postId']) ?? asString(json['post_id']) ?? '',
      content: asString(json['content']) ?? '',
      parentId: asString(json['parentId']) ??
          asString(json['parent_id']) ??
          asString(json['cmt_id']),
      image: asString(json['image']),
      author: authorId.isNotEmpty
          ? PostAuthor(
              id: authorId,
              username: authorName,
              avatarUrl: authorAvatar,
            )
          : null,
      createdAt:
          parseApiDate(json['createdAt']) ?? parseApiDate(json['created_at']),
      reactionCount: asInt(json['reactionCount'] ?? json['reaction_count']),
      myReaction: asString(json['myReaction']) ?? asString(json['my_reaction']),
    );
  }
}
