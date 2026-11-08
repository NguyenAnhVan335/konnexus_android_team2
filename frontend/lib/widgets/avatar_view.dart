import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Ảnh đại diện dùng chung: ưu tiên ảnh mạng (có cache), fallback là chữ cái đầu.
class AvatarView extends StatelessWidget {
  const AvatarView({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 44,
    this.isOnline = false,
    this.showOnlineDot = false,
    this.onTap,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final bool isOnline;
  final bool showOnlineDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String url = (imageUrl ?? '').trim();
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url.isEmpty
          ? _AvatarInitials(name: name, size: size)
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              // Dùng chữ cái đầu thay vì khung trống để danh sách không bị nhấp nháy.
              placeholder: (BuildContext context, String imageUrl) =>
                  _AvatarInitials(name: name, size: size),
              errorWidget:
                  (BuildContext context, String imageUrl, Object error) =>
                      _AvatarInitials(name: name, size: size),
            ),
    );

    if (showOnlineDot && isOnline) {
      avatar = Stack(
        children: <Widget>[
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) {
      return avatar;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}

/// Ảnh dự phòng khi chưa có URL hoặc tải ảnh thất bại.
class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      initialsOf(name),
      style: TextStyle(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}
