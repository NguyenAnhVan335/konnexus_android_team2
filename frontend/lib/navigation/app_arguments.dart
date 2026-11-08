import '../models/chat_model.dart';
import '../models/post_model.dart';

/// Tham số điều hướng tới trang cá nhân của một người dùng khác.
class ProfileArgs {
  const ProfileArgs({required this.userId});

  final String userId;
}

/// Tham số mở chi tiết bài viết (có thể kèm dữ liệu đã có để hiển thị ngay).
class PostDetailArgs {
  const PostDetailArgs({required this.postId, this.initialPost});

  final String postId;
  final PostModel? initialPost;
}

/// Tham số mở trình soạn bài: [post] null nghĩa là tạo mới, khác null là chỉnh sửa.
class PostComposerArgs {
  const PostComposerArgs({this.post});

  final PostModel? post;

  bool get isEditing => post != null;
}

/// Tham số mở màn hình trò chuyện.
class ChatArgs {
  const ChatArgs({required this.thread});

  final ChatThread thread;
}
