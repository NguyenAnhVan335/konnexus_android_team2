import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Khối nền trắng bo góc, viền mảnh — đơn vị bố cục cơ bản của ứng dụng.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget container = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppColors.darkSurface : AppColors.white),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color:
              borderColor ?? (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: child,
    );
    if (onTap == null) {
      return container;
    }
    return InkWell(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: container,
    );
  }
}

/// Tiêu đề nhỏ cho một nhóm nội dung.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
