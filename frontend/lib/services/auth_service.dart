import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/auth/jwt_utils.dart';
import '../utils/json_utils.dart';

/// Kết quả đăng nhập: token JWT và id người dùng đọc từ claim `sub`.
class AuthSession {
  const AuthSession({required this.token, required this.userId});

  final String token;
  final String userId;
}

/// Gọi các endpoint xác thực đã có trong backend:
/// - `POST /api/auth/login`
/// - `POST /api/auth/register`
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final dynamic response = await _api.post(
      '/api/auth/login',
      body: <String, dynamic>{
        'username': username.trim(),
        'password': password,
      },
      // Sai mật khẩu cũng trả 401: không được coi là "phiên hết hạn".
      authenticated: false,
    );
    final Map<String, dynamic> map = asMap(response);
    final String? token = asString(map['token']);
    if (token == null || token.isEmpty) {
      throw const ApiException('Phản hồi đăng nhập không chứa token hợp lệ.');
    }
    final String? userId = userIdFromJwt(token);
    if (userId == null) {
      throw const ApiException('Không đọc được id người dùng từ token.');
    }
    return AuthSession(token: token, userId: userId);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _api.post(
      '/api/auth/register',
      body: <String, dynamic>{
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      },
      authenticated: false,
    );
  }
}
