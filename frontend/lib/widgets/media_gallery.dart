import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../theme/app_colors.dart';

/// Hiển thị tối đa 4 media của bài viết (backend nhận `media_url`, chưa có upload).
class MediaGallery extends StatelessWidget {
  const MediaGallery({super.key, required this.items});

  final List<PostMedia> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<PostMedia> visible = items.take(4).toList(growable: false);
    final int hiddenCount = items.length - visible.length;
    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: visible.length == 1 ? 1 : 2,
      childAspectRatio: visible.length == 1 ? 1.7 : 1.1,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: <Widget>[
        for (int index = 0; index < visible.length; index++)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _MediaTile(media: visible[index]),
                if (index == visible.length - 1 && hiddenCount > 0)
                  Container(
                    color: Colors.black.withAlpha(120),
                    alignment: Alignment.center,
                    child: Text(
                      '+$hiddenCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.media});

  final PostMedia media;

  @override
  Widget build(BuildContext context) {
    if (media.kind == MediaKind.video) {
      final Uri? uri = Uri.tryParse(media.url);
      return Container(
        color: AppColors.textPrimary,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
            const SizedBox(height: 6),
            Text(
              uri?.host ?? 'Video',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (BuildContext context, String imageUrl) {
        return Container(
          color: AppColors.surfaceMuted,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorWidget: (BuildContext context, String imageUrl, Object error) {
        return Container(
          color: AppColors.surfaceMuted,
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
              SizedBox(height: 4),
              Text(
                'Không tải được ảnh',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}
