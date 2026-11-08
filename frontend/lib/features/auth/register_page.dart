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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSubmitting = true);
    final SessionController session = AppScope.of(context).session;
    try {
      await session.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      await session.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(
          context, 'Đăng ký thành công, chào mừng bạn đến Konexus!');
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, error.userMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Scaffold(
      appBar: const AppPageHeader(title: 'Đăng ký'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Tạo tài khoản Konexus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tài khoản dùng để đăng nhập và gửi yêu cầu kết bạn với mọi người.',
                  style:
                      TextStyle(fontSize: 12.5, height: 1.4, color: mutedColor),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _usernameController,
                  label: 'Tên đăng nhập',
                  hint: 'Ví dụ: konexus_user',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: Validators.username,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  hint: 'Tối thiểu 6 ký tự',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmController,
                  label: 'Nhập lại mật khẩu',
                  hint: 'Nhập lại mật khẩu',
                  prefixIcon: Icons.lock_reset_outlined,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: (String? value) => Validators.confirmPassword(
                      value, _passwordController.text),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Đăng ký và đăng nhập',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sau khi đăng ký, ứng dụng tự đăng nhập bằng tài khoản vừa tạo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
