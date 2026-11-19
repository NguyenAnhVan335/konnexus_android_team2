/// WebSocket transport cho module chat — chọn implementation theo nền tảng.
///
/// Android/iOS/Windows (có `dart:io`) dùng [chat_socket_io.dart] kết nối
/// WebSocket thật; web (không có `dart:io`) dùng [chat_socket_stub.dart] ném
/// `UnsupportedError` để mã nguồn vẫn biên dịch được với `flutter run -d chrome`.
/// Trên web, module chat vẫn gửi/nhận được qua REST fallback.
library;

export 'chat_socket_stub.dart' if (dart.library.io) 'chat_socket_io.dart';
