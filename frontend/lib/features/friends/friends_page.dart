import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/friendship_model.dart';
import '../../models/user_model.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/friends_controller.dart';
import '../../state/messages_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/state_views.dart';
import 'widgets/friend_tile.dart';

/// Bạn bè: số người online, lời mời kết bạn, danh sách bạn bè.
///
/// Dữ liệu lấy từ Friendship API (`/api/friends`) — backend chỉ chấp nhận header
/// `X-Test-User-Id` khi chạy dev/test; production sẽ trả 403.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  FriendsController? _controller;
  MessagesController? _messages;
  bool _initialized = false;
  int _tabIndex = 0;

  static const List<String> _tabs = <String>['Bạn bè', 'Lời mời', 'Đã gửi'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final services = AppScope.of(context);
    _controller = FriendsController(
      friendshipService: services.friendshipService,
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

  String? get _currentUserId => AppScope.of(context).session.userId;

  Future<void> _runAction(
      Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (mounted) {
        showAppSnackBar(context, successMessage);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
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

  @override
  Widget build(BuildContext context) {
    final FriendsController? controller = _controller;
    if (controller == null) {
      return const Scaffold(body: LoadingView());
    }
    return Scaffold(
      appBar: KonexusAppBar(
        title: 'Bạn bè',
        onAvatarTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          if (controller.isLoading && controller.friends.isEmpty) {
            return const LoadingView(message: 'Đang tải danh sách bạn bè...');
          }
          if (controller.error != null &&
              controller.friends.isEmpty &&
              controller.received.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => controller.load(force: true),
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 40),
                  ErrorView(
                    message: controller.error!,
                    onRetry: () => controller.load(force: true),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => controller.load(force: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatBlock(
                        value: '${controller.onlineCount}',
                        label: 'Online',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatBlock(
                        value: '${controller.received.length}',
                        label: 'Lời mời',
                        onTap: () => setState(() => _tabIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatBlock(
                        value: '${controller.friends.length}',
                        label: 'Bạn bè',
                        onTap: () => setState(() => _tabIndex = 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (int index = 0; index < _tabs.length; index++)
                      ChoiceChip(
                        label: Text(_tabs[index]),
                        selected: _tabIndex == index,
                        onSelected: (_) => setState(() => _tabIndex = index),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.isBusy)
                  const LoadingView(message: 'Đang cập nhật...'),
                if (_tabIndex == 0) ..._buildFriends(controller),
                if (_tabIndex == 1)
                  ..._buildRequests(controller, isReceived: true),
                if (_tabIndex == 2)
                  ..._buildRequests(controller, isReceived: false),
                const SizedBox(height: 8),
                if (controller.error != null)
                  Text(
                    controller.error!,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.danger),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFriends(FriendsController controller) {
    if (controller.friends.isEmpty) {
      return const <Widget>[
        EmptyView(
          message: 'Chưa có người bạn nào. Hãy tìm và kết bạn nhé!',
          icon: Icons.people_outline,
        ),
      ];
    }
    return <Widget>[
      for (final FriendshipModel friendship in controller.friends)
        _friendTile(
          controller,
          friendship,
          subtitle: 'Bạn bè',
          actions: _friendActions(controller, friendship),
        ),
    ];
  }

  Widget _friendTile(
    FriendsController controller,
    FriendshipModel friendship, {
    required String subtitle,
    required List<Widget> actions,
  }) {
    final String? currentUserId = _currentUserId;
    return FriendTile(
      user: controller.userOf(friendship),
      fallbackName: 'Người dùng ${friendship.otherUserId(currentUserId ?? '')}',
      subtitle: subtitle,
      actions: actions,
    );
  }

  List<Widget> _friendActions(
    FriendsController controller,
    FriendshipModel friendship,
  ) {
    final UserModel? user = controller.userOf(friendship);
    return <Widget>[
      IconButton(
        tooltip: 'Nhắn tin',
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        onPressed: user == null ? null : () => _openChat(user),
      ),
      IconButton(
        tooltip: 'Trang cá nhân',
        icon: const Icon(Icons.person_outline, size: 20),
        onPressed: user == null
            ? null
            : () => Navigator.of(context).pushNamed(
                  AppRoutes.profile,
                  arguments: ProfileArgs(userId: user.id),
                ),
      ),
      PopupMenuButton<String>(
        tooltip: 'Khác',
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (_) => _runAction(
          () => controller.unfriend(friendship),
          'Đã bỏ kết bạn',
        ),
        itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
          PopupMenuItem<String>(value: 'unfriend', child: Text('Bỏ kết bạn')),
        ],
      ),
    ];
  }

  List<Widget> _buildRequests(
    FriendsController controller, {
    required bool isReceived,
  }) {
    final List<FriendshipModel> items =
        isReceived ? controller.received : controller.sent;
    if (items.isEmpty) {
      return <Widget>[
        EmptyView(
          message: isReceived
              ? 'Không có lời mời kết bạn nào.'
              : 'Bạn chưa gửi lời mời nào.',
          icon: Icons.mail_outline,
        ),
      ];
    }
    return <Widget>[
      for (final FriendshipModel friendship in items)
        _friendTile(
          controller,
          friendship,
          subtitle: friendship.statusLabel ??
              (isReceived ? 'Muốn kết bạn với bạn' : 'Đang chờ phản hồi'),
          actions: isReceived
              ? _receivedActions(controller, friendship)
              : _sentActions(controller, friendship),
        ),
    ];
  }

  List<Widget> _receivedActions(
    FriendsController controller,
    FriendshipModel friendship,
  ) {
    return <Widget>[
      SizedBox(
        height: 32,
        child: FilledButton(
          onPressed: controller.isBusy
              ? null
              : () => _runAction(
                    () => controller.accept(friendship),
                    'Đã chấp nhận lời mời kết bạn',
                  ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Chấp nhận', style: TextStyle(fontSize: 12)),
        ),
      ),
      TextButton(
        onPressed: controller.isBusy
            ? null
            : () => _runAction(
                  () => controller.reject(friendship),
                  'Đã từ chối lời mời kết bạn',
                ),
        child: const Text('Từ chối', style: TextStyle(fontSize: 12)),
      ),
    ];
  }

  List<Widget> _sentActions(
    FriendsController controller,
    FriendshipModel friendship,
  ) {
    return <Widget>[
      SizedBox(
        height: 32,
        child: OutlinedButton(
          onPressed: controller.isBusy
              ? null
              : () => _runAction(
                    () => controller.cancel(friendship),
                    'Đã huỷ lời mời kết bạn',
                  ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Huỷ', style: TextStyle(fontSize: 12)),
        ),
      ),
    ];
  }
}
