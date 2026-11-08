import 'package:flutter/material.dart';

import '../../../models/interaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/avatar_view.dart';
import '../../../widgets/post_actions.dart';

/// Một bình luận trong chi tiết bài viết, kèm cảm xúc / trả lời / sửa / xoá.
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.isOwn = false,
    this.parentAuthorName,
    this.onReact,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  final CommentModel comment;
  final bool isOwn;
  final String? parentAuthorName;
  final VoidCallback? onReact;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted =
        isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    final Color primary = Theme.of(context).colorScheme.primary;
    final String avatarUrl = comment.author?.avatarUrl ?? '';
    final String authorName = comment.author?.displayName ?? 'Người dùng';
    final bool reacted = comment.myReaction != null;
    final String reactLabel = comment.reactionCount > 0
        ? '${reactionEmojiText(comment.myReaction)} ${comment.reactionCount}'
        : 'Cảm xúc';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AvatarView(name: authorName, imageUrl: avatarUrl, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (isOwn)
                            PopupMenuButton<String>(
                              tooltip: 'Tuỳ chọn',
                              icon: Icon(Icons.more_horiz,
                                  size: 16, color: muted),
                              padding: EdgeInsets.zero,
                              onSelected: (String value) {
                                if (value == 'edit') {
                                  onEdit?.call();
                                } else if (value == 'delete') {
                                  onDelete?.call();
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                if (onEdit != null)
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Chỉnh sửa bình luận'),
                                  ),
                                if (onDelete != null)
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Xoá bình luận'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      if (comment.isReply) ...<Widget>[
                        Text(
                          parentAuthorName != null
                              ? 'Trả lời @$parentAuthorName'
                              : 'Trả lời',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        comment.content,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      formatRelativeTime(comment.createdAt),
                      style: TextStyle(fontSize: 10.5, color: muted),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: onReact,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          reactLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                reacted ? FontWeight.w700 : FontWeight.w500,
                            color: reacted ? primary : muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: onReply,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Trả lời',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ),
                    ),
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
