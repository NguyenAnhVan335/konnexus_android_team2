import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/interaction_model.dart';
import '../../models/post_model.dart';
import '../../navigation/app_arguments.dart';
import '../../navigation/app_routes.dart';
import '../../state/post_detail_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/post_card.dart';
import '../../widgets/reaction_picker.dart';
import '../../widgets/state_views.dart';
import '../../widgets/surface_card.dart';
import '../../utils/share_utils.dart';
import 'widgets/comment_tile.dart';

/// Chi tiết bài viết: nội dung, cảm xúc, bình luận.
///
/// Backend trả kèm `reactions` + `comments` trong `GET /api/v1/posts/{id}`.
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.args});

  final PostDetailArgs args;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  PostDetailController? _controller;
  CommentModel? _replyTo;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final services = AppScope.of(context);
    _controller = PostDetailController(
      postId: widget.args.postId,
      postService: services.postService,
      interactionService: services.interactionService,
      session: services.session,
      initialPost: widget.args.initialPost,
    );
    _controller!.load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickReaction() async {
    final PostDetailController? controller = _controller;
    if (controller == null) {
      return;
    }
    final String? type = await showReactionPicker(
      context,
      currentType: controller.post?.myReaction,
    );
    if (type == null || !mounted) {
      return;
    }
    try {
      await controller.toggleLike(type);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _submitComment() async {
    final PostDetailController? controller = _controller;
    final String text = _commentController.text.trim();
    if (controller == null || text.isEmpty || controller.isSubmitting) {
      return;
    }
    final String? parentId = _replyTo?.id;
    try {
      await controller.addComment(text, parentCommentId: parentId);
      if (mounted) {
        _commentController.clear();
        setState(() => _replyTo = null);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _edit(PostModel post) async {
    final Object? result = await Navigator.of(context).pushNamed(
      AppRoutes.postComposer,
      arguments: PostComposerArgs(post: post),
    );
    if (!mounted || result is! PostModel) {
      return;
    }
    await _controller?.load();
    if (mounted) {
      showAppSnackBar(context, 'Đã cập nhật bài viết');
    }
  }

  Future<void> _delete() async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Xoá bài viết',
      message: 'Bài viết sẽ bị xoá mềm trên máy chủ. Bạn chắc chắn?',
      confirmLabel: 'Xoá',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await _controller?.deletePost();
      if (mounted) {
        showAppSnackBar(context, 'Đã xoá bài viết');
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _reactToComment(CommentModel comment) async {
    final PostDetailController? controller = _controller;
    if (controller == null) {
      return;
    }
    final String? type = await showReactionPicker(
      context,
      currentType: comment.myReaction,
    );
    if (type == null || !mounted) {
      return;
    }
    try {
      await controller.toggleCommentReaction(comment, type);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  void _beginReply(CommentModel comment) {
    setState(() => _replyTo = comment);
    _commentFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyTo = null);
  }

  String? _parentAuthorName(CommentModel comment) {
    if (!comment.isReply || comment.parentId == null) {
      return null;
    }
    final PostDetailController? controller = _controller;
    if (controller == null) {
      return null;
    }
    for (final CommentModel c in controller.comments) {
      if (c.id == comment.parentId) {
        return c.author?.displayName;
      }
    }
    return null;
  }

  /// Hiển thị một nút bình luận và đệ quy các trả lời (thụt lề theo cấp).
  Widget _buildCommentNode(
    CommentNode node,
    PostDetailController controller, {
    required int depth,
  }) {
    final CommentModel comment = node.comment;
    final int indentLevel = depth > 4 ? 4 : depth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: indentLevel * 18),
          child: CommentTile(
            comment: comment,
            isOwn: controller.isCommentOwner(comment),
            parentAuthorName: _parentAuthorName(comment),
            onReact: () => _reactToComment(comment),
            onReply: () => _beginReply(comment),
            onEdit: () => _editComment(comment),
            onDelete: () => _deleteComment(comment),
          ),
        ),
        for (final CommentNode reply in node.replies)
          _buildCommentNode(reply, controller, depth: depth + 1),
      ],
    );
  }

  Future<void> _editComment(CommentModel comment) async {
    final PostDetailController? controller = _controller;
    if (controller == null) {
      return;
    }
    // Controller của dialog do widget dialog tự quản lý (xem _CommentEditDialog).
    final String? newContent = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _CommentEditDialog(initialContent: comment.content);
      },
    );
    if (newContent == null || newContent.isEmpty || !mounted) {
      return;
    }
    try {
      await controller.editComment(comment.id, newContent);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final PostDetailController? controller = _controller;
    if (controller == null) {
      return;
    }
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Xoá bình luận',
      message: 'Bạn chắc chắn muốn xoá bình luận này?',
      confirmLabel: 'Xoá',
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await controller.deleteComment(comment.id);
      if (mounted) {
        showAppSnackBar(context, 'Đã xoá bình luận');
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    }
  }

  Future<void> _sharePost(PostModel post) async {
    try {
      await sharePost(post);
    } catch (_) {
      // Bỏ qua khi không có app nhận share.
    }
  }

  @override
  Widget build(BuildContext context) {
    final PostDetailController? controller = _controller;
    if (controller == null) {
      return const Scaffold(body: LoadingView());
    }
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: const AppPageHeader(title: 'Bài viết'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final PostModel? post = controller.post;
          return Column(
            children: <Widget>[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: <Widget>[
                      if (post == null && controller.isLoading)
                        const LoadingView(message: 'Đang tải bài viết...')
                      else if (post == null)
                        ErrorView(
                          message:
                              controller.error ?? 'Không tìm thấy bài viết.',
                          onRetry: controller.load,
                        )
                      else ...<Widget>[
                        PostCard(
                          post: post,
                          showActions: true,
                          onLike: _pickReaction,
                          onComment: () => _commentFocus.requestFocus(),
                          onShare: () => _sharePost(post),
                          onEdit: controller.isOwner ? () => _edit(post) : null,
                          onDelete: controller.isOwner ? _delete : null,
                        ),
                        const SizedBox(height: 16),
                        SectionHeading(
                          title: 'Bình luận (${controller.comments.length})',
                        ),
                        const SizedBox(height: 12),
                        if (controller.comments.isEmpty)
                          const EmptyView(
                            message:
                                'Chưa có bình luận nào. Hãy là người đầu tiên!',
                            icon: Icons.mode_comment_outlined,
                          )
                        else
                          for (final CommentNode node in controller.commentTree)
                            _buildCommentNode(node, controller, depth: 0),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_replyTo != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Đang trả lời ${_replyTo!.author?.displayName ?? 'bình luận'}: ${_replyTo!.content}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _cancelReply,
                                child: const Icon(Icons.close, size: 16),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocus,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _submitComment(),
                              decoration: InputDecoration(
                                hintText: _replyTo == null
                                    ? 'Viết bình luận...'
                                    : 'Viết trả lời...',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            tooltip: 'Gửi bình luận',
                            onPressed:
                                controller.isSubmitting ? null : _submitComment,
                            icon: controller.isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Dialog sửa bình luận — tự tạo và dispose `TextEditingController`.
///
/// Trước đây controller được tạo trong `_editComment` rồi dispose ngay sau khi
/// `showDialog` trả về. Lúc đó dialog vẫn đang chạy animation đóng và `TextField`
/// vẫn còn listener, khiến `ChangeNotifier.dispose()` ném assertion
/// `_dependents.isEmpty`. Đặt controller vào State của dialog để vòng đời khớp
/// với vòng đời widget.
class _CommentEditDialog extends StatefulWidget {
  const _CommentEditDialog({required this.initialContent});

  final String initialContent;

  @override
  State<_CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends State<_CommentEditDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialContent);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa bình luận'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 5,
        decoration: const InputDecoration(hintText: 'Nội dung bình luận'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
