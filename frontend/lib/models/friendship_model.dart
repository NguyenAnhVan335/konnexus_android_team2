import '../utils/json_utils.dart';

/// Trạng thái quan hệ do `GET /api/friends/status/{otherUserId}` trả về.
enum RelationshipStatus {
  friends('FRIENDS', 'Bạn bè'),
  requestSent('REQUEST_SENT', 'Đã gửi lời mời'),
  requestReceived('REQUEST_RECEIVED', 'Đã nhận lời mời'),
  none('NONE', 'Thêm bạn');

  const RelationshipStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static RelationshipStatus fromApi(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'FRIENDS':
        return RelationshipStatus.friends;
      case 'REQUEST_SENT':
        return RelationshipStatus.requestSent;
      case 'REQUEST_RECEIVED':
        return RelationshipStatus.requestReceived;
      default:
        return RelationshipStatus.none;
    }
  }
}

/// Một dòng trong bảng `friendships` (`FriendshipDto` của backend).
class FriendshipModel {
  const FriendshipModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.statusLabel,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final String? statusLabel;

  bool get isPending => status.toUpperCase() == 'PENDING';

  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';

  String otherUserId(String currentUserId) {
    return senderId == currentUserId ? receiverId : senderId;
  }

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> sender = asMap(json['sender']);
    final Map<String, dynamic> receiver = asMap(json['receiver']);
    return FriendshipModel(
      id: asString(json['id']) ?? '',
      senderId: asString(sender['id']) ??
          asString(json['senderId']) ??
          asString(json['sender_id']) ??
          '',
      receiverId: asString(receiver['id']) ??
          asString(json['receiverId']) ??
          asString(json['receiver_id']) ??
          '',
      status: asString(json['status']) ?? 'PENDING',
      statusLabel:
          asString(json['statusLabel']) ?? asString(json['status_label']),
    );
  }
}

/// `FriendshipStatusDto` của backend.
class RelationshipModel {
  const RelationshipModel({
    required this.userId,
    required this.status,
    this.friendshipId,
    this.message,
  });

  final String userId;
  final RelationshipStatus status;
  final String? friendshipId;
  final String? message;

  factory RelationshipModel.fromJson(Map<String, dynamic> json) {
    return RelationshipModel(
      userId: asString(json['userId']) ?? asString(json['user_id']) ?? '',
      status: RelationshipStatus.fromApi(asString(json['status'])),
      friendshipId:
          asString(json['friendshipId']) ?? asString(json['friendship_id']),
      message: asString(json['message']),
    );
  }

  static RelationshipModel unknown(String userId) {
    return RelationshipModel(userId: userId, status: RelationshipStatus.none);
  }
}
