import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/admin_model.dart';
import '../../state/admin_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';
import 'admin_page_scaffold.dart';

/// Danh sách người dùng: tìm kiếm + phân trang bằng `PaginatedDataTable`.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.controller});

  final AdminController controller;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.loadUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.controller.loadUsers(keyword: value.trim(), page: 0);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    widget.controller.loadUsers(keyword: '', page: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final AdminController controller = widget.controller;
        return AdminPageScaffold(
          title: 'Người dùng',
          actions: <Widget>[
            IconButton(
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadUsers(force: true),
            ),
          ],
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: ListenableBuilder(
                  listenable: _searchController,
                  builder: (BuildContext context, Widget? _) {
                    return TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Xóa tìm kiếm',
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              ),
                        border: const OutlineInputBorder(
                          borderRadius: AppSpacing.fieldRadius,
                        ),
                        isDense: true,
                      ),
                    );
                  },
                ),
              ),
              Expanded(child: _buildTable(controller)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable(AdminController controller) {
    if (controller.usersLoading && controller.users.isEmpty) {
      return const LoadingView();
    }
    if (controller.usersError != null && controller.users.isEmpty) {
      return ErrorView(
        message: controller.usersError!,
        onRetry: () => controller.loadUsers(force: true),
      );
    }
    if (controller.usersTotal == 0) {
      return const EmptyView(message: 'Không tìm thấy người dùng nào.');
    }
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: PaginatedDataTable(
          key: ValueKey<String>(
              'users-${controller.usersPage}-${controller.usersKeyword}'),
          columns: const <DataColumn>[
            DataColumn(label: Text('Người dùng')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Vai trò')),
            DataColumn(label: Text('Trạng thái')),
            DataColumn(label: Text('Ngày tạo')),
          ],
          source: _UsersDataSource(
            users: controller.users,
            total: controller.usersTotal,
            offset: controller.usersPage * controller.usersSize,
          ),
          rowsPerPage: controller.usersSize,
          initialFirstRowIndex: controller.usersPage * controller.usersSize,
          showCheckboxColumn: false,
          showEmptyRows: false,
          horizontalMargin: 16,
          onPageChanged: (int firstRow) => controller
              .loadUsers(page: firstRow ~/ controller.usersSize),
        ),
      ),
    );
  }
}
class _UsersDataSource extends DataTableSource {
  _UsersDataSource({
    required this.users,
    required this.total,
    required this.offset,
  });

  final List<AdminUser> users;
  final int total;
  final int offset;

  @override
  DataRow? getRow(int index) {
    final int local = index - offset;
    if (local < 0 || local >= users.length) {
      return null;
    }
    final AdminUser user = users[local];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Row(
          children: <Widget>[
            CircleAvatar(
              radius: 14,
              child: Text(initialsOf(user.displayName)),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(user.displayName)),
          ],
        )),
        DataCell(Text(user.email ?? '—')),
        DataCell(_RoleChip(isAdmin: user.isAdmin, isActive: user.isActive)),
        DataCell(Text(user.isOnline ? 'Online' : 'Offline')),
        DataCell(Text(formatDate(user.createdAt))),
      ],
    );
  }

  @override
  int get rowCount => total;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.isAdmin, required this.isActive});

  final bool isAdmin;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color background;
    if (!isActive) {
      label = 'Đã khóa';
      background = AppColors.textMuted;
    } else if (isAdmin) {
      label = 'Quản trị viên';
      background = AppColors.warning;
    } else {
      label = 'Thành viên';
      background = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background.withAlpha(30),
        borderRadius: AppSpacing.pillRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: background,
        ),
      ),
    );
  }
}

