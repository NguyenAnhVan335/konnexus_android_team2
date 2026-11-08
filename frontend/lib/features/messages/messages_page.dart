import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../models/chat_model.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/messages_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/state_views.dart';
import 'widgets/chat_thread_tile.dart';

/// Danh sách cuộc trò chuyện.
///
/// **Dữ liệu mẫu**: backend chưa có API tin nhắn (xem `MockChatService`).
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  MessagesController? _controller;
  bool _initialized = false;
  String _keyword = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _controller = MessagesController(AppScope.of(context).chatService);
    _controller!.loadThreads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MessagesController? controller = _controller;
    if (controller == null) {
      return const Scaffold(body: LoadingView());
    }
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: KonexusAppBar(
        title: 'Tin nhắn',
        onAvatarTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final List<ChatThread> threads = controller.threads
              .where(
                (ChatThread thread) =>
                    _keyword.isEmpty ||
                    thread.participantName
                        .toLowerCase()
                        .contains(_keyword.toLowerCase()),
              )
              .toList(growable: false);
          return RefreshIndicator(
            onRefresh: controller.loadThreads,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: (String value) =>
                      setState(() => _keyword = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Tìm cuộc trò chuyện',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _keyword.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _keyword = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.isLoading && threads.isEmpty)
                  const LoadingView(message: 'Đang tải cuộc trò chuyện...')
                else if (threads.isEmpty)
                  EmptyView(
                    message: _keyword.isEmpty
                        ? 'Chưa có cuộc trò chuyện nào.'
                        : 'Không tìm thấy cuộc trò chuyện phù hợp.',
                    icon: Icons.chat_bubble_outline,
                  )
                else
                  for (final ChatThread thread in threads)
                    ChatThreadTile(
                      thread: thread,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.chat,
                        arguments: ChatArgs(thread: thread),
                      ),
                    ),
                const SizedBox(height: 8),
                Text(
                  'Gợi ý: mở Bạn bè → "Nhắn tin" để bắt đầu cuộc trò chuyện mới.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
