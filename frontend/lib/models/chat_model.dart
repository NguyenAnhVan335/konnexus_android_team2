/// Model cho module Tin nhắn.
///
/// Backend hiện chưa có endpoint chat (chỉ có dependency websocket trong pom.xml),
/// nên dữ liệu được cấp bởi `MockChatService`. Model được giữ tách khỏi UI để khi
/// backend bổ sung chỉ cần thay service.
class ChatThread {
  const ChatThread({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  final String id;
  final String participantId;
  final String participantName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String? avatarUrl;
  final int unreadCount;
  final bool isOnline;

  ChatThread copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isOnline,
  }) {
    return ChatThread(
      id: id,
      participantId: participantId,
      participantName: participantName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      avatarUrl: avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.text,
    required this.sentAt,
    required this.isMine,
  });

  final String id;
  final String threadId;
  final String text;
  final DateTime sentAt;
  final bool isMine;
}
