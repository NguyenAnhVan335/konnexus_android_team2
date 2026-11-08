import 'package:flutter/material.dart';

import '../../../models/chat_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/avatar_view.dart';
import '../../../widgets/surface_card.dart';

/// Một dòng cuộc trò chuyện trong danh sách Tin nhắn.
class ChatThreadTile extends StatelessWidget {
  const ChatThreadTile({super.key, required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final Color muted =
        isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          AvatarView(
            name: thread.participantName,
            imageUrl: thread.avatarUrl,
            size: 44,
            showOnlineDot: true,
            isOnline: thread.isOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        thread.participantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatRelativeTime(thread.lastMessageAt),
                      style: TextStyle(fontSize: 10.5, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: secondary),
                      ),
                    ),
                    if (thread.unreadCount > 0) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
