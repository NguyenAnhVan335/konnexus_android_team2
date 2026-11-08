  import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, outlined, text, danger }

/// Nút dùng chung: có trạng thái loading, icon và biến thể màu.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Widget child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: disabled ? null : onPressed,
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          child: child,
        ),
    };

    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Thẻ thông tin nhỏ (số bài viết, số bạn bè...) theo phong cách wireframe.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: AppSpacing.fieldRadius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceMuted,
          borderRadius: AppSpacing.fieldRadius,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
