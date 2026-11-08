/// Lỗi tầng API: gồm lỗi HTTP do backend trả về và lỗi mạng.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  bool get isNetworkError => statusCode == null;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  /// Thông điệp tiếng Việt dùng để hiển thị cho người dùng cuối.
  String get userMessage {
    if (statusCode == null) {
      return 'Không kết nối được máy chủ. Kiểm tra địa chỉ backend và kết nối mạng.';
    }
    if (statusCode == 500) {
      return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
    }
    final String value = message.trim();
    return value.isEmpty ? 'Yêu cầu thất bại (HTTP $statusCode).' : value;
  }

  @override
  String toString() =>
      'ApiException(status: $statusCode, code: $code, message: $message)';
}
