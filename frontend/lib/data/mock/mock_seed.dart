import '../../models/chat_model.dart';
import '../../models/notification_model.dart';

/// Dữ liệu mẫu cho các module **backend chưa có API**: Tin nhắn và Thông báo.
///
/// Dữ liệu mẫu nằm ở tầng service (xem `MockChatService`, `MockNotificationService`),
/// không nằm trong widget, để khi backend bổ sung chỉ cần thay implementation.
class MockSeed {
  const MockSeed._();

  static List<ChatThread> chatThreads() {
    final DateTime now = DateTime.now();
    return <ChatThread>[
      ChatThread(
        id: 'mock-thread-1',
        participantId: 'mock-user-1',
        participantName: 'Minh Anh',
        lastMessage: 'Cuối tuần này đi cà phê không?',
        lastMessageAt: now.subtract(const Duration(minutes: 12)),
        unreadCount: 2,
        isOnline: true,
      ),
      ChatThread(
        id: 'mock-thread-2',
        participantId: 'mock-user-2',
        participantName: 'Quốc Bảo',
        lastMessage: 'Mình vừa gửi bài tập nhóm nhé.',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        isOnline: true,
      ),
      ChatThread(
        id: 'mock-thread-3',
        participantId: 'mock-user-3',
        participantName: 'Nhóm Mobile 07',
        lastMessage: 'Bạn: Đã cập nhật giao diện trang chủ.',
        lastMessageAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Map<String, List<ChatMessage>> messagesByThread() {
    final DateTime now = DateTime.now();
    return <String, List<ChatMessage>>{
      'mock-thread-1': <ChatMessage>[
        ChatMessage(
          id: 'mock-msg-1',
          threadId: 'mock-thread-1',
          text: 'Chào bạn, bài viết về Konexus trông ổn rồi đó!',
          sentAt: now.subtract(const Duration(minutes: 40)),
          isMine: false,
        ),
        ChatMessage(
          id: 'mock-msg-2',
          threadId: 'mock-thread-1',
          text: 'Cảm ơn bạn, mình vừa thêm phần cảm xúc và bình luận.',
          sentAt: now.subtract(const Duration(minutes: 32)),
          isMine: true,
        ),
        ChatMessage(
          id: 'mock-msg-3',
          threadId: 'mock-thread-1',
          text: 'Cuối tuần này đi cà phê không?',
          sentAt: now.subtract(const Duration(minutes: 12)),
          isMine: false,
        ),
      ],
      'mock-thread-2': <ChatMessage>[
        ChatMessage(
          id: 'mock-msg-4',
          threadId: 'mock-thread-2',
          text: 'Mình vừa gửi bài tập nhóm nhé.',
          sentAt: now.subtract(const Duration(hours: 2)),
          isMine: false,
        ),
      ],
      'mock-thread-3': <ChatMessage>[
        ChatMessage(
          id: 'mock-msg-5',
          threadId: 'mock-thread-3',
          text: 'Đã cập nhật giao diện trang chủ.',
          sentAt: now.subtract(const Duration(days: 1)),
          isMine: true,
        ),
      ],
    };
  }

  static List<NotificationItem> notifications() {
    final DateTime now = DateTime.now();
    return <NotificationItem>[
      NotificationItem(
        id: 'mock-noti-1',
        title: 'Lời mời kết bạn',
        body: 'Minh Anh đã gửi cho bạn một lời mời kết bạn.',
        createdAt: now.subtract(const Duration(minutes: 8)),
        kind: NotificationKind.friendRequest,
      ),
      NotificationItem(
        id: 'mock-noti-2',
        title: 'Cảm xúc mới',
        body: 'Quốc Bảo đã bày tỏ cảm xúc về bài viết của bạn.',
        createdAt: now.subtract(const Duration(hours: 1)),
        kind: NotificationKind.like,
        isRead: true,
      ),
      NotificationItem(
        id: 'mock-noti-3',
        title: 'Bình luận mới',
        body:
            'Nhóm Mobile 07 vừa bình luận về bài viết "Konexus phiên bản mới".',
        createdAt: now.subtract(const Duration(hours: 5)),
        kind: NotificationKind.comment,
      ),
      NotificationItem(
        id: 'mock-noti-4',
        title: 'Chào mừng đến Konexus',
        body: 'Hãy hoàn thiện hồ sơ và kết nối với bạn bè của bạn.',
        createdAt: now.subtract(const Duration(days: 2)),
        kind: NotificationKind.system,
        isRead: true,
      ),
    ];
  }
}
