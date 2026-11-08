import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../state/session_controller.dart';
import '../../state/users_directory.dart';
import '../../widgets/konexus_bottom_nav.dart';
import '../explore/explore_page.dart';
import '../friends/friends_page.dart';
import '../home/home_page.dart';
import '../messages/messages_page.dart';
import '../profile/profile_page.dart';

/// Khung chính với thanh điều hướng dưới cùng 5 mục theo wireframe.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  SessionController? _session;
  UsersDirectory? _directory;
  Timer? _heartbeat;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    ExplorePage(),
    MessagesPage(),
    FriendsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      _session?.setOnline(true);
      _directory?.ensureLoaded(force: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = AppScope.of(context).session;
    _directory = AppScope.of(context).usersDirectory;
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _session?.setOnline(false);
    } else if (state == AppLifecycleState.resumed) {
      _session?.setOnline(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: KonexusBottomNav(
        currentIndex: _currentIndex,
        onSelected: (int index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
