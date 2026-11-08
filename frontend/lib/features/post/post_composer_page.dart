import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/post_model.dart';
import '../../navigation/app_arguments.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/privacy_icon.dart';
import 'widgets/media_draft_row.dart';
import 'widgets/media_input_dialog.dart';

/// Tạo mới hoặc chỉnh sửa bài viết.
///
/// - Tạo: `POST /api/v1/posts` (201) với `content`, `privacy`, `media_list`.
/// - Sửa: `PUT /api/v1/posts/{id}` — backend thay thế toàn bộ `media_list`.
/// - Media nhập bằng URL vì backend chưa có endpoint upload ảnh.
class PostComposerPage extends StatefulWidget {
  const PostComposerPage({super.key, required this.args});

  final PostComposerArgs args;

  @override
  State<PostComposerPage> createState() => _PostComposerPageState();
}

class _PostComposerPageState extends State<PostComposerPage> {
  final TextEditingController _contentController = TextEditingController();
  final List<PostMedia> _media = <PostMedia>[];
  late SessionController _session;
  PostPrivacy _privacy = PostPrivacy.public;
  bool _initialized = false;
  bool _isSaving = false;

  bool get _isEditing => widget.args.isEditing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _session = AppScope.of(context).session;
    final PostModel? post = widget.args.post;
    if (post != null) {
      _contentController.text = post.content ?? '';
      _privacy = post.privacy;
      _media.addAll(post.media);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _addMedia() async {
    final PostMedia? media = await showDialog<PostMedia>(
      context: context,
      builder: (BuildContext dialogContext) => const MediaInputDialog(),
    );
    if (media == null || !mounted) {
      return;
    }
    if (_media.length >= ApiConfig.maxMediaPerPost) {
      showAppSnackBar(
        context,
        'Tối đa ${ApiConfig.maxMediaPerPost} media cho mỗi bài viết',
        isError: true,
      );
      return;
    }
    setState(() => _media.add(media));
  }

  Future<void> _addImageMedia() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) {
      return;
    }
    if (_media.length >= ApiConfig.maxMediaPerPost) {
      showAppSnackBar(
        context,
        'Tối đa ${ApiConfig.maxMediaPerPost} media cho mỗi bài viết',
        isError: true,
      );
      return;
    }
    try {
      final String url = await AppScope.of(context)
          .fileUploadService
          .uploadFile(image.path);
      if (!mounted) {
        return;
      }
      setState(
          () => _media.add(PostMedia(url: url, kind: MediaKind.image)));
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Tải ảnh lên thất bại', isError: true);
      }
    }
  }

  Future<void> _submit() async {
    final String? validation = Validators.postContent(
      _contentController.text,
      hasMedia: _media.isNotEmpty,
    );
    if (validation != null) {
      showAppSnackBar(context, validation, isError: true);
      return;
    }
    setState(() => _isSaving = true);
    final services = AppScope.of(context);
    try {
      final PostModel saved;
      if (_isEditing && widget.args.post != null) {
        saved = await services.postService.updatePost(
          widget.args.post!.id,
          content: _contentController.text,
          privacy: _privacy,
          media: _media,
        );
      } else {
        saved = await services.postService.createPost(
          content: _contentController.text,
          privacy: _privacy,
          media: _media,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.userMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color muted =
        isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
    return Scaffold(
      appBar: AppPageHeader(
        title: _isEditing ? 'Chỉnh sửa bài viết' : 'Tạo bài viết',
        actions: <Widget>[
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: Text(_isEditing ? 'Lưu' : 'Đăng'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: <Widget>[
          Row(
            children: <Widget>[
              AvatarView(
                  name: _session.displayName,
                  imageUrl: _session.avatarUrl,
                  size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _session.displayName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đăng với quyền: ${_privacy.label}',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _contentController,
            hint: 'Bạn đang nghĩ gì?',
            maxLines: 8,
            minLines: 5,
            maxLength: ApiConfig.maxContentLength,
            showCounter: true,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 12),
          const Text(
            'Quyền riêng tư',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: <Widget>[
              for (final PostPrivacy privacy in PostPrivacy.values)
                ChoiceChip(
                  avatar: Icon(
                    privacyIcon(privacy),
                    size: 15,
                    color: _privacy == privacy ? Colors.white : muted,
                  ),
                  label: Text(privacy.label),
                  selected: _privacy == privacy,
                  onSelected: (_) => setState(() => _privacy = privacy),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Media đính kèm',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _addImageMedia,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: const Text('Tải ảnh lên'),
              ),
              TextButton.icon(
                onPressed: _addMedia,
                icon: const Icon(Icons.add_link, size: 16),
                label: const Text('Thêm URL'),
              ),
            ],
          ),
          if (_media.isEmpty)
            Text(
              'Chưa có ảnh/video đính kèm.',
              style: TextStyle(fontSize: 11, height: 1.4, color: muted),
            )
          else
            for (int index = 0; index < _media.length; index++)
              MediaDraftRow(
                media: _media[index],
                onRemove: () => setState(() => _media.removeAt(index)),
              ),
          const SizedBox(height: 18),
          AppButton(
            label: _isEditing ? 'Lưu thay đổi' : 'Đăng bài',
            icon: Icons.send_outlined,
            isLoading: _isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
