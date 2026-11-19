import 'dart:async';
import 'dart:convert';

import '../config/api_config.dart';
import '../core/api/api_client.dart';
import '../data/mock/mock_seed.dart';
import '../models/chat_model.dart';
import '../state/session_controller.dart';
import '../utils/json_utils.dart';
import 'chat_socket.dart';

/// Hợp đồng của module Tin nhắn.
abstract class ChatService {
  Future<List<ChatThread>> fetchThreads();

  Future<List<ChatMessage>> fetchMessages(String threadId);

  Future<ChatMessage> sendMessage(
      {required String threadId, required String text});

  /// Tạo (hoặc lấy) cuộc trò chuyện 1-1 với một người dùng khác.
  Future<ChatThread> ensureDirect(
      {required String userId, required String name, String? avatarUrl});

  /// Tạo nhóm chat mới (nhiều thành viên) và trả về thread vừa tạo.
  Future<ChatThread> createGroup({
    required String title,
    required List<String> memberIds,
    String? avatarUrl,
  });

  /// Lắng nghe tin nhắn realtime của một cuộc trò chuyện qua WebSocket.
  Stream<ChatMessage> watchMessages(String threadId);

  /// Đóng kết nối WebSocket realtime (gọi khi rời màn hình chat).
  void closeSocket();
}

/// Implementation thật gọi REST của backend (`/api/conversations`, `/api/messages`).
class ApiChatService implements ChatService {
  ApiChatService(this._api, this._session);

  final ApiClient _api;
  final SessionController _session;

  ChatSocket? _socket;
  StreamController<ChatMessage>? _incoming;
  String? _activeThreadId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

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
    final String content = text.trim();
    final ChatSocket? socket = _socket;
    if (socket != null && _activeThreadId == threadId) {
      try {
        // Gửi qua WebSocket để backend broadcast realtime cho mọi người trong
        // phòng (kể cả chính mình). Tin nhắn thật sẽ quay lại qua kênh watchMessages.
        socket.add(jsonEncode(<String, dynamic>{
          'type': 'CHAT',
          'content': content,
          'attachment_url': null,
        }));
        return ChatMessage(
          id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
          threadId: threadId,
          text: content,
          sentAt: DateTime.now(),
          isMine: true,
        );
      } catch (_) {
        // Socket vừa đóng: rơi xuống fallback REST bên dưới.
      }
    }

    // Fallback REST khi chưa có kết nối realtime.
    final dynamic response = await _api.post(
      '/api/messages',
      body: <String, dynamic>{
        'conversation_id': threadId,
        'content': content,
        'attachment_url': null,
      },
    );
    final Map<String, dynamic> m = asMap(ApiClient.unwrap(response));
    return ChatMessage(
      id: asString(m['id']) ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      text: content,
      sentAt: DateTime.now(),
      isMine: true,
    );
  }

  @override
  Stream<ChatMessage> watchMessages(String threadId) {
    closeSocket();
    _activeThreadId = threadId;
    _reconnectAttempts = 0;
    _incoming = StreamController<ChatMessage>.broadcast();
    unawaited(_connect(threadId));
    return _incoming!.stream;
  }

  @override
  void closeSocket() {
    _activeThreadId = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final ChatSocket? socket = _socket;
    _socket = null;
    socket?.close();
    _incoming?.close();
    _incoming = null;
  }

  Future<void> _connect(String threadId) async {
    final String token = _session.token ?? '';
    // Chưa có token thì không thể xác thực WebSocket; chờ lần gọi lại.
    if (token.isEmpty) {
      _scheduleReconnect(threadId);
      return;
    }
    final Uri uri = Uri.parse('${ApiConfig.wsBaseUrl}/chat/$threadId')
        .replace(queryParameters: <String, String>{'token': token});
    try {
      final ChatSocket socket = await ChatSocket.connect(uri.toString());
      // Tránh ghi đè kết nối khi người dùng đã chuyển sang thread khác.
      if (_activeThreadId != threadId) {
        socket.close();
        return;
      }
      _socket = socket;
      _reconnectAttempts = 0;
      socket.listen(
        (dynamic data) => _handleIncoming(threadId, data),
        onDone: () => _handleSocketClosed(threadId, socket),
        onError: (Object error) {
          _emitError(error);
          _handleSocketClosed(threadId, socket);
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Kết nối realtime thất bại (mất mạng, handshake, hoặc nền tảng không
      // hỗ trợ WebSocket như web): thử lại với backoff; trong lúc chờ, người
      // dùng vẫn gửi/nhận được qua REST fallback.
      _scheduleReconnect(threadId);
    }
  }

  /// Xử lý khi socket bị đóng ngoài ý muốn (mất mạng, server ngắt): lên lịch
  /// kết nối lại nếu người dùng vẫn còn ở thread này.
  void _handleSocketClosed(String threadId, ChatSocket socket) {
    if (_activeThreadId != threadId || !identical(_socket, socket)) {
      return;
    }
    _socket = null;
    _scheduleReconnect(threadId);
  }

  /// Kết nối lại với backoff tăng dần (2s -> 4s -> 8s -> 16s -> 30s).
  void _scheduleReconnect(String threadId) {
    if (_activeThreadId != threadId || _reconnectTimer != null) {
      return;
    }
    _reconnectAttempts += 1;
    const List<int> backoffSeconds = <int>[2, 4, 8, 16, 30];
    final int index =
        (_reconnectAttempts - 1).clamp(0, backoffSeconds.length - 1);
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds[index]), () {
      _reconnectTimer = null;
      if (_activeThreadId == threadId) {
        unawaited(_connect(threadId));
      }
    });
  }

  void _emit(ChatMessage message) {
    final StreamController<ChatMessage>? controller = _incoming;
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.add(message);
  }

  void _emitError(Object error) {
    final StreamController<ChatMessage>? controller = _incoming;
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.addError(error);
  }

  void _handleIncoming(String threadId, dynamic data) {
    if (data is! String || _incoming == null) {
      return;
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(data) as Map<String, dynamic>;
    } on FormatException {
      return;
    } on TypeError {
      return;
    }
    if (asString(json['type'])?.toUpperCase() != 'CHAT') {
      return;
    }
    final String senderId = asString(json['user_id']) ?? '';
    _emit(ChatMessage(
      id: asString(json['id']) ?? 'ws-${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      text: asString(json['content']) ?? '',
      sentAt: parseApiDate(json['created_at']) ?? DateTime.now(),
      isMine: senderId.isNotEmpty && senderId == _session.userId,
    ));
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

  @override
  Future<ChatThread> createGroup({
    required String title,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    final dynamic response = await _api.post(
      '/api/conversations',
      body: <String, dynamic>{
        'title': title,
        'memberIds': memberIds,
        'avatar_url': avatarUrl,
      },
    );
    final Map<String, dynamic> conv = asMap(ApiClient.unwrap(response));
    return ChatThread(
      id: asString(conv['id']) ?? '',
      participantId: '',
      participantName: asString(conv['title']) ?? title,
      lastMessage: '',
      lastMessageAt: parseApiDate(conv['created_at']) ?? DateTime.now(),
      avatarUrl: asString(conv['avatar_url']),
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

  @override
  Future<ChatThread> createGroup({
    required String title,
    required List<String> memberIds,
    String? avatarUrl,
  }) async {
    final ChatThread thread = ChatThread(
      id: 'group-${DateTime.now().microsecondsSinceEpoch}',
      participantId: '',
      participantName: title,
      lastMessage: 'Nhóm đã được tạo',
      lastMessageAt: DateTime.now(),
      avatarUrl: avatarUrl,
    );
    _threads.add(thread);
    _messages[thread.id] = <ChatMessage>[];
    return thread;
  }

  @override
  Stream<ChatMessage> watchMessages(String threadId) {
    return const Stream<ChatMessage>.empty();
  }

  @override
  void closeSocket() {}

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
