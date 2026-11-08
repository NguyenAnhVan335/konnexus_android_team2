import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';
import '../services/friendship_service.dart';
import 'session_controller.dart';
import 'users_directory.dart';

/// Danh sách bạn bè, lời mời đã nhận và lời mời đã gửi.
class FriendsController extends AppChangeNotifier {
  FriendsController({
    required FriendshipService friendshipService,
    required UsersDirectory directory,
    required SessionController session,
  })  : _friendshipService = friendshipService,
        _directory = directory,
        _session = session;

  final FriendshipService _friendshipService;
  final UsersDirectory _directory;
  final SessionController _session;

  List<FriendshipModel> _friends = <FriendshipModel>[];
  List<FriendshipModel> _received = <FriendshipModel>[];
  List<FriendshipModel> _sent = <FriendshipModel>[];
  bool _isLoading = false;
  bool _isBusy = false;
  String? _error;

  List<FriendshipModel> get friends => _friends;

  List<FriendshipModel> get received => _received;

  List<FriendshipModel> get sent => _sent;

  bool get isLoading => _isLoading;

  bool get isBusy => _isBusy;

  String? get error => _error;

  int get onlineCount => _friends
      .where((FriendshipModel item) => userOf(item)?.isOnline ?? false)
      .length;

  UserModel? userOf(FriendshipModel friendship) {
    final String? currentUserId = _session.userId;
    if (currentUserId == null) {
      return null;
    }
    return _directory.find(friendship.otherUserId(currentUserId));
  }

  Future<void> load({bool force = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _directory.ensureLoaded(force: force);
      final List<List<FriendshipModel>> results = await Future.wait(
        <Future<List<FriendshipModel>>>[
          _friendshipService.fetchFriends(),
          _friendshipService.fetchReceivedRequests(),
          _friendshipService.fetchSentRequests(),
        ],
      );
      _friends = results[0];
      _received = results[1];
      _sent = results[2];
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> accept(FriendshipModel request) async {
    await _run(() => _friendshipService.acceptRequest(request.id));
  }

  Future<void> reject(FriendshipModel request) async {
    await _run(() => _friendshipService.rejectRequest(request.id));
  }

  Future<void> cancel(FriendshipModel request) async {
    await _run(() => _friendshipService.cancelRequest(request.id));
  }

  Future<void> unfriend(FriendshipModel friend) async {
    final UserModel? other = userOf(friend);
    if (other == null) {
      return;
    }
    await _run(() => _friendshipService.unfriend(other.id));
  }

  Future<void> _run(Future<void> Function() action) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      await load(force: true);
    } on ApiException catch (error) {
      _error = error.userMessage;
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
