import 'package:flutter/material.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/messages/chat_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/post/post_composer_page.dart';
import '../features/post/post_detail_page.dart';
import '../features/profile/edit_profile_page.dart';
import '../features/profile/profile_page.dart';
import '../features/profile/settings_page.dart';
import '../features/search/search_page.dart';
import 'app_arguments.dart';
import 'app_routes.dart';

/// Điều hướng bằng tên route, tham số được đóng gói trong `app_arguments.dart`.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Object? args = settings.arguments;
    switch (settings.name) {
      case AppRoutes.login:
        return _page(const LoginPage(), settings);
      case AppRoutes.register:
        return _page(const RegisterPage(), settings);
      case AppRoutes.search:
        return _page(const SearchPage(), settings);
      case AppRoutes.notifications:
        return _page(const NotificationsPage(), settings);
      case AppRoutes.editProfile:
        return _page(const EditProfilePage(), settings);
      case AppRoutes.settings:
        return _page(const SettingsPage(), settings);
      case AppRoutes.postComposer:
        return _page(
          PostComposerPage(
            args: args is PostComposerArgs ? args : const PostComposerArgs(),
          ),
          settings,
        );
      case AppRoutes.postDetail:
        if (args is PostDetailArgs) {
          return _page(PostDetailPage(args: args), settings);
        }
        return _page(
          const _RouteErrorPage(
              message: 'Không mở được bài viết: thiếu postId.'),
          settings,
        );
      case AppRoutes.chat:
        if (args is ChatArgs) {
          return _page(ChatPage(args: args), settings);
        }
        return _page(
          const _RouteErrorPage(
              message: 'Không mở được trò chuyện: thiếu dữ liệu.'),
          settings,
        );
      case AppRoutes.profile:
        return _page(
          ProfilePage(userId: args is ProfileArgs ? args.userId : null),
          settings,
        );
      default:
        return _page(
          _RouteErrorPage(
              message: 'Không tìm thấy màn hình "${settings.name}".'),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _page(
      Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      builder: (BuildContext context) => child,
      settings: settings,
    );
  }
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konexus')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
