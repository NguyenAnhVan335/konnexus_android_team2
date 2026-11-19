/// Bản stub cho nền tảng không có `dart:io` (web).
class ChatSocket {
  ChatSocket._();

  static Future<ChatSocket> connect(String url) async {
    throw UnsupportedError(
        'WebSocket realtime chưa được hỗ trợ trên nền tảng này.');
  }

  void add(String data) {}

  void close() {}

  void listen(
    void Function(dynamic data) onData, {
    void Function()? onDone,
    void Function(Object error)? onError,
    bool cancelOnError = false,
  }) {}
}
