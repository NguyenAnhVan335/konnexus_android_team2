import 'package:flutter/material.dart';

import '../../../models/post_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/surface_card.dart';

/// Một media đã chọn trong trình soạn bài (kèm nút xoá).
class MediaDraftRow extends StatelessWidget {
  const MediaDraftRow({super.key, required this.media, required this.onRemove});

  final PostMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              media.kind == MediaKind.video
                  ? Icons.play_circle_outline
                  : Icons.image_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  media.kind.label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  media.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xoá media',
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
