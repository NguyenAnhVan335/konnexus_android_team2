import 'package:flutter/material.dart';

import '../../../models/friendship_model.dart';
import '../../../models/user_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/avatar_view.dart';
import '../../../widgets/surface_card.dart';

/// Khối thông tin đầu trang cá nhân: avatar, tên, mô tả, địa chỉ, thống kê.
class ProfileSummary extends StatelessWidget {
  const ProfileSummary({
    super.key,
    required this.user,
    required this.isOwn,
    required this.postCount,
    this.friendCount,
    this.address,
    this.relationship,
  });

  final UserModel user;
  final bool isOwn;
  final int postCount;
  final int? friendCount;
  final String? address;
  final RelationshipModel? relationship;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted =
        isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    final String? note = user.note?.trim();
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AvatarView(
            name: user.displayName,
            imageUrl: user.avatarUrl,
            size: 76,
            showOnlineDot: true,
            isOnline: user.isOnline,
            onTap: () => _openAvatar(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (!isOwn) ...<Widget>[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppSpacing.pillRadius,
                    ),
                    child: Text(
                      relationship?.status.label ?? 'Chưa kết bạn',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                if (note != null && note.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    note,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
                if (address != null && address!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Icon(Icons.place_outlined, size: 13, color: muted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                        child: StatBlock(
                            value: '$postCount', label: 'Số bài viết')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatBlock(
                        value: friendCount == null ? '—' : '$friendCount',
                        label: 'Số bạn bè',
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

  /// Mở avatar kích thước lớn, chạm ra ngoài để đóng.
  void _openAvatar(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: AvatarView(
                name: user.displayName,
                imageUrl: user.avatarUrl,
                size: 240,
                showOnlineDot: true,
                isOnline: user.isOnline,
              ),
            ),
          );
        },
      ),
    );
  }
}
