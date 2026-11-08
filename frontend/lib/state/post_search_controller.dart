import 'app_change_notifier.dart';

import '../core/api/api_exception.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

/// Tìm kiếm bài viết theo từ khóa (server-side).
class PostSearchController extends AppChangeNotifier {
  PostSearchController(this._postService);

  final PostService _postService;

  List<PostModel> _items = <PostModel>[];
  bool _isLoading = false;
  String? _error;
  String _keyword = '';

  List<PostModel> get items => _items;

  bool get isLoading => _isLoading;

  String? get error => _error;

  String get keyword => _keyword;

  Future<void> search(String keyword) async {
    final String kw = keyword.trim();
    if (kw.isEmpty) {
      _items = <PostModel>[];
      _keyword = '';
      _error = null;
      notifyListeners();
      return;
    }
    _keyword = kw;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await _postService.searchPosts(kw);
      _items = page.content;
    } on ApiException catch (error) {
      _error = error.userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
