import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/post_search_controller.dart';
import '../../state/search_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/surface_card.dart';
import 'widgets/search_result_tile.dart';

/// Tìm kiếm người dùng.
///
/// Backend chưa có endpoint tìm kiếm: dữ liệu lấy từ `GET /api/users` và lọc
/// phía client theo tên/email, trạng thái online và danh sách bạn bè.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _queryController = TextEditingController();
  UserSearchController? _controller;
  PostSearchController? _postSearch;
  bool _initialized = false;
  int _tabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final services = AppScope.of(context);
    _controller = UserSearchController(
      directory: services.usersDirectory,
      friendshipService: services.friendshipService,
      session: services.session,
      store: services.preferencesStore,
    );
    _postSearch = PostSearchController(services.postService);
    _controller!.load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _controller?.dispose();
    _postSearch?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserSearchController? controller = _controller;
    final PostSearchController? postSearch = _postSearch;
    if (controller == null || postSearch == null) {
      return const Scaffold(body: LoadingView());
    }
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Scaffold(
      appBar: const AppPageHeader(title: 'Tìm kiếm'),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[controller, postSearch]),
        builder: (BuildContext context, Widget? _) {
          final List<UserModel> results = controller.results;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: <Widget>[
              TextField(
                controller: _queryController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (String value) {
                  controller.updateQuery(value);
                  postSearch.search(value);
                },
                decoration: InputDecoration(
                  hintText: 'Tìm người dùng hoặc bài viết',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: controller.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Lưu từ khoá',
                          icon:
                              const Icon(Icons.bookmark_add_outlined, size: 20),
                          onPressed: () async {
                            await controller.saveCurrentQuery();
                            if (context.mounted) {
                              showAppSnackBar(
                                  context, 'Đã lưu từ khoá tìm kiếm');
                            }
                          },
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Người dùng'),
                    selected: _tabIndex == 0,
                    onSelected: (_) => setState(() => _tabIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Bài viết'),
                    selected: _tabIndex == 1,
                    onSelected: (_) => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_tabIndex == 0) ...<Widget>[
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilterChip(
                      label: const Text('Đang online'),
                      selected: controller.onlineOnly,
                      onSelected: controller.setOnlineOnly,
                    ),
                    FilterChip(
                      label: const Text('Bạn bè'),
                      selected: controller.friendsOnly,
                      onSelected: controller.setFriendsOnly,
                    ),
                  ],
                ),
                if (controller.savedSearches.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                const SectionHeading(title: 'Từ khoá đã lưu'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final String keyword in controller.savedSearches)
                      InputChip(
                        label: Text(keyword),
                        onPressed: () {
                          _queryController.text = keyword;
                          controller.updateQuery(keyword);
                        },
                        onDeleted: () => controller.removeSavedQuery(keyword),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (controller.isLoading && results.isEmpty)
                const LoadingView(message: 'Đang tải danh sách người dùng...')
              else if (controller.error != null && results.isEmpty)
                ErrorView(message: controller.error!, onRetry: controller.load)
              else if (results.isEmpty)
                EmptyView(
                  message: controller.query.isEmpty
                      ? 'Chưa có người dùng nào để hiển thị.'
                      : 'Không tìm thấy người dùng phù hợp với "${controller.query}".',
                  icon: Icons.search_off,
                )
              else ...<Widget>[
                Text(
                  '${results.length} kết quả',
                  style: TextStyle(fontSize: 11.5, color: secondary),
                ),
                const SizedBox(height: 8),
                for (final UserModel user in results)
                  SearchResultTile(
                    user: user,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.profile,
                      arguments: ProfileArgs(userId: user.id),
                    ),
                  ),
              ],
              ] else ...<Widget>[
                if (postSearch.keyword.isEmpty)
                  const EmptyView(
                    message: 'Nhập từ khoá để tìm bài viết.',
                    icon: Icons.article_outlined,
                  )
                else if (postSearch.isLoading && postSearch.items.isEmpty)
                  const LoadingView(message: 'Đang tìm bài viết...')
                else if (postSearch.error != null && postSearch.items.isEmpty)
                  ErrorView(
                    message: postSearch.error!,
                    onRetry: () => postSearch.search(postSearch.keyword),
                  )
                else if (postSearch.items.isEmpty)
                  EmptyView(
                    message:
                        'Không tìm thấy bài viết nào phù hợp với "${postSearch.keyword}".',
                    icon: Icons.search_off,
                  )
                else
                  for (final PostModel post in postSearch.items)
                    PostCard(
                      post: post,
                      showActions: false,
                      onTap: () => _openDetail(post),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDetail(PostModel post) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArgs(postId: post.id, initialPost: post),
    );
  }
}
