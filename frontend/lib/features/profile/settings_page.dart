import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../navigation/app_routes.dart';
import '../../state/session_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/surface_card.dart';
import 'widgets/accent_picker.dart';

/// Cài đặt: chế độ sáng/tối, màu theme, tài khoản và thông tin kết nối backend.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _pickThemeMode(
    BuildContext context,
    SettingsController settings,
  ) async {
    final ThemeMode? selected = await showDialog<ThemeMode>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Chọn chế độ'),
          children: <Widget>[
            for (final MapEntry<ThemeMode, String> option
                in const <ThemeMode, String>{
              ThemeMode.light: 'Sáng',
              ThemeMode.dark: 'Tối',
              ThemeMode.system: 'Theo hệ thống',
            }.entries)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(option.key),
                child: Row(
                  children: <Widget>[
                    Icon(
                      settings.themeMode == option.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(option.value),
                  ],
                ),
              ),
          ],
        );
      },
    );
    if (selected != null) {
      await settings.setThemeMode(selected);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc muốn đăng xuất khỏi Konexus trên thiết bị này?',
      confirmLabel: 'Đăng xuất',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final SessionController session = AppScope.of(context).session;
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    await session.logout();
    if (context.mounted) {
      showAppSnackBar(context, 'Đã đăng xuất');
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = AppScope.of(context).settings;
    final SessionController session = AppScope.of(context).session;
    return Scaffold(
      appBar: const AppPageHeader(title: 'Cài đặt'),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[settings, session]),
        builder: (BuildContext context, Widget? _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: <Widget>[
              const SectionHeading(title: 'Giao diện'),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: const Text('Chế độ'),
                      subtitle: Text(_themeModeLabel(settings.themeMode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickThemeMode(context, settings),
                    ),
                    const Divider(height: 1),
                    AccentPicker(settings: settings),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeading(title: 'Tài khoản'),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(session.displayName),
                      subtitle: Text(session.user?.email ?? 'Chưa có email'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Chỉnh sửa thông tin cá nhân'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.editProfile),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: AppColors.danger),
                      title: const Text('Đăng xuất',
                          style: TextStyle(color: AppColors.danger)),
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.system:
        return 'Theo hệ thống';
    }
  }
}
