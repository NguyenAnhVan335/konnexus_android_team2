import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../state/messages_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/konexus_app_bar.dart';
import '../../widgets/state_views.dart';

/// Màn hình tạo nhóm chat: đặt tên nhóm rồi chọn nhiều thành viên.
///
/// Người tạo tự động được thêm làm quản trị viên (ADMIN) ở backend, nên danh
/// sách chọn sẽ loại bỏ chính mình để tránh trùng thành viên.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  MessagesController? _messages;
  bool _initialized = false;
  bool _isCreating = false;
  String _keyword = '';
  String _name = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final services = AppScope.of(context);
    _messages = MessagesController(services.chatService);
    services.usersDirectory.ensureLoaded();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _messages?.dispose();
    super.dispose();
  }

  List<UserModel> _candidates(String currentUserId, List<UserModel> users) {
    final List<UserModel> result = users
        .where((UserModel user) =>
            user.id.isNotEmpty &&
            user.id != currentUserId &&
            (_keyword.isEmpty ||
                user.displayName
                    .toLowerCase()
                    .contains(_keyword.toLowerCase())))
        .toList();
    result.sort(
        (UserModel a, UserModel b) => a.displayName.compareTo(b.displayName));
    return result;
  }

  Future<void> _create() async {
    final MessagesController? controller = _messages;
    if (controller == null || _isCreating) {
      return;
    }
    final String title = _name.trim();
    if (title.isEmpty || _selectedIds.isEmpty) {
      return;
    }
    setState(() => _isCreating = true);
    try {
      final ChatThread thread = await controller.createGroup(
        title: title,
        memberIds: _selectedIds.toList(growable: false),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(thread);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tạo được nhóm. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final String currentUserId = services.session.userId ?? '';
    final bool canCreate =
        _name.trim().isNotEmpty && _selectedIds.isNotEmpty && !_isCreating;

    return Scaffold(
      appBar: const AppPageHeader(title: 'Tạo nhóm chat'),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppTextField(
              controller: _nameController,
              label: 'Tên nhóm',
              hint: 'Ví dụ: Nhóm học tập',
              textInputAction: TextInputAction.next,
              maxLength: 80,
              onChanged: (String value) => setState(() => _name = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (String value) =>
                  setState(() => _keyword = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Tìm thành viên',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: <Widget>[
                const Text('Đã chọn ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_selectedIds.length} thành viên'),
                const Spacer(),
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    child: const Text('Bỏ chọn tất cả'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: services.usersDirectory,
              builder: (BuildContext context, Widget? _) {
                if (services.usersDirectory.isLoading &&
                    services.usersDirectory.users.isEmpty) {
                  return const LoadingView(message: 'Đang tải danh sách...');
                }
                final List<UserModel> candidates =
                    _candidates(currentUserId, services.usersDirectory.users);
                if (candidates.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy người dùng phù hợp.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  itemCount: candidates.length,
                  itemBuilder: (BuildContext context, int index) {
                    final UserModel user = candidates[index];
                    final bool selected = _selectedIds.contains(user.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (bool? value) => setState(() {
                        if (value == true) {
                          _selectedIds.add(user.id);
                        } else {
                          _selectedIds.remove(user.id);
                        }
                      }),
                      secondary: AvatarView(
                        name: user.displayName,
                        imageUrl: user.avatarUrl,
                        size: 38,
                        isOnline: user.isOnline,
                        showOnlineDot: true,
                      ),
                      title: Text(user.displayName),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton(
                label: 'Tạo nhóm',
                icon: Icons.group_add_outlined,
                isLoading: _isCreating,
                onPressed: canCreate ? _create : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
