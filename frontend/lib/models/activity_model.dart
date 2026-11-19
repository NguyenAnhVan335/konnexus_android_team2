import '../utils/json_utils.dart';

/// Loại hoạt động — tương ứng enum `ActivityType` của backend.
enum ActivityKind { reaction, comment, post, friendRequest, unknown }

/// Một dòng trong "Lịch sử hoạt động" (`GET /api/activities`).
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.actionType,
    required this.preview,
    required this.createdAt,
    this.targetId,
  });

  final String id;
  final ActivityKind kind;
  final String actionType;
  final String preview;
  final DateTime createdAt;
  final String? targetId;

  /// Đọc cả snake_case (backend) và camelCase để không vỡ khi DTO đổi tên.
  factory ActivityItem.fromApi(Map<String, dynamic> json) {
    final String actionType =
        (asString(json['action_type']) ?? asString(json['actionType']) ?? '')
            .toUpperCase();
    return ActivityItem(
      id: asString(json['id']) ?? '',
      kind: _kindFor(actionType),
      actionType: actionType,
      preview: asString(json['target_preview']) ??
          asString(json['targetPreview']) ??
          '',
      createdAt:
          parseApiDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      targetId: asString(json['target_id'] ?? json['targetId']),
    );
  }

  static ActivityKind _kindFor(String actionType) {
    switch (actionType) {
      case 'REACTION':
        return ActivityKind.reaction;
      case 'COMMENT':
        return ActivityKind.comment;
      case 'POST':
        return ActivityKind.post;
      case 'FRIEND_REQUEST':
        return ActivityKind.friendRequest;
      default:
        return ActivityKind.unknown;
    }
  }
}
