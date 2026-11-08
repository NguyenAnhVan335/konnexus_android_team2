import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/di/app_scope.dart';
import '../../models/user_model.dart';
import '../../state/session_controller.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/feedback.dart';
import '../../widgets/konexus_app_bar.dart';

/// Chỉnh sửa hồ sơ: phần lõi (tên, email, mật khẩu, avatar) gửi `PUT /api/users/{id}`;
/// giới tính, sinh nhật, địa chỉ chỉ lưu cục bộ vì backend chưa có các cột này.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Map<String, String> _genders = <String, String>{
    'male': 'Nam',
    'female': 'Nữ',
    'unspecified': 'Không muốn tiết lộ',
  };

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  late final SessionController _session;
  bool _initialized = false;
  bool _isSaving = false;
  bool _obscure = true;
  String? _avatarUrl;
  DateTime? _birthday;
  String _gender = 'unspecified';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _session = AppScope.of(context).session;
    final UserModel? user = _session.user;
    _usernameController.text = user?.username ?? '';
    _emailController.text = user?.email ?? '';
    _addressController.text = _session.address ?? user?.address ?? '';
    _avatarUrl = user?.avatarUrl;
    _birthday = user?.birthday;
    _birthdayController.text = _birthday == null ? '' : formatDate(_birthday);
    _gender = _session.gender ?? user?.gender ?? 'unspecified';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayController.text = formatDate(picked);
      });
    }
  }

  Future<void> _changeAvatar() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image == null || !mounted) {
      return;
    }
    try {
      final String url =
          await AppScope.of(context).fileUploadService.uploadFile(image.path);
      if (!mounted) {
        return;
      }
      setState(() => _avatarUrl = url);
      showAppSnackBar(context, 'Đã cập nhật ảnh đại diện');
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Tải ảnh lên thất bại', isError: true);
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _session.updateProfile(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        avatarUrl: _avatarUrl,
        gender: _gender,
        birthday: _birthday,
        address: _addressController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Đã cập nhật hồ sơ');
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
    return Scaffold(
      appBar: AppPageHeader(
        title: 'Chỉnh sửa thông tin',
        actions: <Widget>[
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  AvatarView(
                    name: _usernameController.text.isEmpty
                        ? _session.displayName
                        : _usernameController.text,
                    imageUrl: _avatarUrl,
                    size: 84,
                    showOnlineDot: true,
                    isOnline: _session.user?.isOnline ?? false,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton.icon(
                        onPressed: _changeAvatar,
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: const Text('Đổi ảnh'),
                      ),
                      if (_avatarUrl != null)
                        TextButton(
                          onPressed: () => setState(() => _avatarUrl = null),
                          child: const Text('Xoá ảnh'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _usernameController,
              label: 'Tên',
              hint: 'Tên hiển thị',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: Validators.username,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hint: 'Mật khẩu hiện tại',
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
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmController,
              label: 'Nhập lại mật khẩu',
              hint: 'Nhập lại mật khẩu',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              validator: (String? value) =>
                  Validators.confirmPassword(value, _passwordController.text),
            ),
            const SizedBox(height: 16),
            const Text('Giới tính',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final MapEntry<String, String> entry in _genders.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _gender == entry.key,
                    onSelected: (_) => setState(() => _gender = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _birthdayController,
              label: 'Sinh nhật',
              hint: 'Chọn ngày sinh',
              prefixIcon: Icons.cake_outlined,
              readOnly: true,
              onTap: _pickBirthday,
              suffix: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _addressController,
              label: 'Địa chỉ',
              hint: 'Ví dụ: Quận 1, TP. Hồ Chí Minh',
              prefixIcon: Icons.place_outlined,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Lưu thay đổi',
              isLoading: _isSaving,
              onPressed: _save,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Huỷ',
              variant: AppButtonVariant.text,
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
