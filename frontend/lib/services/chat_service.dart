import '../core/api/api_client.dart';
import '../data/mock/mock_seed.dart';
import '../models/chat_model.dart';
import '../state/session_controller.dart';
import '../utils/json_utils.dart';

/// Hợp đồng của module Tin nhắn.
abstract class ChatService {
  Future<List<ChatThread>> fetchThreads();

  Future<List<ChatMessage>> fetchMessages(String threadId);

  Future<ChatMessage> sendMessage(
      {required String threadId, required String text});

  /// Tạo (hoặc lấy) cuộc trò chuyện 1-1 với một người dùng khác.
  Future<ChatThread> ensureDirect(
      {required String userId, required String name, String? avatarUrl});
}

/// Implementation thật gọi REST của backend (`/api/conversations`, `/api/messages`).
class ApiChatService implements ChatService {
  ApiChatService(this._api, this._session);

  final ApiClient _api;
  final SessionController _session;

  @override
  Future<List<ChatThread>> fetchThreads() async {
    final dynamic response = await _api.get('/api/conversations');
    final List<dynamic> list = asList(ApiClient.unwrap(response));
    return list.whereType<Map>().map((dynamic item) {
      final Map<String, dynamic> conv = asMap(item);
      return ChatThread(
        id: asString(conv['id']) ?? '',
        participantId: asString(conv['id']) ?? '',
        participantName: asString(conv['title']) ?? 'Cuộc trò chuyện',
        lastMessage: '',
        lastMessageAt: parseApiDate(conv['created_at']) ?? DateTime.now(),
        avatarUrl: asString(conv['avatar_url']),
      );
    }).toList(growable: false);
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    final dynamic response = await _api.get('/api/messages/$threadId');
    final List<dynamic> list = asList(ApiClient.unwrap(response));
    final String myId = _session.userId ?? '';
    final List<ChatMessage> messages =
        list.whereType<Map>().map((dynamic item) {
      final Map<String, dynamic> m = asMap(item);
      return ChatMessage(
        id: asString(m['id']) ?? '',
        threadId: threadId,
        text: asString(m['content']) ?? '',
        sentAt: parseApiDate(m['created_at']) ?? DateTime.now(),
        isMine: asString(m['user_id']) == myId,
      );
    }).toList(growable: false);
    messages
        .sort((ChatMessage a, ChatMessage b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  @override
  Future<ChatMessage> sendMessage(
      {required String threadId, required String text}) async {
    final dynamic response = await _api.post(
      '/api/messages',
      body: <String, dynamic>{
        'conversation_id': threadId,
        'content': text.trim(),
        'attachment_url': null,
      },
    );
    final Map<String, dynamic> m = asMap(ApiClient.unwrap(response));
    return ChatMessage(
      id: asString(m['id']) ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      text: text.trim(),
      sentAt: DateTime.now(),
      isMine: true,
    );
  }

  @override
  Future<ChatThread> ensureDirect(
      {required String userId, required String name, String? avatarUrl}) async {
    final dynamic response =
        await _api.post('/api/conversations/direct/$userId');
    final Map<String, dynamic> conv = asMap(ApiClient.unwrap(response));
    return ChatThread(
      id: asString(conv['id']) ?? '',
      participantId: userId,
      participantName: name,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
      avatarUrl: avatarUrl,
    );
  }
}

/// Implementation tạm thời dùng dữ liệu mẫu (không còn dùng ở production).
class MockChatService implements ChatService {
  MockChatService()
      : _threads = MockSeed.chatThreads(),
        _messages = MockSeed.messagesByThread();

  final List<ChatThread> _threads;
  final Map<String, List<ChatMessage>> _messages;

  @override
  Future<List<ChatThread>> fetchThreads() async {
    final List<ChatThread> threads = List<ChatThread>.from(_threads);
    threads.sort((ChatThread a, ChatThread b) =>
        b.lastMessageAt.compareTo(a.lastMessageAt));
    return threads;
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    final List<ChatMessage> messages = List<ChatMessage>.from(
      _messages[threadId] ?? const <ChatMessage>[],
    );
    messages
        .sort((ChatMessage a, ChatMessage b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  @override
  Future<ChatMessage> sendMessage(
      {required String threadId, required String text}) async {
    final ChatMessage message = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      text: text.trim(),
      sentAt: DateTime.now(),
      isMine: true,
    );
    _messages.putIfAbsent(threadId, () => <ChatMessage>[]).add(message);
    _updateThread(threadId, text.trim());
    return message;
  }

  @override
  Future<ChatThread> ensureDirect(
      {required String userId, required String name, String? avatarUrl}) async {
    for (final ChatThread thread in _threads) {
      if (thread.participantId == userId) {
        return thread;
      }
    }
    final ChatThread thread = ChatThread(
      id: 'thread-$userId',
      participantId: userId,
      participantName: name,
      lastMessage: 'Bắt đầu cuộc trò chuyện',
      lastMessageAt: DateTime.now(),
      avatarUrl: avatarUrl,
    );
    _threads.add(thread);
    _messages[thread.id] = <ChatMessage>[];
    return thread;
  }

  void _updateThread(String threadId, String lastMessage) {
    final int index =
        _threads.indexWhere((ChatThread item) => item.id == threadId);
    if (index == -1) {
      return;
    }
    _threads[index] = _threads[index].copyWith(
      lastMessage: lastMessage,
      lastMessageAt: DateTime.now(),
    );
  }
}
