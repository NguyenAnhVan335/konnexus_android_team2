import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';

/// Đổi mật khẩu — tách riêng khỏi chỉnh sửa hồ sơ.
///
/// Bắt buộc nhập đúng mật khẩu hiện tại; backend kiểm tra lại một lần nữa
/// trước khi cập nhật (xem `PUT /api/users/password`).
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  SessionController? _session;
  bool _initialized = false;
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _session = AppScope.of(context).session;
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final SessionController? session = _session;
    if (session == null || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await session.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Đổi mật khẩu thành công');
      Navigator.of(context).pop();
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
    return Scaffold(
      appBar: const AppPageHeader(title: 'Đổi mật khẩu'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            AppTextField(
              controller: _currentController,
              label: 'Mật khẩu hiện tại',
              hint: 'Nhập mật khẩu đang dùng',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              validator: (String? value) =>
                  Validators.required(value, label: 'Mật khẩu hiện tại'),
              suffix: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _newController,
              label: 'Mật khẩu mới',
              hint: 'Ít nhất 6 ký tự',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
              suffix: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmController,
              label: 'Nhập lại mật khẩu mới',
              hint: 'Nhập lại mật khẩu mới',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (String? value) =>
                  Validators.confirmPassword(value, _newController.text),
            ),
            const SizedBox(height: 10),
            Text(
              'Mật khẩu mới phải khác mật khẩu hiện tại. Sau khi đổi, bạn vẫn '
              'đang đăng nhập trên thiết bị này.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Đổi mật khẩu',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
