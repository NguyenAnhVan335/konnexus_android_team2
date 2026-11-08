import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/post_model.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/paged_posts_controller.dart';
import '../../state/users_directory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/reaction_picker.dart';
import '../../widgets/state_views.dart';
import '../../utils/share_utils.dart';

/// Khám phá: bài viết nổi bật theo tương tác trong N ngày (Post API trending).
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  TrendingController? _trending;
  bool _initialized = false;

  static const List<int> _dayOptions = <int>[7, 30, 365];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final services = AppScope.of(context);
    _trending = TrendingController(
      postService: services.postService,
      interactionService: services.interactionService,
      session: services.session,
    );
    _trending!.refresh();
    services.usersDirectory.ensureLoaded();
  }

  @override
  void dispose() {
    _trending?.dispose();
    super.dispose();
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
      await _trending?.toggleLike(post, type);
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
    final TrendingController? trending = _trending;
    if (trending == null) {
      return const Scaffold(body: LoadingView());
    }
    final UsersDirectory directory = AppScope.of(context).usersDirectory;
    return Scaffold(
      appBar: KonexusAppBar(
        title: 'Khám phá',
        onAvatarTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
      ),
      body: RefreshIndicator(
        onRefresh: trending.refresh,
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[trending, directory]),
          builder: (BuildContext context, Widget? _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
                Text(
                  'Bài viết nổi bật trong ${trending.days} ngày gần nhất, '
                  'xếp theo số cảm xúc và bình luận.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final int days in _dayOptions)
                      ChoiceChip(
                        label: Text(days == 365 ? '1 năm' : '$days ngày'),
                        selected: trending.days == days,
                        onSelected: (bool selected) {
                          if (selected) {
                            trending.changeDays(days);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (trending.isLoading && trending.isEmpty)
                  const LoadingView(message: 'Đang tải bài viết nổi bật...')
                else if (trending.error != null && trending.isEmpty)
                  ErrorView(message: trending.error!, onRetry: trending.refresh)
                else if (trending.isEmpty)
                  EmptyView(
                    message:
                        'Chưa có bài viết nổi bật trong khoảng thời gian này.',
                    icon: Icons.local_fire_department_outlined,
                    actionLabel: 'Tải lại',
                    onAction: trending.refresh,
                  )
                else ...<Widget>[
                  for (final PostModel post in trending.items)
                    PostCard(
                      post: post,
                      authorName: directory.find(post.author.id)?.displayName,
                      authorAvatarUrl:
                          directory.find(post.author.id)?.avatarUrl,
                      onTap: () => _openDetail(post),
                      onAuthorTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.profile,
                        arguments: ProfileArgs(userId: post.author.id),
                      ),
                      onLike: () => _pickReaction(post),
                      onComment: () => _openDetail(post),
                      onShare: () => _share(post),
                    ),
                  if (trending.isLoading)
                    const LoadingView(message: 'Đang tải thêm...'),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openDetail(PostModel post) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArgs(postId: post.id, initialPost: post),
    );
    if (!mounted) {
      return;
    }
    await _trending?.refresh();
  }
}
