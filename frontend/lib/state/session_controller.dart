import 'dart:async';

import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../core/storage/preferences_store.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

enum SessionStatus { starting, unauthenticated, authenticated }

/// Quản lý phiên đăng nhập và hồ sơ người dùng hiện tại.
///
/// Đây là nguồn dữ liệu duy nhất cung cấp header xác thực cho `ApiClient`:
/// - `Authorization: Bearer <token>` cho `/api/users` và Post API.
/// - `X-Test-User-Id` cho Friendship API (chỉ backend dev/test chấp nhận).
class SessionController extends AppChangeNotifier {
  SessionController({required PreferencesStore store}) : _store = store;

  final PreferencesStore _store;

  late final AuthService _authService;
  late final UserService _userService;

  /// Gọi sau khi phiên bị xoá (ví dụ để xoá cache người dùng của phiên cũ).
  void Function()? _onSessionCleared;

  SessionStatus _status = SessionStatus.starting;
  String? _token;
  String? _userId;
  UserModel? _user;
  String? _address;
  String? _gender;
  bool _isBusy = false;
  String? _error;
  String? _sessionNotice;

  SessionStatus get status => _status;

  String? get userId => _userId;

  UserModel? get user => _user;

  String? get address => _address;

  String? get gender => _gender;

  bool get isBusy => _isBusy;

  String? get error => _error;

  bool get isAuthenticated => _status == SessionStatus.authenticated;

  String get displayName => _user?.displayName ?? 'Người dùng';

  String get avatarUrl => _user?.avatarUrl ?? '';

  Map<String, String> get authHeaders {
    final Map<String, String> headers = <String, String>{};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Gắn service sau khi khởi tạo để tránh vòng lặp phụ thuộc
  /// (`ApiClient` cần header của session, session cần service gọi API).
  void attach({
    required AuthService authService,
    required UserService userService,
    void Function()? onSessionCleared,
  }) {
    _authService = authService;
    _userService = userService;
    _onSessionCleared = onSessionCleared;
  }

  /// Khôi phục phiên đã lưu và làm mới hồ sơ ở nền.
  Future<void> restore() async {
    _address = _store.address;
    final String? token = _store.token;
    final String? userId = _store.userId;
    if (token == null || userId == null) {
      _status = SessionStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _token = token;
    _userId = userId;
    _user = _store.cachedUser;
    _address = _store.address;
    _gender = _store.cachedUser?.gender;
    _status = SessionStatus.authenticated;
    notifyListeners();
    unawaited(refreshProfile(silently: true));
    setOnline(true);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _setBusy(true);
    _error = null;
    try {
      final AuthSession session = await _authService.login(
        username: username,
        password: password,
      );
      _token = session.token;
      _userId = session.userId;
      _status = SessionStatus.authenticated;
      await _store.saveSession(token: session.token, userId: session.userId);
      notifyListeners();
      setOnline(true);
      await refreshProfile(silently: true);
    } on ApiException catch (error) {
      _error = error.userMessage;
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    _error = null;
    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );
    } on ApiException catch (error) {
      _error = error.userMessage;
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  /// Lấy hồ sơ mới nhất từ `GET /api/users` (backend chưa có `/api/users/me`).
  Future<void> refreshProfile({bool silently = false}) async {
    if (_userId == null) {
      return;
    }
    try {
      final UserModel? fetched = await _userService.findById(_userId!);
      if (fetched != null) {
        _user = fetched.copyWith(
          address: _address ?? fetched.address,
          gender: _gender ?? fetched.gender,
        );
        _gender = _user?.gender;
        await _store.saveUser(_user!);
        notifyListeners();
      }
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await handleUnauthorized();
        return;
      }
      if (!silently) {
        _error = error.userMessage;
        notifyListeners();
      }
    }
  }

  /// Cập nhật hồ sơ: phần lõi gọi backend, giới tính/địa chỉ lưu cục bộ.
  Future<void> updateProfile({
    required String username,
    required String email,
    required String password,
    String? avatarUrl,
    String? gender,
    DateTime? birthday,
    String? address,
  }) async {
    if (_userId == null) {
      throw const ApiException('Bạn cần đăng nhập để cập nhật hồ sơ.');
    }
    _setBusy(true);
    _error = null;
    try {
      await _userService.updateProfile(
        userId: _userId!,
        username: username,
        email: email,
        password: password,
        avatarUrl: avatarUrl,
      );
      await _store.saveAddress(address);
      _address = address;
      _gender = gender;
      final UserModel updated = UserModel(
        id: _userId!,
        username: username.trim(),
        email: email.trim(),
        avatarUrl: avatarUrl,
        isOnline: _user?.isOnline ?? false,
        note: _user?.note,
        birthday: birthday ?? _user?.birthday,
        createdAt: _user?.createdAt,
        lastSeen: _user?.lastSeen,
        address: address,
        gender: gender,
      );
      _user = updated;
      await _store.saveUser(updated);
      notifyListeners();
    } on ApiException catch (error) {
      _error = error.userMessage;
      rethrow;
    } finally {
      _setBusy(false);
    }
  }

  /// Đăng xuất và xoá phiên đã lưu trên thiết bị.
  ///
  /// [clearNotice] = `false` khi đăng xuất tự động do `401`: thông báo
  /// "phiên hết hạn" cần được giữ lại cho màn hình đăng nhập hiển thị.
  Future<void> logout({bool clearNotice = true}) async {
    if (clearNotice) {
      _sessionNotice = null;
    }
    // Đánh dấu offline trước khi xoá token (request vẫn mang token cũ).
    unawaited(_updateStatus(false));
    _token = null;
    _userId = null;
    _user = null;
    _address = null;
    _gender = null;
    _status = SessionStatus.unauthenticated;
    _error = null;
    await _store.clearSession();
    _onSessionCleared?.call();
    notifyListeners();
  }

  /// Đăng xuất tự động khi backend trả `401` (token hết hạn hoặc không hợp lệ).
  ///
  /// Được gọi bởi `ApiClient.onUnauthorized`, nên có thể xảy ra đồng thời với
  /// nhiều request. Trạng thái được đặt lại ngay từ đầu để các lần gọi sau
  /// không lặp lại việc đăng xuất/thông báo.
  Future<void> handleUnauthorized() async {
    if (_status != SessionStatus.authenticated) {
      return;
    }
    _sessionNotice = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    await logout(clearNotice: false);
  }

  /// Lấy (và xoá) thông báo phiên hết hạn; màn hình đăng nhập gọi một lần.
  String? takeNotice() {
    final String? notice = _sessionNotice;
    _sessionNotice = null;
    return notice;
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  /// Đánh dấu người dùng đang online/offline (fire-and-forget).
  void setOnline(bool online) {
    if (_status != SessionStatus.authenticated || _userId == null) {
      return;
    }
    unawaited(_updateStatus(online));
  }

  Future<void> _updateStatus(bool online) async {
    try {
      await _userService.updateStatus(online);
    } on ApiException {
      // Bỏ qua lỗi cập nhật trạng thái hoạt động (không ảnh hưởng UX).
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
