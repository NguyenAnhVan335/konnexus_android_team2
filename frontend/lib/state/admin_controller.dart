import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/admin_model.dart';
import '../models/page_data.dart';
import '../services/admin_service.dart';

/// Controller cho module Admin Dashboard.
///
/// Quản lý dữ liệu tổng quan, danh sách người dùng, danh sách phòng chat và
/// trạng thái bật/tắt bot Charles.
class AdminController extends AppChangeNotifier {
  AdminController({required AdminService service}) : _service = service;

  final AdminService _service;

  // ---- Dashboard ----
  AdminDashboard? _dashboard;
  bool _dashboardLoading = false;
  String? _dashboardError;

  AdminDashboard? get dashboard => _dashboard;
  bool get dashboardLoading => _dashboardLoading;
  String? get dashboardError => _dashboardError;

  // ---- Bot ----
  bool _botBusy = false;
  String? _botError;

  bool get botBusy => _botBusy;
  String? get botError => _botError;

  // ---- Users ----
  List<AdminUser> _users = <AdminUser>[];
  int _usersPage = 0;
  final int _usersSize = 10;
  int _usersTotal = 0;
  String _usersKeyword = '';
  bool _usersLoading = false;
  String? _usersError;

  List<AdminUser> get users => _users;
  int get usersPage => _usersPage;
  int get usersSize => _usersSize;
  int get usersTotal => _usersTotal;
  String get usersKeyword => _usersKeyword;
  bool get usersLoading => _usersLoading;
  String? get usersError => _usersError;

  // ---- Rooms ----
  List<AdminRoom> _rooms = <AdminRoom>[];
  int _roomsPage = 0;
  final int _roomsSize = 10;
  int _roomsTotal = 0;
  bool _roomsLoading = false;
  String? _roomsError;

  List<AdminRoom> get rooms => _rooms;
  int get roomsPage => _roomsPage;
  int get roomsSize => _roomsSize;
  int get roomsTotal => _roomsTotal;
  bool get roomsLoading => _roomsLoading;
  String? get roomsError => _roomsError;

  Future<void> loadDashboard({bool force = false}) async {
    if (_dashboardLoading) {
      return;
    }
    if (_dashboard != null && !force) {
      return;
    }
    _dashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await _service.getDashboard();
    } on ApiException catch (error) {
      _dashboardError = error.userMessage;
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({
    int? page,
    String? keyword,
    bool force = false,
  }) async {
    if (_usersLoading) {
      return;
    }
    _usersPage = page ?? _usersPage;
    _usersKeyword = keyword ?? _usersKeyword;
    _usersLoading = true;
    _usersError = null;
    notifyListeners();
    try {
      PageData<AdminUser> result = await _service.getUsers(
        page: _usersPage,
        size: _usersSize,
        keyword: _usersKeyword,
      );
      // Trang hiện tại vượt quá số trang (thường do tìm kiếm): quay về trang đầu.
      if (result.content.isEmpty &&
          result.totalElements > 0 &&
          _usersPage > 0) {
        _usersPage = 0;
        result = await _service.getUsers(
          page: 0,
          size: _usersSize,
          keyword: _usersKeyword,
        );
      }
      _users = result.content;
      _usersTotal = result.totalElements;
    } on ApiException catch (error) {
      _usersError = error.userMessage;
    } finally {
      _usersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRooms({int? page, bool force = false}) async {
    if (_roomsLoading) {
      return;
    }
    _roomsPage = page ?? _roomsPage;
    _roomsLoading = true;
    _roomsError = null;
    notifyListeners();
    try {
      final PageData<AdminRoom> result =
          await _service.getRooms(page: _roomsPage, size: _roomsSize);
      _rooms = result.content;
      _roomsTotal = result.totalElements;
    } on ApiException catch (error) {
      _roomsError = error.userMessage;
    } finally {
      _roomsLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBotEnabled(bool enabled) async {
    if (_botBusy) {
      return;
    }
    _botBusy = true;
    _botError = null;
    notifyListeners();
    try {
      await _service.toggleBot(enabled);
      // Cập nhật trạng thái hiển thị ngay (không cần gọi lại dashboard).
      _dashboard = AdminDashboard(
        totalUsers: _dashboard?.totalUsers ?? 0,
        totalPosts: _dashboard?.totalPosts ?? 0,
        totalMessages: _dashboard?.totalMessages ?? 0,
        totalRooms: _dashboard?.totalRooms ?? 0,
        totalMessagesToday: _dashboard?.totalMessagesToday ?? 0,
        onlineUsers: _dashboard?.onlineUsers ?? 0,
        isBotEnabled: enabled,
        botTokensUsed: _dashboard?.botTokensUsed ?? 0,
        totalUsageHours: _dashboard?.totalUsageHours,
        chart: _dashboard?.chart ?? const <AdminChartPoint>[],
      );
    } on ApiException catch (error) {
      _botError = error.userMessage;
    } finally {
      _botBusy = false;
      notifyListeners();
    }
  }

  void clearBotError() {
    if (_botError == null) {
      return;
    }
    _botError = null;
    notifyListeners();
  }
}
