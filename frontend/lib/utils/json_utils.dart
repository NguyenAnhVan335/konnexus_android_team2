/// Các hàm đọc JSON an toàn.
///
/// Backend trả dữ liệu bằng Jackson (snake_case cho DTO của Post API, camelCase
/// cho các DTO cũ), nên tầng model luôn đọc qua các helper này thay vì ép kiểu
/// trực tiếp để một field null/đổi tên không làm sập toàn bộ màn hình.
library;

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map<String, dynamic>(
      (dynamic key, dynamic item) =>
          MapEntry<String, dynamic>(key.toString(), item),
    );
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

String? asString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String normalized = value.toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
  }
  return fallback;
}

/// `LocalDateTime` của Java không kèm timezone, `DateTime.tryParse` xử lý được.
DateTime? parseApiDate(dynamic value) {
  final String? raw = asString(value);
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw.trim());
}
