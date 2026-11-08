import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/friendship_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/friendship_service.dart';
import '../services/interaction_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'paged_posts_controller.dart';
import 'session_controller.dart';
import 'users_directory.dart';

/// Trang cá nhân của chính mình hoặc của người dùng khác.
class ProfileController extends AppChangeNotifier {
  ProfileController({
    required this.userId,
    required UserService userService,
    required FriendshipService friendshipService,
    required PostService postService,
    required InteractionService interactionService,
    required UsersDirectory directory,
    required SessionController session,
  })  : _userService = userService,
        _friendshipService = friendshipService,
        _directory = directory,
        _session = session,
        posts = UserPostsController(
          userId: userId,
          postService: postService,
          interactionService: interactionService,
          session: session,
        );

  final String userId;
  final UserService _userService;
  final FriendshipService _friendshipService;
  final UsersDirectory _directory;
  final SessionController _session;

  final UserPostsController posts;

  UserModel? _user;
  RelationshipModel? _relationship;
  int? _friendCount;
  bool _isLoading = false;
  bool _isBusy = false;
  String? _error;
  String? _relationshipWarning;

  UserModel? get user => _user;

  RelationshipModel? get relationship => _relationship;

  int? get friendCount => _friendCount;

  bool get isLoading => _isLoading;

  bool get isBusy => _isBusy;

  String? get error => _error;

  String? get relationshipWarning => _relationshipWarning;

  bool get isOwnProfile => _session.userId == userId;

  String get displayName =>
      _user?.displayName ??
      (_session.userId == userId ? _session.displayName : 'Người dùng');

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    _relationshipWarning = null;
    notifyListeners();
    try {
      _user =
          _session.userId == userId ? _session.user : _directory.find(userId);
      if (_user == null) {
        await _directory.ensureLoaded();
        _user = _directory.find(userId);
      }
      _user ??= await _userService.findById(userId);
      if (_user == null) {
        throw const ApiException('Không tìm thấy người dùng này.');
      }
      if (!isOwnProfile) {
        try {
          _relationship = await _friendshipService.fetchStatus(userId);
        } on ApiException catch (error) {
          _relationshipWarning = error.userMessage;
        }
      } else {
        try {
          final List<FriendshipModel> friends =
              await _friendshipService.fetchFriends();
          _friendCount = friends.length;
        } on ApiException {
          _friendCount = null;
        }
      }
      await posts.refresh();
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPosts() => posts.refresh();

  Future<void> sendFriendRequest() async {
    await _run(() async {
      await _friendshipService.sendRequest(userId);
      _relationship = await _friendshipService.fetchStatus(userId);
    });
  }

  Future<void> cancelFriendRequest() async {
    final RelationshipModel? current = _relationship;
    if (current?.friendshipId == null) {
      return;
    }
    await _run(() async {
      await _friendshipService.cancelRequest(current!.friendshipId!);
      _relationship = await _friendshipService.fetchStatus(userId);
    });
  }

  Future<void> acceptFriendRequest() async {
    final RelationshipModel? current = _relationship;
    if (current?.friendshipId == null) {
      return;
    }
    await _run(() async {
      await _friendshipService.acceptRequest(current!.friendshipId!);
      _relationship = await _friendshipService.fetchStatus(userId);
    });
  }

  Future<void> unfriend() async {
    await _run(() async {
      await _friendshipService.unfriend(userId);
      _relationship = await _friendshipService.fetchStatus(userId);
    });
  }

  Future<void> toggleLike(PostModel post, String emojiType) {
    return posts.toggleLike(post, emojiType);
  }

  Future<void> deletePost(String postId) {
    return posts.deletePost(postId);
  }

  Future<void> _run(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (error) {
      _error = error.userMessage;
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
