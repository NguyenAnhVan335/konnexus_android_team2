import 'package:flutter/material.dart';

import '../../models/admin_model.dart';
import '../../state/admin_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters.dart';
import '../../widgets/state_views.dart';
import 'admin_page_scaffold.dart';

/// Danh sách phòng chat + phân trang bằng `PaginatedDataTable`.
class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key, required this.controller});

  final AdminController controller;

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final AdminController controller = widget.controller;
        return AdminPageScaffold(
          title: 'Phòng chat',
          actions: <Widget>[
            IconButton(
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadRooms(force: true),
            ),
          ],
          child: _buildTable(controller),
        );
      },
    );
  }

  Widget _buildTable(AdminController controller) {
    if (controller.roomsLoading && controller.rooms.isEmpty) {
      return const LoadingView();
    }
    if (controller.roomsError != null && controller.rooms.isEmpty) {
      return ErrorView(
        message: controller.roomsError!,
        onRetry: () => controller.loadRooms(force: true),
      );
    }
    if (controller.roomsTotal == 0) {
      return const EmptyView(message: 'Chưa có phòng chat nào.');
    }
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: PaginatedDataTable(
          key: ValueKey<String>('rooms-${controller.roomsPage}'),
          columns: const <DataColumn>[
            DataColumn(label: Text('Phòng')),
            DataColumn(label: Text('Loại')),
            DataColumn(label: Text('Người tạo')),
            DataColumn(label: Text('Ngày tạo')),
          ],
          source: _RoomsDataSource(
            rooms: controller.rooms,
            total: controller.roomsTotal,
            offset: controller.roomsPage * controller.roomsSize,
          ),
          rowsPerPage: controller.roomsSize,
          initialFirstRowIndex: controller.roomsPage * controller.roomsSize,
          showCheckboxColumn: false,
          showEmptyRows: false,
          horizontalMargin: 16,
          onPageChanged: (int firstRow) => controller
              .loadRooms(page: firstRow ~/ controller.roomsSize),
        ),
      ),
    );
  }
}

class _RoomsDataSource extends DataTableSource {
  _RoomsDataSource({
    required this.rooms,
    required this.total,
    required this.offset,
  });

  final List<AdminRoom> rooms;
  final int total;
  final int offset;

  @override
  DataRow? getRow(int index) {
    final int local = index - offset;
    if (local < 0 || local >= rooms.length) {
      return null;
    }
    final AdminRoom room = rooms[local];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Row(
          children: <Widget>[
            CircleAvatar(
              radius: 14,
              child: Text(initialsOf(room.displayName)),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(room.displayName)),
          ],
        )),
        DataCell(_TypeChip(isGroup: room.isGroup)),
        DataCell(Text(room.createdBy ?? '—')),
        DataCell(Text(formatDate(room.createdAt))),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.isGroup});

  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final Color color = isGroup ? AppColors.primary : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: AppSpacing.pillRadius,
      ),
      child: Text(
        isGroup ? 'Nhóm' : '1-1',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
