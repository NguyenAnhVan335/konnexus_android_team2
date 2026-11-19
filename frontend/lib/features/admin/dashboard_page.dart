import 'package:flutter/material.dart';

import '../../models/admin_model.dart';
import '../../state/admin_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/state_views.dart';
import 'admin_page_scaffold.dart';

/// Thẻ thống kê tổng quan + switch bật/tắt trợ lý Charles.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.controller});

  final AdminController controller;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final AdminController controller = widget.controller;
        return AdminPageScaffold(
          title: 'Tổng quan',
          actions: <Widget>[
            IconButton(
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh),
              onPressed: controller.dashboardLoading
                  ? null
                  : () => controller.loadDashboard(force: true),
            ),
          ],
          child: _buildBody(controller),
        );
      },
    );
  }

  Widget _buildBody(AdminController controller) {
    if (controller.dashboardLoading && controller.dashboard == null) {
      return const LoadingView();
    }
    if (controller.dashboardError != null && controller.dashboard == null) {
      return ErrorView(
        message: controller.dashboardError!,
        onRetry: () => controller.loadDashboard(force: true),
      );
    }
    final AdminDashboard dashboard =
        controller.dashboard ?? const AdminDashboard();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (controller.dashboardError != null) ...<Widget>[
            ErrorView(
              message: controller.dashboardError!,
              onRetry: () => controller.loadDashboard(force: true),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              _StatCard(
                icon: Icons.people_outline,
                label: 'Tổng người dùng',
                value: '${dashboard.totalUsers}',
              ),
              _StatCard(
                icon: Icons.article_outlined,
                label: 'Tổng bài viết',
                value: '${dashboard.totalPosts}',
              ),
              _StatCard(
                icon: Icons.chat_bubble_outline,
                label: 'Tổng tin nhắn',
                value: '${dashboard.totalMessages}',
              ),
              _StatCard(
                icon: Icons.circle,
                iconColor: AppColors.success,
                label: 'Người dùng online',
                value: '${dashboard.onlineUsers}',
              ),
              _StatCard(
                icon: Icons.schedule,
                label: 'Số giờ sử dụng',
                value: dashboard.totalUsageHours == null
                    ? 'Chưa có dữ liệu'
                    : '${dashboard.totalUsageHours!.toStringAsFixed(1)} giờ',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildBotCard(controller, dashboard),
        ],
      ),
    );
  }
  Widget _buildBotCard(AdminController controller, AdminDashboard dashboard) {
    return SurfaceCard(
      child: Row(
        children: <Widget>[
          const Icon(Icons.smart_toy_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Trợ lý Charles',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bật/tắt chatbot trả lời khi nhắn "@charles".',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (controller.botBusy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            Switch(
              value: dashboard.isBotEnabled,
              onChanged: (bool value) => controller.setBotEnabled(value),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: SurfaceCard(
        child: Row(
          children: <Widget>[
            Icon(icon, size: 28, color: iconColor ?? AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

