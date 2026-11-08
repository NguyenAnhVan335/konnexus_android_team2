import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../utils/json_utils.dart';
import 'api_exception.dart';

/// Trả về header xác thực hiện tại (`Authorization`, `X-User-Id`, `X-Test-User-Id`).
typedef AuthHeadersProvider = Map<String, String> Function();

/// Gọi khi một request **cần xác thực** nhận HTTP `401`.
typedef UnauthorizedCallback = void Function();

/// Client HTTP duy nhất của ứng dụng.
///
/// - Không rải URL trong màn hình: mọi service đều nhận [ApiClient] này.
/// - Tự gắn token/định danh người dùng vào header.
/// - Chuẩn hoá lỗi mạng và lỗi HTTP thành [ApiException].
/// - Báo `401` qua [onUnauthorized] để tầng phiên đăng xuất tập trung.
class ApiClient {
  ApiClient({
    required AuthHeadersProvider headersProvider,
    http.Client? httpClient,
    String? baseUrl,
    this.onUnauthorized,
  })  : _headersProvider = headersProvider,
        _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final AuthHeadersProvider _headersProvider;
  final http.Client _http;
  final String _baseUrl;

  /// Được gọi mỗi khi request có xác thực trả `401` (token hết hạn/không hợp lệ).
  ///
  /// Không được gọi cho các endpoint công khai như `/api/auth/login`
  /// (truyền `authenticated: false` khi gọi) để tránh đăng xuất nhầm khi
  /// người dùng nhập sai mật khẩu.
  UnauthorizedCallback? onUnauthorized;

  String get baseUrl => _baseUrl;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) {
    return _send('GET', path, query: query, authenticated: authenticated);
  }

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> put(String path, {Object? body, bool authenticated = true}) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> delete(String path,
      {Object? body, bool authenticated = true}) {
    return _send('DELETE', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final Uri uri = _buildUri(path, query);
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      ..._headersProvider(),
    };

    try {
      final http.Request request = http.Request(method, uri);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final http.StreamedResponse streamed =
          await _http.send(request).timeout(ApiConfig.requestTimeout);
      final http.Response response = await http.Response.fromStream(streamed);
      return _decode(response, authenticated: authenticated);
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on SocketException {
      throw const ApiException('Không kết nối được máy chủ.');
    } on http.ClientException {
      throw const ApiException('Không kết nối được máy chủ.');
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final String base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final String normalizedPath = path.startsWith('/') ? path : '/$path';
    final Uri uri = Uri.parse('$base$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(
        queryParameters: <String, String>{...uri.queryParameters, ...query});
  }

  dynamic _decode(http.Response response, {bool authenticated = true}) {
    final int status = response.statusCode;
    final String raw = utf8.decode(response.bodyBytes, allowMalformed: true);
    dynamic json;
    if (raw.trim().isNotEmpty) {
      try {
        json = jsonDecode(raw);
      } on FormatException {
        json = null;
      }
    }
    if (status >= 200 && status < 300) {
      return json;
    }
    if (status == 401 && authenticated) {
      onUnauthorized?.call();
    }
    final Map<String, dynamic> map = asMap(json);
    throw ApiException(
      asString(map['message']) ??
          asString(map['error']) ??
          'Yêu cầu thất bại (HTTP $status).',
      statusCode: status,
      code: asString(map['code']),
    );
  }

  /// Bóc lớp `{ success, message, data }`; trả nguyên giá trị nếu không có `data`.
  static dynamic unwrap(dynamic response) {
    if (response is Map) {
      final Map<String, dynamic> map = asMap(response);
      if (map.containsKey('data')) {
        return map['data'];
      }
    }
    return response;
  }

  void dispose() {
    _http.close();
  }
}
