import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';

/// Trạng thái đang tải.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Đang tải...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái lỗi, kèm nút thử lại nếu có.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_outlined,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 16),
            AppButton(
              label: 'Thử lại',
              icon: Icons.refresh,
              variant: AppButtonVariant.outlined,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Trạng thái danh sách rỗng.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            AppButton(
              label: actionLabel!,
              variant: AppButtonVariant.outlined,
              expand: false,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Nhãn ghi chú cho phần dữ liệu mẫu (backend chưa có API).
class MockDataBanner extends StatelessWidget {
  const MockDataBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.4, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
