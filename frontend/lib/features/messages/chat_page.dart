import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../models/chat_model.dart';
import '../../navigation/app_arguments.dart';
import '../../state/messages_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/state_views.dart';
import 'widgets/message_bubble.dart';

/// Màn hình trò chuyện (dữ liệu mẫu vì backend chưa có API chat).
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.args});

  final ChatArgs args;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  MessagesController? _controller;
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _initialized = false;
  bool _isSending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _controller = MessagesController(AppScope.of(context).chatService);
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final MessagesController? controller = _controller;
    if (controller == null) {
      return;
    }
    final List<ChatMessage> messages =
        await controller.loadMessages(widget.args.thread.id);
    if (!mounted) {
      return;
    }
    setState(() => _messages = messages);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final String text = _textController.text.trim();
    final MessagesController? controller = _controller;
    if (text.isEmpty || _isSending || controller == null) {
      return;
    }
    setState(() => _isSending = true);
    try {
      final ChatMessage message = await controller.sendMessage(
        widget.args.thread.id,
        text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = <ChatMessage>[..._messages, message];
        _textController.clear();
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _insertEmoji() {
    final String text = '${_textController.text}😊';
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChatThread thread = widget.args.thread;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            AvatarView(
              name: thread.participantName,
              imageUrl: thread.avatarUrl,
              size: 32,
              showOnlineDot: true,
              isOnline: thread.isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    thread.participantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    thread.isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _messages.isEmpty
                ? const EmptyView(
                    message: 'Chưa có tin nhắn nào. Hãy gửi lời chào!',
                    icon: Icons.forum_outlined,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) =>
                        MessageBubble(message: _messages[index]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Emoji',
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: _insertEmoji,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Gửi',
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
