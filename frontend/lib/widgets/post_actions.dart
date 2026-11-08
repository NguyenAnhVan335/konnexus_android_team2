import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Emoji hiển thị cho một `emojiType` do backend trả về.
String reactionEmojiText(String? type) {
  switch ((type ?? '').toUpperCase()) {
    case 'LOVE':
      return '❤️';
    case 'HAHA':
      return '😆';
    case 'WOW':
      return '😮';
    case 'SAD':
      return '😢';
    case 'ANGRY':
      return '😡';
    default:
      return '👍';
  }
}

/// Footer xanh của thẻ bài viết: Cảm xúc / Bình luận / Chia sẻ.
class PostActionsBar extends StatelessWidget {
  const PostActionsBar({
    super.key,
    required this.likeCount,
    required this.commentCount,
    required this.liked,
    this.reactionType,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  final int likeCount;
  final int commentCount;
  final bool liked;
  final String? reactionType;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final Color background = Theme.of(context).colorScheme.primary;
    return Container(
      color: background,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _PostAction(
              emoji: liked ? reactionEmojiText(reactionType) : null,
              icon: liked ? null : Icons.thumb_up_alt_outlined,
              label: likeCount > 0
                  ? 'Cảm xúc ${formatCount(likeCount)}'
                  : 'Cảm xúc',
              onTap: onLike,
              isActive: liked,
            ),
          ),
          Expanded(
            child: _PostAction(
              icon: Icons.mode_comment_outlined,
              label: commentCount > 0
                  ? 'Bình luận ${formatCount(commentCount)}'
                  : 'Bình luận',
              onTap: onComment,
            ),
          ),
          Expanded(
            child: _PostAction(
              icon: Icons.share_outlined,
              label: 'Chia sẻ',
              onTap: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    this.icon,
    this.emoji,
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  final IconData? icon;
  final String? emoji;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isActive ? Colors.white : Colors.white70;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 16))
            else if (icon != null)
              Icon(icon, size: 17, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: foreground,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
