import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/notifications_controller.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/state_views.dart';
import 'widgets/notification_tile.dart';

/// Thông báo — **dữ liệu mẫu** vì backend chưa có endpoint thông báo.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationsController? _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _controller =
        NotificationsController(AppScope.of(context).notificationService);
    _controller!.load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NotificationsController? controller = _controller;
    if (controller == null) {
      return const Scaffold(body: LoadingView());
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        return Scaffold(
          appBar: AppPageHeader(
            title: 'Thông báo',
            actions: <Widget>[
              if (controller.unreadCount > 0)
                TextButton(
                  onPressed: controller.markAllAsRead,
                  child: const Text('Đọc tất cả'),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
                if (controller.isLoading && controller.items.isEmpty)
                  const LoadingView(message: 'Đang tải thông báo...')
                else if (controller.items.isEmpty)
                  const EmptyView(
                    message: 'Bạn chưa có thông báo nào.',
                    icon: Icons.notifications_none,
                  )
                else
                  for (final item in controller.items)
                    NotificationTile(
                      item: item,
                      onTap: item.postId != null
                          ? () => _openPost(item.postId!)
                          : null,
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPost(String postId) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArgs(postId: postId),
    );
  }
}
