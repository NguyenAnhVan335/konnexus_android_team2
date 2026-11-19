import 'package:flutter/material.dart';

import 'core/di/app_scope.dart';
import 'core/di/app_services.dart';
import 'features/auth/login_page.dart';
import 'features/shell/main_shell.dart';
import 'navigation/app_navigator.dart';
import 'navigation/app_router.dart';
import 'state/session_controller.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';

class KonnexusApp extends StatelessWidget {
  const KonnexusApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          services.session,
          services.settings,
        ]),
        builder: (BuildContext context, Widget? _) {
          return MaterialApp(
            title: 'Konnexus',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppNavigator.key,
            theme: AppTheme.light(services.settings.accent),
            darkTheme: AppTheme.dark(services.settings.accent),
            themeMode: services.settings.themeMode,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const AppGate(),
          );
        },
      ),
    );
  }
}

/// Quyết định màn hình gốc theo trạng thái phiên đăng nhập.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext context, Widget? _) {
        switch (session.status) {
          case SessionStatus.starting:
            return const SplashScreen();
          case SessionStatus.authenticated:
            return const MainShell();
          case SessionStatus.unauthenticated:
            return const LoginPage();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppLogo(size: 96),
            const SizedBox(height: 20),
            Text(
              'Konnexus',
              style: AppTextStyles.brand.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kết nối bạn bè, chia sẻ khoảnh khắc',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
