import 'package:flutter/material.dart';

import '../models/interaction_model.dart';
import '../models/post_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'media_gallery.dart';
import 'post_actions.dart';
import 'post_header.dart';

/// Thẻ bài viết theo wireframe: header xanh (tác giả + menu), thân trắng,
/// footer xanh (Cảm xúc / Bình luận / Chia sẻ).
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.authorName,
    this.authorAvatarUrl,
    this.onTap,
    this.onAuthorTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final PostModel post;
  final String? authorName;
  final String? authorAvatarUrl;
  final VoidCallback? onTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final EdgeInsetsGeometry margin;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final PostModel post = widget.post;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final String name = widget.authorName ?? post.author.displayName;
    final String? avatarUrl = widget.authorAvatarUrl ?? post.author.avatarUrl;
    final String content = (post.content ?? '').trim();
    final bool isLong = content.length > 260;

    return Container(
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PostHeader(
            post: post,
            name: name,
            avatarUrl: avatarUrl,
            onAuthorTap: widget.onAuthorTap,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          ),
          InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (content.isNotEmpty) ...<Widget>[
                    Text(
                      _expanded || !isLong
                          ? content
                          : '${content.substring(0, 260)}…',
                      style: TextStyle(
                          fontSize: 14, height: 1.45, color: textColor),
                    ),
                    if (isLong)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _expanded ? 'Thu gọn' : 'Xem thêm',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                  if (post.media.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    MediaGallery(items: post.media),
                  ],
                  if (_reactionSummary(post).isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: <Widget>[
                        for (final MapEntry<String, int> entry
                            in _reactionSummary(post).entries)
                          Text(
                            '${reactionEmojiText(entry.key)} ${entry.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                  if (post.edited)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Đã chỉnh sửa',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.showActions)
            PostActionsBar(
              likeCount: post.likeCount,
              commentCount: post.commentCount,
              liked: post.liked,
              reactionType: post.myReaction,
              onLike: widget.onLike,
              onComment: widget.onComment,
              onShare: widget.onShare,
            ),
        ],
      ),
    );
  }

  Map<String, int> _reactionSummary(PostModel post) {
    final ReactionSummary? summary = post.reactions;
    if (summary == null || summary.byType.isEmpty) {
      return const <String, int>{};
    }
    return summary.byType;
  }
}
