import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

/// Trạng thái module Tin nhắn (dữ liệu do [ApiChatService] cung cấp).
class MessagesController extends AppChangeNotifier {
  MessagesController(this._chatService);

  final ChatService _chatService;

  List<ChatThread> _threads = <ChatThread>[];
  bool _isLoading = false;
  String? _error;

  List<ChatThread> get threads => _threads;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadThreads() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _threads = await _chatService.fetchThreads();
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ChatMessage>> loadMessages(String threadId) {
    return _chatService.fetchMessages(threadId);
  }

  Future<ChatMessage> sendMessage(String threadId, String text) async {
    final ChatMessage message =
        await _chatService.sendMessage(threadId: threadId, text: text);
    _threads = await _chatService.fetchThreads();
    notifyListeners();
    return message;
  }

  Future<ChatThread> ensureDirect({
    required String userId,
    required String name,
    String? avatarUrl,
  }) {
    return _chatService.ensureDirect(
        userId: userId, name: name, avatarUrl: avatarUrl);
  }

  /// Tạo nhóm chat mới (nhiều thành viên) và trả về thread vừa tạo.
  Future<ChatThread> createGroup({
    required String title,
    required List<String> memberIds,
    String? avatarUrl,
  }) {
    return _chatService.createGroup(
        title: title, memberIds: memberIds, avatarUrl: avatarUrl);
  }

  /// Lắng nghe tin nhắn realtime của một cuộc trò chuyện.
  Stream<ChatMessage> watchMessages(String threadId) {
    return _chatService.watchMessages(threadId);
  }

  /// Đóng kết nối realtime khi rời màn hình chat.
  void closeSocket() {
    _chatService.closeSocket();
  }
}
