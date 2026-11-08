import '../utils/json_utils.dart';
import 'interaction_model.dart';

enum PostPrivacy {
  public('PUBLIC', 'Công khai'),
  friends('FRIENDS_ONLY', 'Bạn bè'),
  private('PRIVATE', 'Chỉ mình tôi');

  const PostPrivacy(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PostPrivacy fromApi(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'FRIENDS_ONLY':
        return PostPrivacy.friends;
      case 'PRIVATE':
        return PostPrivacy.private;
      default:
        return PostPrivacy.public;
    }
  }
}

enum MediaKind {
  image('IMAGE', 'Ảnh'),
  video('VIDEO', 'Video');

  const MediaKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MediaKind fromApi(String? raw) {
    return (raw ?? '').toUpperCase() == 'VIDEO'
        ? MediaKind.video
        : MediaKind.image;
  }
}

/// Tác giả bài viết (`author` trong PostResponse).
class PostAuthor {
  const PostAuthor({required this.id, this.username, this.avatarUrl});

  final String id;
  final String? username;
  final String? avatarUrl;

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: asString(json['id']) ?? '',
      username: asString(json['username']),
      avatarUrl: asString(json['avatar_url']) ?? asString(json['avatarUrl']),
    );
  }

  String get displayName {
    final String value = (username ?? '').trim();
    return value.isEmpty ? 'Người dùng' : value;
  }
}

class PostMedia {
  const PostMedia({
    this.id,
    required this.url,
    required this.kind,
    this.displayOrder = 0,
  });

  final String? id;
  final String url;
  final MediaKind kind;
  final int displayOrder;

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: asString(json['id']),
      url: asString(json['media_url']) ?? asString(json['mediaUrl']) ?? '',
      kind: MediaKind.fromApi(
          asString(json['media_type']) ?? asString(json['mediaType'])),
      displayOrder: asInt(json['display_order']),
    );
  }

  /// Payload gửi kèm `media_list` khi tạo/sửa bài viết.
  Map<String, dynamic> toRequestJson(int index) {
    return <String, dynamic>{
      'media_url': url,
      'media_type': kind.apiValue,
      'display_order': index,
    };
  }
}

class PostModel {
  const PostModel({
    required this.id,
    required this.author,
    required this.content,
    required this.privacy,
    required this.likeCount,
    required this.commentCount,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
    required this.edited,
    required this.liked,
    this.myReaction,
    this.reactions,
    this.comments,
  });

  final String id;
  final PostAuthor author;
  final String? content;
  final PostPrivacy privacy;
  final int likeCount;
  final int commentCount;
  final List<PostMedia> media;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool edited;
  final bool liked;

  /// Loại cảm xúc của người dùng hiện tại (LIKE/LOVE/HAHA/...). null nếu chưa thả.
  final String? myReaction;

  /// Chỉ có ở `GET /api/v1/posts/{id}`.
  final ReactionSummary? reactions;
  final List<CommentModel>? comments;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final List<PostMedia> mediaItems = asList(json['media_list'])
        .whereType<Map>()
        .map((dynamic item) => PostMedia.fromJson(asMap(item)))
        .toList(growable: false);
    final dynamic reactionsJson = json['reactions'];
    final dynamic commentsJson = json['comments'];
    final ReactionSummary? reactions = reactionsJson is Map
        ? ReactionSummary.fromJson(asMap(reactionsJson))
        : null;
    final bool liked = asBool(json['is_liked'],
        fallback: asBool(json['_liked'], fallback: asBool(json['liked'])));
    final String? myReaction = asString(json['my_reaction']) ??
        reactions?.myReaction ??
        (liked ? 'LIKE' : null);
    return PostModel(
      id: asString(json['id']) ?? '',
      author: PostAuthor.fromJson(asMap(json['author'])),
      content: asString(json['content']),
      privacy: PostPrivacy.fromApi(asString(json['privacy'])),
      likeCount: asInt(json['like_count']),
      commentCount: asInt(json['comment_count']),
      media: mediaItems,
      createdAt: parseApiDate(json['created_at']),
      updatedAt: parseApiDate(json['updated_at']),
      edited: asBool(json['is_edited'], fallback: asBool(json['edited'])),
      liked: liked,
      myReaction: myReaction,
      reactions: reactions,
      comments: commentsJson is List
          ? asList(commentsJson)
              .whereType<Map>()
              .map((dynamic item) => CommentModel.fromJson(asMap(item)))
              .toList(growable: false)
          : null,
    );
  }

  bool get hasText => (content ?? '').trim().isNotEmpty;

  PostModel copyWith({
    String? content,
    PostPrivacy? privacy,
    int? likeCount,
    int? commentCount,
    List<PostMedia>? media,
    bool? edited,
    bool? liked,
    ReactionSummary? reactions,
    List<CommentModel>? comments,
  }) {
    return PostModel(
      id: id,
      author: author,
      content: content ?? this.content,
      privacy: privacy ?? this.privacy,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      media: media ?? this.media,
      createdAt: createdAt,
      updatedAt: updatedAt,
      edited: edited ?? this.edited,
      liked: liked ?? this.liked,
      myReaction: myReaction,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
    );
  }

  /// Cập nhật trạng thái cảm xúc của người dùng hiện tại sau khi thả/gỡ.
  PostModel withReaction({
    required bool liked,
    required int likeCount,
    String? myReaction,
  }) {
    return PostModel(
      id: id,
      author: author,
      content: content,
      privacy: privacy,
      likeCount: likeCount,
      commentCount: commentCount,
      media: media,
      createdAt: createdAt,
      updatedAt: updatedAt,
      edited: edited,
      liked: liked,
      myReaction: myReaction,
      reactions: reactions,
      comments: comments,
    );
  }
}
