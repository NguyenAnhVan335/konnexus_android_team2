import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/paged_posts_controller.dart';
import '../../state/session_controller.dart';
import '../../state/users_directory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/reaction_picker.dart';
import '../../widgets/state_views.dart';
import '../../widgets/surface_card.dart';
import '../../utils/share_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  FeedController? _feed;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final services = AppScope.of(context);
    _feed = FeedController(
      postService: services.postService,
      interactionService: services.interactionService,
      session: services.session,
    );
    _scrollController.addListener(_onScroll);
    _feed!.refresh();
    services.usersDirectory.ensureLoaded();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _feed?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final FeedController? feed = _feed;
    if (feed == null || !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 280) {
      feed.loadMore();
    }
  }

  Future<void> _refresh() async {
    await _feed?.refresh();
    if (mounted) {
      await AppScope.of(context).usersDirectory.ensureLoaded(force: true);
    }
  }

  Future<void> _openComposer([PostModel? post]) async {
    final Object? result = await Navigator.of(context).pushNamed(
      AppRoutes.postComposer,
      arguments: PostComposerArgs(post: post),
    );
    if (!mounted || result is! PostModel) {
      return;
    }
    final FeedController? feed = _feed;
    if (feed == null) {
      return;
    }
    final int index =
        feed.items.indexWhere((PostModel item) => item.id == result.id);
    if (index >= 0) {
      feed.replacePost(result);
    } else {
      feed.prependPost(result);
    }
    showAppSnackBar(
        context, post == null ? 'Đã đăng bài viết' : 'Đã cập nhật bài viết');
  }

  Future<void> _openDetail(PostModel post) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArgs(postId: post.id, initialPost: post),
    );
    if (!mounted) {
      return;
    }
    await _feed?.refresh();
  }

  Future<void> _pickReaction(PostModel post) async {
    final String? type = await showReactionPicker(
      context,
      currentType: post.myReaction,
    );
    if (type == null || !mounted) {
      return;
    }
    try {
      await _feed?.toggleLike(post, type);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _delete(PostModel post) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Xoá bài viết',
      message:
          'Bài viết sẽ bị xoá mềm trên máy chủ và không còn hiển thị. Bạn chắc chắn?',
      confirmLabel: 'Xoá',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await _feed?.deletePost(post.id);
      if (mounted) {
        showAppSnackBar(context, 'Đã xoá bài viết');
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _share(PostModel post) async {
    try {
      await sharePost(post);
    } catch (_) {
      // Bỏ qua khi không có app nhận share.
    }
  }

  @override
  Widget build(BuildContext context) {
    final FeedController? feed = _feed;
    if (feed == null) {
      return const Scaffold(body: LoadingView());
    }
    final UsersDirectory directory = AppScope.of(context).usersDirectory;
    return Scaffold(
      appBar: KonexusAppBar(
        showCreatePost: true,
        onCreatePost: _openComposer,
        onAvatarTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[feed, directory]),
          builder: (BuildContext context, Widget? _) {
            if (feed.isLoading && feed.isEmpty) {
              return ListView(
                children: const <Widget>[
                  SizedBox(height: 90),
                  LoadingView(message: 'Đang tải bảng tin...'),
                ],
              );
            }
            if (feed.error != null && feed.isEmpty) {
              return ListView(
                children: <Widget>[
                  const SizedBox(height: 48),
                  ErrorView(message: feed.error!, onRetry: feed.refresh),
                ],
              );
            }
            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
                const _ComposerPrompt(),
                const SizedBox(height: 12),
                if (feed.isEmpty)
                  EmptyView(
                    message:
                        'Chưa có bài viết nào. Hãy đăng bài đầu tiên của bạn!',
                    icon: Icons.article_outlined,
                    actionLabel: 'Tạo bài viết',
                    onAction: _openComposer,
                  )
                else
                  for (final PostModel post in feed.items)
                    _buildPost(context, post, feed),
                if (feed.isLoading && feed.items.isNotEmpty)
                  const LoadingView(message: 'Đang tải thêm...'),
                if (!feed.hasMore && feed.items.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        'Bạn đã xem hết bài viết',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPost(BuildContext context, PostModel post, FeedController feed) {
    final services = AppScope.of(context);
    final UserModel? author = services.usersDirectory.find(post.author.id);
    final bool isOwner = post.author.id == services.session.userId;
    return PostCard(
      post: post,
      authorName: author?.displayName ?? post.author.displayName,
      authorAvatarUrl: author?.avatarUrl ?? post.author.avatarUrl,
      onTap: () => _openDetail(post),
      onAuthorTap: () => Navigator.of(context).pushNamed(
        AppRoutes.profile,
        arguments: ProfileArgs(userId: post.author.id),
      ),
      onLike: () => _pickReaction(post),
      onComment: () => _openDetail(post),
      onShare: () => _share(post),
      onEdit: isOwner ? () => _openComposer(post) : null,
      onDelete: isOwner ? () => _delete(post) : null,
    );
  }
}

class _ComposerPrompt extends StatelessWidget {
  const _ComposerPrompt();

  @override
  Widget build(BuildContext context) {
    final SessionController session = AppScope.of(context).session;
    final Color primary = Theme.of(context).colorScheme.primary;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.postComposer),
      child: Row(
        children: <Widget>[
          AvatarView(
              name: session.displayName, imageUrl: session.avatarUrl, size: 34),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bạn đang nghĩ gì?',
              style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
            ),
          ),
          Icon(Icons.edit_outlined, size: 17, color: primary),
          const SizedBox(width: 4),
          Text(
            'Tạo bài viết',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: primary),
          ),
        ],
      ),
    );
  }
}
