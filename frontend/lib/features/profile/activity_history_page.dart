import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/state_views.dart';

/// Lịch sử hoạt động của chính người dùng (7 ngày gần nhất).
///
/// Dữ liệu lấy từ `GET /api/activities`; backend xác định người dùng qua JWT
/// nên màn hình không cần truyền userId.
class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  ActivityService? _service;
  bool _initialized = false;
  bool _isLoading = true;
  String? _error;
  List<ActivityItem> _items = const <ActivityItem>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _service = AppScope.of(context).activityService;
    _load();
  }

  Future<void> _load() async {
    final ActivityService? service = _service;
    if (service == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<ActivityItem> items = await service.fetchActivities(
        from: DateTime.now().subtract(const Duration(days: 7)),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.userMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageHeader(title: 'Lịch sử hoạt động'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 24),
          LoadingView(message: 'Đang tải hoạt động...'),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 24),
          ErrorView(message: _error!, onRetry: _load),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 24),
          EmptyView(
            message: 'Chưa có hoạt động nào trong 7 ngày qua',
            icon: Icons.history,
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        return _ActivityTile(
          item: _items[index],
          isLast: index == _items.length - 1,
        );
      },
    );
  }
}

/// Một mốc trên timeline: icon theo loại hoạt động, nội dung và thời gian.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.isLast});

  final ActivityItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = _accentOf(item.kind);
    final Color primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final Color secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 40,
            child: Column(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconOf(item.kind), size: 18, color: accent),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _titleOf(item.kind),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRelativeTime(item.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (item.preview.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      item.preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _titleOf(ActivityKind kind) {
    switch (kind) {
      case ActivityKind.reaction:
        return 'Bạn đã bày tỏ cảm xúc với một bài viết';
      case ActivityKind.comment:
        return 'Bạn đã bình luận';
      case ActivityKind.post:
        return 'Bạn đã đăng bài viết';
      case ActivityKind.friendRequest:
        return 'Bạn đã gửi lời mời kết bạn';
      case ActivityKind.unknown:
        return 'Hoạt động';
    }
  }

  static IconData _iconOf(ActivityKind kind) {
    switch (kind) {
      case ActivityKind.reaction:
        return Icons.favorite_border;
      case ActivityKind.comment:
        return Icons.mode_comment_outlined;
      case ActivityKind.post:
        return Icons.article_outlined;
      case ActivityKind.friendRequest:
        return Icons.person_add_alt_1_outlined;
      case ActivityKind.unknown:
        return Icons.history;
    }
  }

  static Color _accentOf(ActivityKind kind) {
    switch (kind) {
      case ActivityKind.reaction:
        return AppColors.danger;
      case ActivityKind.comment:
        return AppColors.primary;
      case ActivityKind.post:
        return AppColors.success;
      case ActivityKind.friendRequest:
        return AppColors.primaryLight;
      case ActivityKind.unknown:
        return AppColors.textMuted;
    }
  }
}
