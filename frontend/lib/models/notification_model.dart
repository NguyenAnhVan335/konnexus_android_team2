import '../utils/json_utils.dart';

/// Model cho module Thông báo.
enum NotificationKind { like, comment, friendRequest, system }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
    this.isRead = false,
    this.postId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationKind kind;
  final bool isRead;
  final String? postId;

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      kind: kind,
      isRead: isRead ?? this.isRead,
      postId: postId,
    );
  }

  /// Ánh xạ từ entity `Notification` của backend (`/api/v1/notifications`).
  factory NotificationItem.fromApi(Map<String, dynamic> json) {
    final String type = (asString(json['type']) ?? '').toUpperCase();
    return NotificationItem(
      id: asString(json['id']) ?? '',
      title: _titleFor(type),
      body: _bodyFor(type),
      createdAt: parseApiDate(json['created_at']) ?? DateTime.now(),
      kind: _kindFor(type),
      isRead: asBool(json['is_read'], fallback: asBool(json['read'])),
      postId: asString(json['post_id']),
    );
  }

  static NotificationKind _kindFor(String type) {
    switch (type) {
      case 'LIKE_POST':
        return NotificationKind.like;
      case 'COMMENT_POST':
      case 'REPLY_POST':
        return NotificationKind.comment;
      case 'FRIEND_REQUEST':
        return NotificationKind.friendRequest;
      default:
        return NotificationKind.system;
    }
  }

  static String _titleFor(String type) {
    switch (type) {
      case 'LIKE_POST':
        return 'Bài viết của bạn được yêu thích';
      case 'COMMENT_POST':
        return 'Bình luận mới';
      case 'REPLY_POST':
        return 'Phản hồi bình luận';
      case 'FRIEND_REQUEST':
        return 'Lời mời kết bạn';
      default:
        return 'Thông báo';
    }
  }

  static String _bodyFor(String type) {
    switch (type) {
      case 'LIKE_POST':
        return 'Có người vừa bày tỏ cảm xúc với bài viết của bạn.';
      case 'COMMENT_POST':
        return 'Có người vừa bình luận vào bài viết của bạn.';
      case 'REPLY_POST':
        return 'Có người vừa trả lời bình luận của bạn.';
      case 'FRIEND_REQUEST':
        return 'Có người vừa gửi lời mời kết bạn cho bạn.';
      default:
        return 'Bạn có một thông báo mới.';
    }
  }
}

