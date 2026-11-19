import 'dart:io';

/// Bọc `dart:io` WebSocket để module chat không import trực tiếp `dart:io`,
/// nhờ đó toàn bộ ứng dụng vẫn biên dịch được cho web.
class ChatSocket {
  ChatSocket._(this._socket);

  final WebSocket _socket;

  static Future<ChatSocket> connect(String url) async {
    return ChatSocket._(await WebSocket.connect(url));
  }

  void add(String data) => _socket.add(data);

  void close() => _socket.close();

  void listen(
    void Function(dynamic data) onData, {
    void Function()? onDone,
    void Function(Object error)? onError,
    bool cancelOnError = false,
  }) {
    _socket.listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }
}
