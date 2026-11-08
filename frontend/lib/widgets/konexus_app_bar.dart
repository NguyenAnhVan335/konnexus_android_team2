import 'package:flutter/material.dart';

import '../core/di/app_scope.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';
import 'avatar_view.dart';

/// Thanh tiêu đề chính: avatar bên trái, "Konexus" ở giữa, các nút tác vụ bên phải.
///
/// Bám theo wireframe: Avatar | ... Konexus ... | [Tạo bài viết] [Tìm kiếm] [Thông báo]
class KonexusAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KonexusAppBar({
    super.key,
    this.title = 'Konexus',
    this.showAvatar = true,
    this.showCreatePost = false,
    this.showSearch = true,
    this.showNotifications = true,
    this.onAvatarTap,
    this.onCreatePost,
    this.onSearch,
    this.onNotifications,
  });

  final String title;
  final bool showAvatar;
  final bool showCreatePost;
  final bool showSearch;
  final bool showNotifications;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCreatePost;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? _) {
        return AppBar(
          centerTitle: true,
          titleSpacing: 0,
          leadingWidth: showAvatar ? 56 : 0,
          leading: showAvatar
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  child: AvatarView(
                    name: session.displayName,
                    imageUrl: session.avatarUrl,
                    size: 32,
                    onTap: onAvatarTap ??
                        () =>
                            Navigator.of(context).pushNamed(AppRoutes.profile),
                  ),
                )
              : const SizedBox.shrink(),
          title: Text(title),
          actions: <Widget>[
            if (showCreatePost)
              IconButton(
                tooltip: 'Tạo bài viết',
                icon: const Icon(Icons.edit_note_outlined),
                onPressed: onCreatePost ??
                    () =>
                        Navigator.of(context).pushNamed(AppRoutes.postComposer),
              ),
            if (showSearch)
              IconButton(
                tooltip: 'Tìm kiếm',
                icon: const Icon(Icons.search),
                onPressed: onSearch ??
                    () => Navigator.of(context).pushNamed(AppRoutes.search),
              ),
            if (showNotifications)
              IconButton(
                tooltip: 'Thông báo',
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: onNotifications ??
                    () => Navigator.of(context)
                        .pushNamed(AppRoutes.notifications),
              ),
            const SizedBox(width: 4),
          ],
        );
      },
    );
  }
}

/// Tiêu đề cho các màn hình con (có nút quay lại, nền trắng).
class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.actions,
    this.background,
    this.foreground,
  });

  final String title;
  final List<Widget>? actions;
  final Color? background;
  final Color? foreground;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor:
          background ?? (isDark ? AppColors.darkSurface : AppColors.white),
      foregroundColor: foreground ??
          (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: foreground ??
            (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
      centerTitle: false,
      actions: actions,
    );
  }
}
