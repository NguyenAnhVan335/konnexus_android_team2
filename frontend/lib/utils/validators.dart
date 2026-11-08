import '../config/api_config.dart';

/// Kiểm tra dữ liệu đầu vào ở mức cần thiết trước khi gọi API.
class Validators {
  const Validators._();

  static String? required(String? value, {String label = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label không được để trống';
    }
    return null;
  }

  static String? username(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Tên đăng nhập không được để trống';
    }
    if (text.length < 3) {
      return 'Tên đăng nhập phải có ít nhất 3 ký tự';
    }
    return null;
  }

  static String? email(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Email không được để trống';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (text.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) {
      return 'Vui lòng nhập lại mật khẩu';
    }
    if (value != original) {
      return 'Mật khẩu nhập lại không khớp';
    }
    return null;
  }

  static String? postContent(String? value, {required bool hasMedia}) {
    final String text = (value ?? '').trim();
    if (text.isEmpty && !hasMedia) {
      return 'Bài viết cần nội dung hoặc ít nhất một media';
    }
    if (text.length > ApiConfig.maxContentLength) {
      return 'Nội dung tối đa ${ApiConfig.maxContentLength} ký tự';
    }
    return null;
  }

  /// Backend chỉ chấp nhận URL http/https (validate trong PostService).
  static String? mediaUrl(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Vui lòng nhập URL media';
    }
    final Uri? uri = Uri.tryParse(text);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'URL phải bắt đầu bằng http:// hoặc https://';
    }
    return null;
  }
}
