/// Cấu hình địa chỉ backend dùng chung cho toàn bộ ứng dụng.
///
/// Có thể ghi đè khi build mà không sửa code:
/// `flutter run --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080`
///
/// Lưu ý: Android Emulator không dùng được `localhost` để trỏ tới máy tính;
/// `10.0.2.2` là địa chỉ đặc biệt của emulator trỏ về host.
class ApiConfig {
  const ApiConfig._();

  static const String defaultBaseUrl = 'http://10.0.2.2:8080';

  static const String baseUrl = String.fromEnvironment(
    'KONNEXUS_API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  /// Số phần tử mỗi trang khi gọi các API phân trang (`size` <= 100 theo backend).
  static const int pageSize = 10;

  /// Giới hạn nghiệp vụ của Post API (khớp validation backend).
  static const int maxMediaPerPost = 10;
  static const int maxContentLength = 5000;

  static String get normalizedBaseUrl {
    if (baseUrl.endsWith('/')) {
      return baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }
}
