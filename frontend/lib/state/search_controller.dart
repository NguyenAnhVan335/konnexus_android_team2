import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../core/storage/preferences_store.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';
import '../services/friendship_service.dart';
import 'session_controller.dart';
import 'users_directory.dart';

/// Tìm kiếm người dùng.
///
/// Backend chưa có endpoint tìm kiếm: dữ liệu lấy từ `GET /api/users` (đã có)
/// và lọc phía client theo tên/email, trạng thái online và quan hệ bạn bè.
///
/// Tên lớp có tiền tố `User` để không xung đột với `SearchController` của Flutter.
class UserSearchController extends AppChangeNotifier {
  UserSearchController({
    required UsersDirectory directory,
    required FriendshipService friendshipService,
    required SessionController session,
    required PreferencesStore store,
  })  : _directory = directory,
        _friendshipService = friendshipService,
        _session = session,
        _store = store;

  final UsersDirectory _directory;
  final FriendshipService _friendshipService;
  final SessionController _session;
  final PreferencesStore _store;

  String _query = '';
  bool _onlineOnly = false;
  bool _friendsOnly = false;
  bool _isLoading = false;
  String? _error;
  List<String> _friendIds = <String>[];
  List<String> _savedSearches = <String>[];

  String get query => _query;

  bool get onlineOnly => _onlineOnly;

  bool get friendsOnly => _friendsOnly;

  bool get isLoading => _isLoading;

  String? get error => _error;

  List<String> get savedSearches => _savedSearches;

  List<UserModel> get results {
    final String keyword = _query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return const <UserModel>[];
    }
    return _directory.users.where((UserModel user) {
      if (user.id == _session.userId) {
        return false;
      }
      if (keyword.isNotEmpty &&
          !user.displayName.toLowerCase().contains(keyword) &&
          !(user.email ?? '').toLowerCase().contains(keyword)) {
        return false;
      }
      if (_onlineOnly && !user.isOnline) {
        return false;
      }
      if (_friendsOnly && !_friendIds.contains(user.id)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  Future<void> load() async {
    _savedSearches = _store.savedSearches;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _directory.ensureLoaded();
      final List<FriendshipModel> friends =
          await _friendshipService.fetchFriends();
      final String? currentUserId = _session.userId;
      _friendIds = currentUserId == null
          ? <String>[]
          : friends
              .map((FriendshipModel item) => item.otherUserId(currentUserId))
              .toList(growable: false);
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateQuery(String value) {
    if (_query == value) {
      return;
    }
    _query = value;
    notifyListeners();
  }

  void setOnlineOnly(bool value) {
    if (_onlineOnly == value) {
      return;
    }
    _onlineOnly = value;
    notifyListeners();
  }

  void setFriendsOnly(bool value) {
    if (_friendsOnly == value) {
      return;
    }
    _friendsOnly = value;
    notifyListeners();
  }

  Future<void> saveCurrentQuery() async {
    if (_query.trim().isEmpty) {
      return;
    }
    await _store.saveSearch(_query);
    _savedSearches = _store.savedSearches;
    notifyListeners();
  }

  Future<void> removeSavedQuery(String value) async {
    await _store.removeSavedSearch(value);
    _savedSearches = _store.savedSearches;
    notifyListeners();
  }
}
