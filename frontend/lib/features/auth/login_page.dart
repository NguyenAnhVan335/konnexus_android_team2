import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../navigation/app_routes.dart';
import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Hiển thị thông báo khi bị đẩy về đây do phiên hết hạn (HTTP 401).
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      final String? notice = AppScope.of(context).session.takeNotice();
      if (notice != null) {
        showAppSnackBar(context, notice, isError: true);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final SessionController session = AppScope.of(context).session;
    try {
      await session.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Đăng nhập thành công');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      final String message = error.isNotFound
          ? 'Tài khoản hoặc mật khẩu không đúng.'
          : error.userMessage;
      showAppSnackBar(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionController session = AppScope.of(context).session;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subtitleColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'K',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Konexus',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Đăng nhập để kết nối với bạn bè',
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _usernameController,
                    label: 'Tên đăng nhập',
                    hint: 'Nhập username',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.username],
                    validator: Validators.username,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    hint: 'Nhập mật khẩu',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.password],
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: session,
                    builder: (BuildContext context, Widget? _) {
                      final String? error = session.error;
                      if (error == null) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(20),
                          borderRadius: AppSpacing.fieldRadius,
                          border:
                              Border.all(color: AppColors.danger.withAlpha(80)),
                        ),
                        child: Text(
                          error,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.danger),
                        ),
                      );
                    },
                  ),
                  ListenableBuilder(
                    listenable: session,
                    builder: (BuildContext context, Widget? _) {
                      return AppButton(
                        label: 'Đăng nhập',
                        isLoading: session.isBusy,
                        onPressed: _submit,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Chưa có tài khoản?',
                          style: TextStyle(fontSize: 13, color: subtitleColor)),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.register),
                        child: const Text('Đăng ký'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Máy chủ: ${ApiConfig.normalizedBaseUrl}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Android Emulator dùng 10.0.2.2 để trỏ tới backend trên máy tính.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.35,
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
      ),
    );
  }
}
