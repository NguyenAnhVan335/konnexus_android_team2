import 'package:share_plus/share_plus.dart';

import '../config/api_config.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

/// Mở share sheet hệ thống để chia sẻ một bài viết.
Future<void> sharePost(PostModel post) async {
  final String content = (post.content ?? '').trim();
  final String link = '${ApiConfig.normalizedBaseUrl}/api/v1/posts/${post.id}';
  final String text = <String>[
    '${post.author.displayName} trên Konexus',
    if (content.isNotEmpty) content,
    link,
  ].join('\n\n');
  await Share.share(
    text,
    subject: '${post.author.displayName} trên Konexus',
  );
}

/// Mở share sheet hệ thống để chia sẻ trang cá nhân của một người dùng.
Future<void> shareUser(UserModel user) async {
  final String link = '${ApiConfig.normalizedBaseUrl}/api/users/${user.id}';
  await Share.share(
    '${user.displayName} trên Konexus\n\n$link',
    subject: '${user.displayName} trên Konexus',
  );
}
