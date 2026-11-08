import 'package:flutter/material.dart';

import '../../../models/post_model.dart';
import '../../../utils/validators.dart';

/// Hộp thoại thêm media bằng URL (backend chưa có API upload ảnh).
class MediaInputDialog extends StatefulWidget {
  const MediaInputDialog({super.key});

  @override
  State<MediaInputDialog> createState() => _MediaInputDialogState();
}

class _MediaInputDialogState extends State<MediaInputDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  MediaKind _kind = MediaKind.image;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Thêm media bằng URL',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final MediaKind kind in MediaKind.values)
                  ChoiceChip(
                    label: Text(kind.label),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              validator: Validators.mediaUrl,
              decoration: const InputDecoration(
                hintText: 'https://example.com/hinh-anh.jpg',
                helperText: 'Backend chỉ chấp nhận URL http/https.',
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(
                PostMedia(url: _urlController.text.trim(), kind: _kind),
              );
            }
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
