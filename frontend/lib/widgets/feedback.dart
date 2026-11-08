import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Hộp thoại xác nhận dùng chung.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Đồng ý',
  String cancelLabel = 'Huỷ',
  bool isDestructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape:
            const RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        title: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content:
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Snackbar ngắn gọn, tự ẩn snackbar cũ.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.danger : null,
      duration: Duration(seconds: isError ? 4 : 2),
    ),
  );
}

/// Hộp thoại nhập một dòng văn bản (dùng cho URL media/avatar).
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String? helperText,
  String initialValue = '',
  String confirmLabel = 'Lưu',
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  final TextEditingController controller =
      TextEditingController(text: initialValue);
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape:
            const RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        title: Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: keyboardType,
                validator: validator,
                maxLines: 3,
                minLines: 1,
                decoration:
                    InputDecoration(hintText: hint, helperText: helperText),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
