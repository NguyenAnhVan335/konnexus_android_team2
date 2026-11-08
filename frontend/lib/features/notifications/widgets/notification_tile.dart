import 'package:flutter/material.dart';

import '../../../models/notification_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/surface_card.dart';

/// Một dòng thông báo (dữ liệu mẫu).
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item, this.onTap});

  final NotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      color: item.isRead
          ? null
          : Theme.of(context).colorScheme.primary.withAlpha(isDark ? 30 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child:
                Icon(_iconFor(item.kind), size: 18, color: AppColors.primary),
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
                        item.title,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatRelativeTime(item.createdAt),
                      style: TextStyle(fontSize: 10.5, color: secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style:
                      TextStyle(fontSize: 12.5, height: 1.4, color: secondary),
                ),
              ],
            ),
          ),
          if (!item.isRead)
            Container(
              margin: const EdgeInsets.only(left: 6, top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.like:
        return Icons.favorite_border;
      case NotificationKind.comment:
        return Icons.mode_comment_outlined;
      case NotificationKind.friendRequest:
        return Icons.person_add_alt_1_outlined;
      case NotificationKind.system:
        return Icons.campaign_outlined;
    }
  }
}
