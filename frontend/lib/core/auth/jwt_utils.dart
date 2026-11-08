import 'dart:convert';

/// Đọc `sub` (id người dùng) từ payload JWT do `/api/auth/login` trả về.
///
/// Backend chỉ trả `{ "token": "..." }` nên không có endpoint "lấy user hiện tại";
/// id người dùng lấy từ claim `sub` để gắn vào header `X-User-Id` của Post API.
String? userIdFromJwt(String token) {
  final List<String> parts = token.split('.');
  if (parts.length < 2) {
    return null;
  }
  try {
    final String normalized = base64Url.normalize(parts[1]);
    final dynamic payload =
        jsonDecode(utf8.decode(base64Url.decode(normalized)));
    if (payload is Map) {
      final dynamic subject = payload['sub'];
      if (subject is String && subject.isNotEmpty) {
        return subject;
      }
    }
  } on FormatException {
    return null;
  }
  return null;
}
