import 'app_change_notifier.dart';

import '../config/api_config.dart';
import '../core/api/api_exception.dart';
import '../models/page_data.dart';
import '../models/post_model.dart';
import '../services/interaction_service.dart';
import '../services/post_service.dart';
import 'session_controller.dart';

/// Controller dùng chung cho mọi danh sách bài viết có phân trang
/// (bảng tin, khám phá, trang cá nhân).
abstract class PagedPostsController extends AppChangeNotifier {
  PagedPostsController({
    required this.postService,
    required this.interactionService,
    required this.session,
  });

  final PostService postService;
  final InteractionService interactionService;
  final SessionController session;

  final List<PostModel> items = <PostModel>[];

  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;
  int _totalElements = 0;

  bool get isLoading => _isLoading;

  bool get hasMore => _hasMore;

  String? get error => _error;

  bool get isEmpty => items.isEmpty;

  /// Tổng số phần tử backend báo về (dùng cho "Số bài viết" ở trang cá nhân).
  int get totalElements => _totalElements;

  Future<PageData<PostModel>> fetchPage(int page, int size);

  Future<void> refresh() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final PageData<PostModel> page = await fetchPage(0, ApiConfig.pageSize);
      items
        ..clear()
        ..addAll(page.content);
      _page = 0;
      _hasMore = page.hasMore;
      _totalElements = page.totalElements;
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || items.isEmpty) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final PageData<PostModel> page =
          await fetchPage(_page + 1, ApiConfig.pageSize);
      items.addAll(page.content);
      _page += 1;
      _hasMore = page.hasMore && page.content.isNotEmpty;
      _totalElements = page.totalElements;
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bày tỏ/bỏ cảm xúc rồi cập nhật lại bài viết trong danh sách.
  Future<void> toggleLike(PostModel post, String emojiType) async {
    final bool liked = await interactionService.toggleReaction(
      postId: post.id,
      type: emojiType,
    );
    final int delta = liked == post.liked ? 0 : (liked ? 1 : -1);
    final int newCount = post.likeCount + delta;
    replacePost(
      post.withReaction(
        liked: liked,
        likeCount: newCount < 0 ? 0 : newCount,
        myReaction: liked ? emojiType : null,
      ),
    );
  }

  Future<void> deletePost(String postId) async {
    await postService.deletePost(postId);
    final int before = items.length;
    items.removeWhere((PostModel item) => item.id == postId);
    if (items.length < before && _totalElements > 0) {
      _totalElements -= 1;
    }
    notifyListeners();
  }

  void replacePost(PostModel post) {
    final int index = items.indexWhere((PostModel item) => item.id == post.id);
    if (index == -1) {
      return;
    }
    items[index] = post;
    notifyListeners();
  }

  void prependPost(PostModel post) {
    items.insert(0, post);
    notifyListeners();
  }
}

/// Bảng tin: `GET /api/v1/posts`.
class FeedController extends PagedPostsController {
  FeedController({
    required super.postService,
    required super.interactionService,
    required super.session,
  });

  @override
  Future<PageData<PostModel>> fetchPage(int page, int size) {
    return postService.fetchFeed(page: page, size: size);
  }
}

/// Khám phá: `GET /api/v1/posts/trending?days=...`.
class TrendingController extends PagedPostsController {
  TrendingController({
    required super.postService,
    required super.interactionService,
    required super.session,
    this.days = 7,
  });

  int days;

  @override
  Future<PageData<PostModel>> fetchPage(int page, int size) {
    return postService.fetchTrending(page: page, size: size, days: days);
  }

  Future<void> changeDays(int value) async {
    if (value == days) {
      return;
    }
    days = value;
    items.clear();
    _page = 0;
    _hasMore = true;
    await refresh();
  }
}

/// Bài viết của một người dùng: `GET /api/v1/users/{id}/posts`.
class UserPostsController extends PagedPostsController {
  UserPostsController({
    required this.userId,
    required super.postService,
    required super.interactionService,
    required super.session,
  });

  final String userId;

  @override
  Future<PageData<PostModel>> fetchPage(int page, int size) {
    return postService.fetchUserPosts(userId, page: page, size: size);
  }
}
