import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/friendship_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/messages_controller.dart';
import '../../state/profile_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/reaction_picker.dart';
import '../../widgets/state_views.dart';
import '../../widgets/surface_card.dart';
import '../../utils/share_utils.dart';
import 'widgets/profile_action_panel.dart';
import 'widgets/profile_summary.dart';

/// Trang cá nhân: dùng cho chính mình (tab Cá nhân) hoặc người dùng khác
/// (điều hướng kèm [ProfileArgs]).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});

  /// `null` nghĩa là trang cá nhân của người đang đăng nhập.
  final String? userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileController? _controller;
  MessagesController? _messages;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final services = AppScope.of(context);
    final String userId = widget.userId ?? services.session.userId ?? '';
    _controller = ProfileController(
      userId: userId,
      userService: services.userService,
      friendshipService: services.friendshipService,
      postService: services.postService,
      interactionService: services.interactionService,
      directory: services.usersDirectory,
      session: services.session,
    );
    _messages = MessagesController(services.chatService);
    _controller!.load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _messages?.dispose();
    super.dispose();
  }

  Future<void> _runAction(
      Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted) {
        showAppSnackBar(context, success);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _pickReaction(
      ProfileController controller, PostModel post) async {
    final String? type = await showReactionPicker(
      context,
      currentType: post.myReaction,
    );
    if (type == null || !mounted) {
      return;
    }
    try {
      await controller.toggleLike(post, type);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _openDetail(PostModel post) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArgs(postId: post.id, initialPost: post),
    );
    if (mounted) {
      await _controller?.refreshPosts();
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
    await _controller?.refreshPosts();
    if (!mounted) {
      return;
    }
    showAppSnackBar(
        context, post == null ? 'Đã đăng bài viết' : 'Đã cập nhật bài viết');
  }

  Future<void> _deletePost(ProfileController controller, PostModel post) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Xoá bài viết',
      message: 'Bài viết sẽ bị xoá mềm trên máy chủ. Bạn chắc chắn?',
      confirmLabel: 'Xoá',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await controller.deletePost(post.id);
      if (mounted) {
        showAppSnackBar(context, 'Đã xoá bài viết');
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _shareProfile(UserModel user) async {
    try {
      await shareUser(user);
    } catch (_) {
      // Bỏ qua khi không có app nhận share.
    }
  }

  Future<void> _sharePost(PostModel post) async {
    try {
      await sharePost(post);
    } catch (_) {
      // Bỏ qua khi không có app nhận share.
    }
  }

  Future<void> _openChat(UserModel user) async {
    final MessagesController? messages = _messages;
    if (messages == null) {
      return;
    }
    final thread = await messages.ensureDirect(
      userId: user.id,
      name: user.displayName,
      avatarUrl: user.avatarUrl,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context)
        .pushNamed(AppRoutes.chat, arguments: ChatArgs(thread: thread));
  }

  Widget _relationshipButton(ProfileController controller) {
    if (controller.isBusy) {
      return const AppButton(label: 'Đang xử lý...', isLoading: true);
    }
    final RelationshipStatus status =
        controller.relationship?.status ?? RelationshipStatus.none;
    switch (status) {
      case RelationshipStatus.none:
        return AppButton(
          label: 'Thêm bạn bè',
          icon: Icons.person_add_alt_1_outlined,
          onPressed: () => _runAction(
            controller.sendFriendRequest,
            'Đã gửi lời mời kết bạn',
          ),
        );
      case RelationshipStatus.requestSent:
        return AppButton(
          label: 'Huỷ lời mời',
          icon: Icons.close,
          variant: AppButtonVariant.outlined,
          onPressed: () => _runAction(
            controller.cancelFriendRequest,
            'Đã huỷ lời mời kết bạn',
          ),
        );
      case RelationshipStatus.requestReceived:
        return AppButton(
          label: 'Chấp nhận lời mời',
          icon: Icons.check,
          onPressed: () => _runAction(
            controller.acceptFriendRequest,
            'Đã chấp nhận lời mời kết bạn',
          ),
        );
      case RelationshipStatus.friends:
        return AppButton(
          label: 'Bỏ kết bạn',
          icon: Icons.person_remove_outlined,
          variant: AppButtonVariant.outlined,
          onPressed: () => _runAction(controller.unfriend, 'Đã bỏ kết bạn'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProfileController? controller = _controller;
    if (controller == null) {
      return const Scaffold(body: LoadingView());
    }
    final bool isOwn = controller.isOwnProfile;
    final PreferredSizeWidget appBar = isOwn
        ? const KonexusAppBar(showAvatar: false)
        : const AppPageHeader(title: 'Trang cá nhân');
    return Scaffold(
      appBar: appBar,
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[controller, controller.posts]),
        builder: (BuildContext context, Widget? _) {
          if (controller.isLoading && controller.user == null) {
            return const LoadingView(message: 'Đang tải trang cá nhân...');
          }
          if (controller.error != null && controller.user == null) {
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 40),
                  ErrorView(
                      message: controller.error!, onRetry: controller.load),
                ],
              ),
            );
          }
          final UserModel? user = controller.user;
          if (user == null) {
            return const EmptyView(message: 'Không tìm thấy người dùng này.');
          }
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
                ProfileSummary(
                  user: user,
                  isOwn: isOwn,
                  postCount: controller.posts.totalElements,
                  friendCount: controller.friendCount,
                  address: isOwn ? AppScope.of(context).session.address : null,
                  relationship: controller.relationship,
                ),
                const SizedBox(height: 12),
                ProfileActionPanel(
                  isOwn: isOwn,
                  relationshipButton: _relationshipButton(controller),
                  onEdit: () =>
                      Navigator.of(context).pushNamed(AppRoutes.editProfile),
                  onSettings: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                  onCreatePost: () => _openComposer(),
                  onShare: () => _shareProfile(user),
                  onMessage: () => _openChat(user),
                ),
                if (controller.relationshipWarning != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    controller.relationshipWarning!,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ],
                const SizedBox(height: 18),
                SectionHeading(
                    title: 'Bài viết (${controller.posts.totalElements})'),
                if (controller.posts.isLoading && controller.posts.isEmpty)
                  const LoadingView(message: 'Đang tải bài viết...')
                else if (controller.posts.error != null &&
                    controller.posts.isEmpty)
                  ErrorView(
                    message: controller.posts.error!,
                    onRetry: controller.refreshPosts,
                  )
                else if (controller.posts.isEmpty)
                  EmptyView(
                    message: isOwn
                        ? 'Bạn chưa có bài viết nào.'
                        : '${user.displayName} chưa có bài viết nào.',
                    icon: Icons.article_outlined,
                    actionLabel: isOwn ? 'Tạo bài viết' : null,
                    onAction: isOwn ? () => _openComposer() : null,
                  )
                else
                  for (final PostModel post in controller.posts.items)
                    PostCard(
                      post: post,
                      onTap: () => _openDetail(post),
                      onLike: () => _pickReaction(controller, post),
                      onComment: () => _openDetail(post),
                      onShare: () => _sharePost(post),
                      onEdit: isOwn ? () => _openComposer(post) : null,
                      onDelete:
                          isOwn ? () => _deletePost(controller, post) : null,
                    ),
                if (controller.posts.isLoading &&
                    controller.posts.items.isNotEmpty)
                  const LoadingView(message: 'Đang tải thêm...'),
              ],
            ),
          );
        },
      ),
    );
  }
}
