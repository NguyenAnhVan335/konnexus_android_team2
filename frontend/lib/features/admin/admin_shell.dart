import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../state/admin_controller.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'dashboard_page.dart';
import 'rooms_page.dart';
import 'users_page.dart';

/// Khung chính của Admin Dashboard: sidebar trái + nội dung phải (IndexedStack).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  AdminController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= AdminController(service: AppScope.of(context).adminService);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionController session = AppScope.of(context).session;
    if (!session.isAdmin) {
      return const _AdminAccessDenied();
    }
    final AdminController controller = _controller!;
    final bool wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: Row(
        children: <Widget>[
          if (wide)
            _AdminSidebar(
              index: _index,
              onSelected: (int value) => setState(() => _index = value),
            )
          else
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (int value) =>
                  setState(() => _index = value),
              labelType: NavigationRailLabelType.all,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Tổng quan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Người dùng'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: Text('Phòng chat'),
                ),
              ],
            ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: <Widget>[
                DashboardPage(controller: controller),
                UsersPage(controller: controller),
                RoomsPage(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 232,
      color: isDark ? AppColors.darkSurface : AppColors.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: <Widget>[
                AppLogo(size: 32),
                SizedBox(width: 10),
                Text(
                  'Konnexus Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SidebarTile(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Tổng quan',
            selected: index == 0,
            onTap: () => onSelected(0),
          ),
          _SidebarTile(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Người dùng',
            selected: index == 1,
            onTap: () => onSelected(1),
          ),
          _SidebarTile(
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum,
            label: 'Phòng chat',
            selected: index == 2,
            onTap: () => onSelected(2),
          ),
          const Spacer(),
          const Divider(height: 1),
          _SidebarTile(
            icon: Icons.arrow_back,
            label: 'Về ứng dụng',
            selected: false,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      leading: Icon(selected ? (selectedIcon ?? icon) : icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

class _AdminAccessDenied extends StatelessWidget {
  const _AdminAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konnexus Admin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_outline,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'Bạn không có quyền truy cập trang quản trị.',
                textAlign: TextAlign.center,
              ),
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
