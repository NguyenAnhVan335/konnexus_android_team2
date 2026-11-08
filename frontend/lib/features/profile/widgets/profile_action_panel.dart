import 'package:flutter/material.dart';

import '../../../widgets/app_button.dart';

/// Các nút hành động dưới phần thông tin trang cá nhân.
class ProfileActionPanel extends StatelessWidget {
  const ProfileActionPanel({
    super.key,
    required this.isOwn,
    required this.relationshipButton,
    required this.onEdit,
    required this.onSettings,
    required this.onCreatePost,
    required this.onShare,
    required this.onMessage,
  });

  final bool isOwn;
  final Widget relationshipButton;
  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final VoidCallback onCreatePost;
  final VoidCallback onShare;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    if (!isOwn) {
      return Row(
        children: <Widget>[
          Expanded(child: relationshipButton),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              label: 'Nhắn tin',
              icon: Icons.chat_bubble_outline,
              variant: AppButtonVariant.outlined,
              onPressed: onMessage,
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Chỉnh sửa trang cá nhân',
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: onEdit,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Chia sẻ',
                icon: Icons.share_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: onShare,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Tạo bài viết',
                icon: Icons.add,
                onPressed: onCreatePost,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Cài đặt',
                icon: Icons.settings_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: onSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
