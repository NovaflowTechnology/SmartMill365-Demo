import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';
import 'package:smartmachine365/flutter_flow/rbac.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'cubits/equipment_category_cubit.dart';
import 'services/equipment_category_service.dart';
import 'dialogs/equipment_category_dialogs.dart';

class EquipmentCategorySettingWidget extends StatefulWidget {
  const EquipmentCategorySettingWidget({super.key});

  @override
  State<EquipmentCategorySettingWidget> createState() =>
      _EquipmentCategorySettingWidgetState();
}

class _EquipmentCategorySettingWidgetState
    extends State<EquipmentCategorySettingWidget> {
  late EquipmentCategoryCubit _cubit;

  @override
  void initState() {
    super.initState();
    final appState = AppStateNotifier.instance;
    _cubit = EquipmentCategoryCubit(
      service: EquipmentCategoryService(),
      factoryId: appState.factoryId ?? '',
      userId: appState.uid ?? '',
    );
    _cubit.fetchAll();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool get _canEdit {
    final role =
        AppRoles.normalizeRole(AppStateNotifier.instance.userRole ?? '');
    return role == AppRoles.superAdmin || role == AppRoles.admin;
  }

  // ── Category Group dialogs ─────────────────────────────────────────────────
  void _showAddGroupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCategoryGroupDialog(
        onSave: (data) => _cubit.createGroup(data),
      ),
    );
  }

  void _showEditGroupDialog(Map<String, dynamic> row) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditCategoryGroupDialog(
        initialData: row,
        onSave: (data) =>
            _cubit.updateGroup(row['id']?.toString() ?? '', data),
      ),
    );
  }

  void _showDeleteGroupDialog(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteDialog(
        title: 'Delete Equipment Category',
        message:
            'Are you sure you want to delete "${row['name']}"? This cannot be undone.',
        onConfirm: () => _cubit.deleteGroup(row['id']?.toString() ?? ''),
      ),
    );
  }

  // ── Equipment Type dialogs ─────────────────────────────────────────────────
  void _showAddTypeDialog(List<Map<String, dynamic>> groups) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEquipmentCategoryDialog(
        categoryGroups: groups,
        onSave: (data) => _cubit.createCategory(data),
      ),
    );
  }

  void _showEditTypeDialog(
      Map<String, dynamic> row, List<Map<String, dynamic>> groups) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditEquipmentCategoryDialog(
        initialData: row,
        categoryGroups: groups,
        onSave: (data) =>
            _cubit.updateCategory(row['id']?.toString() ?? '', data),
      ),
    );
  }

  void _showDeleteTypeDialog(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteDialog(
        title: 'Delete Equipment Type',
        message:
            'Are you sure you want to delete "${row['device_type']}"? This cannot be undone.',
        onConfirm: () => _cubit.deleteCategory(row['id']?.toString() ?? ''),
      ),
    );
  }

  // ── Badge builder (shared by both tables) ─────────────────────────────────
  _CategoryBadgeStyle _styleForCategoryCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return const _CategoryBadgeStyle(
        background: Color(0x141E293B),
        border: Color(0xFF64748B),
        text: Color(0xFFE2E8F0),
      );
    }

    // Curated global palette for better readability on dark UI.
    // New categories automatically map by hash (no per-code hardcoding needed).
    const palette = <_CategoryBadgeStyle>[
      _CategoryBadgeStyle(
        background: Color(0xFF0B2E59),
        border: Color(0xFF0284C7),
        text: Color(0xFF7DD3FC),
      ),
      _CategoryBadgeStyle(
        background: Color(0xFF122B1F),
        border: Color(0xFF16A34A),
        text: Color(0xFF86EFAC),
      ),
      _CategoryBadgeStyle(
        background: Color(0xFF21153A),
        border: Color(0xFF8B5CF6),
        text: Color(0xFFC4B5FD),
      ),
      _CategoryBadgeStyle(
        background: Color(0xFF33210C),
        border: Color(0xFFF59E0B),
        text: Color(0xFFFCD34D),
      ),
      _CategoryBadgeStyle(
        background: Color(0xFF102A36),
        border: Color(0xFF06B6D4),
        text: Color(0xFF67E8F9),
      ),
      _CategoryBadgeStyle(
        background: Color(0xFF2E1D2C),
        border: Color(0xFFEC4899),
        text: Color(0xFFF9A8D4),
      ),
    ];

    final hash = code.codeUnits.fold<int>(0, (sum, c) => (sum * 31 + c) & 0x7fffffff);
    return palette[hash % palette.length];
  }

  Widget _codeBadge(String code) {
    final style = _styleForCategoryCode(code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: style.border, width: 1.0),
      ),
      child: Text(
        code,
        style: TextStyle(
            color: style.text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          image: DecorationImage(
            fit: BoxFit.cover,
            image: Image.asset('assets/images/backgroundanimated.gif').image,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              breadcrumbs: [
                BreadcrumbItem(label: 'Settings', icon: Icons.settings),
                BreadcrumbItem(label: 'General Factory Setting'),
                BreadcrumbItem(label: 'Equipment Category'),
              ],
              title: 'Equipment Category',
              subtitle: 'Manage top-level categories and their device types.',
            ),
            Expanded(
              child: BlocBuilder<EquipmentCategoryCubit, EquipmentCategoryState>(
                builder: (context, state) {
                  if (state is EquipmentCategoryLoading ||
                      state is EquipmentCategoryInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00D4FF)),
                    );
                  }

                  if (state is EquipmentCategoryError) {
                    return Center(
                      child: Text(state.message,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 16)),
                    );
                  }

                  final loaded = state as EquipmentCategoryPageLoaded;
                  final groups = loaded.categoryGroups;
                  final types  = loaded.equipmentTypes;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── SECTION 1: Equipment Category ──────────────────
                        _sectionLabel('Equipment Category'),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 380,
                          child: DataTableWidget(
                            columns: const [
                              TableColumn(
                                  'Equipment Category', 'name', 280,
                                  sortable: true),
                              TableColumn(
                                  'Category Code', 'category_code', 150),
                            ],
                            rows: groups,
                            perPage: 10,
                            primaryKey: 'id',
                            primaryColumnKey: 'name',
                            primaryIcon: Icons.label_outline,
                            sortKey: 'name',
                            showSelection: false,
                            showFilterDropdown: false,
                            onEdit: _canEdit ? _showEditGroupDialog : null,
                            onDelete:
                                _canEdit ? _showDeleteGroupDialog : null,
                            onSelectionChanged: (_) {},
                            cellBuilder: (columnKey, value, row) {
                              if (columnKey == 'category_code') {
                                return _codeBadge(
                                    value?.toString() ?? '');
                              }
                              return null;
                            },
                            actions: [
                              if (_canEdit)
                                TableAction(
                                  label: 'Add Category',
                                  icon: Icons.add_box_outlined,
                                  isPrimary: true,
                                  onTap: _showAddGroupDialog,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── SECTION 2: Equipment Type ──────────────────────
                        _sectionLabel('Equipment Type'),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 520,
                          child: DataTableWidget(
                            columns: const [
                              TableColumn('Device Type', 'device_type', 200,
                                  sortable: true),
                              TableColumn('Device Code', 'device_code', 110),
                              TableColumn('Equipment Category',
                                  'equipment_category', 200),
                              TableColumn(
                                  'Category Code', 'category_code', 130),
                            ],
                            rows: types,
                            perPage: 10,
                            primaryKey: 'id',
                            primaryColumnKey: 'device_type',
                            primaryIcon: Icons.precision_manufacturing_outlined,
                            sortKey: 'device_type',
                            showSelection: false,
                            showFilterDropdown: false,
                            onEdit: _canEdit
                                ? (row) => _showEditTypeDialog(row, groups)
                                : null,
                            onDelete:
                                _canEdit ? _showDeleteTypeDialog : null,
                            onSelectionChanged: (_) {},
                            cellBuilder: (columnKey, value, row) {
                              if (columnKey == 'equipment_category') {
                                final catCode =
                                    row['category_code']?.toString() ?? '';
                                final style = _styleForCategoryCode(catCode);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: style.background,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: style.border, width: 1.0),
                                  ),
                                  child: Text(
                                    value?.toString() ?? '',
                                    style: TextStyle(
                                        color: style.text,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4),
                                  ),
                                );
                              }
                              return null;
                            },
                            actions: [
                              if (_canEdit)
                                TableAction(
                                  label: 'Add Equipment Type',
                                  icon: Icons.add_box_outlined,
                                  isPrimary: true,
                                  onTap: () => _showAddTypeDialog(groups),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(children: [
      Container(
        width: 3,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF00D4FF),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    ]);
  }
}

class _CategoryBadgeStyle {
  final Color background;
  final Color border;
  final Color text;

  const _CategoryBadgeStyle({
    required this.background,
    required this.border,
    required this.text,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE CONFIRMATION DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final Future<bool> Function() onConfirm;

  const _DeleteDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0E1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF00D4FF), width: 1),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 18,
              fontWeight: FontWeight.w600)),
      content: Text(message,
          style: const TextStyle(color: Color(0xFF6B7FA3), fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              const Text('CANCEL', style: TextStyle(color: Color(0xFF6B7FA3))),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74852),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('DELETE'),
        ),
      ],
    );
  }
}
