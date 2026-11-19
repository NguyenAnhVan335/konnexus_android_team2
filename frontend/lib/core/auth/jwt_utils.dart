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

/// Đọc quyền admin từ JWT (`admin: true` do backend gắn khi đăng nhập).
///
/// Backend cũng đặt role vào claim `groups`; trường hợp chưa có claim `admin`,
/// ta fallback sang `groups` để không bỏ sót tài khoản ADMIN cũ.
bool isAdminJwt(String? token) {
  if (token == null || token.isEmpty) {
    return false;
  }
  try {
    final List<String> parts = token.split('.');
    if (parts.length < 2) {
      return false;
    }
    final String normalized = base64Url.normalize(parts[1]);
    final dynamic payload =
        jsonDecode(utf8.decode(base64Url.decode(normalized)));
    if (payload is Map) {
      final dynamic admin = payload['admin'];
      if (admin is bool) {
        return admin;
      }
      final dynamic groups = payload['groups'];
      if (groups is List) {
        return groups.any((dynamic group) => group == 'ADMIN');
      }
      if (groups is String) {
        return groups.split(',').any((String g) => g.trim() == 'ADMIN');
      }
    }
  } on FormatException {
    return false;
  }
  return false;
}
