import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

/// Cache danh sách người dùng để hiển thị tên/avatar ở bài viết, bạn bè,
/// tìm kiếm. Chỉ gọi `GET /api/users` một lần cho mỗi phiên.
class UsersDirectory extends AppChangeNotifier {
  UsersDirectory(this._userService);

  final UserService _userService;
  final Map<String, UserModel> _byId = <String, UserModel>{};

  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  bool get isLoading => _isLoading;

  bool get isLoaded => _isLoaded;

  String? get error => _error;

  List<UserModel> get users => _byId.values.toList(growable: false);

  UserModel? find(String? id) => id == null ? null : _byId[id];

  Future<void> ensureLoaded({bool force = false}) async {
    if (_isLoading || (_isLoaded && !force)) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final List<UserModel> users = await _userService.fetchUsers();
      _byId
        ..clear()
        ..addEntries(users.map(
            (UserModel user) => MapEntry<String, UserModel>(user.id, user)));
      _isLoaded = true;
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void merge(UserModel user) {
    if (user.id.isEmpty) {
      return;
    }
    _byId[user.id] = user;
    notifyListeners();
  }

  void clear() {
    _byId.clear();
    _isLoaded = false;
    notifyListeners();
  }
}
