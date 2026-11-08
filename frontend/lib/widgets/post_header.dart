import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../utils/formatters.dart';
import 'avatar_view.dart';
import 'privacy_icon.dart';

/// Phần đầu thẻ bài viết (nền màu chủ đạo): avatar, tên, thời gian, quyền riêng tư
/// và menu "Phân mở rộng" cho chủ bài viết.
class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.post,
    required this.name,
    this.avatarUrl,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
  });

  final PostModel post;
  final String name;
  final String? avatarUrl;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: <Widget>[
          AvatarView(
              name: name, imageUrl: avatarUrl, size: 36, onTap: onAuthorTap),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        formatRelativeTime(post.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(privacyIcon(post.privacy),
                        size: 12, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text(
                      post.privacy.label,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              tooltip: 'Phân mở rộng',
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onSelected: (String value) {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (onEdit != null)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Chỉnh sửa bài viết'),
                  ),
                if (onDelete != null)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Xoá bài viết'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
