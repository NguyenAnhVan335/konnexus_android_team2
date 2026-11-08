import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/avatar_view.dart';
import '../../../widgets/surface_card.dart';

/// Một kết quả tìm kiếm người dùng.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          AvatarView(
            name: user.displayName,
            imageUrl: user.avatarUrl,
            size: 42,
            showOnlineDot: true,
            isOnline: user.isOnline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: secondary),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
