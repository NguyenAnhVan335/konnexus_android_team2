import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/avatar_view.dart';
import '../../../widgets/surface_card.dart';

/// Một dòng người dùng trong danh sách bạn bè / lời mời kết bạn.
class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.user,
    required this.fallbackName,
    required this.actions,
    this.subtitle,
  });

  final UserModel? user;
  final String fallbackName;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          AvatarView(
            name: user?.displayName ?? fallbackName,
            imageUrl: user?.avatarUrl,
            size: 44,
            showOnlineDot: true,
            isOnline: user?.isOnline ?? false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user?.displayName ?? fallbackName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
