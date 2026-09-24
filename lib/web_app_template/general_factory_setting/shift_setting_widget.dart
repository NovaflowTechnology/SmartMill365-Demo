import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/rbac.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/add_shift_dialog.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/edit_shift_dialog.dart';

const List<TableColumn> _shiftColumns = [
  TableColumn('Shift Code', 'code', 130),
  TableColumn('Shift Name', 'name', 180, sortable: true),
  TableColumn('Start Work Time', 'startWorkTime', 150),
  TableColumn('Finish Work Time', 'finishWorkTime', 150),
  TableColumn('Shift Rest Time', 'shiftRestTimeSummary', 200),
  TableColumn('Valid', 'valid', 80),
];

class ShiftSettingWidget extends StatefulWidget {
  const ShiftSettingWidget({super.key});

  @override
  State<ShiftSettingWidget> createState() => _ShiftSettingWidgetState();
}

class _ShiftSettingWidgetState extends State<ShiftSettingWidget> {
  List<Map<String, dynamic>> _shifts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final userId = AppStateNotifier.instance.uid ?? '';
      final userRole = AppStateNotifier.instance.userRole ?? '';
      final normalizedRole = AppRoles.normalizeRole(userRole);
      final isSuperAdminOrAdmin = normalizedRole == AppRoles.superAdmin || normalizedRole == AppRoles.admin;

      final uri = Uri.parse('${AppConfig.dataApiBaseSafe}/shifts')
          .replace(queryParameters: (!isSuperAdminOrAdmin && userId.isNotEmpty) ? {'userId': userId} : null);
      final res = await http.get(uri, headers: AppConfig.headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final shifts = data.map((e) => Map<String, dynamic>.from(e as Map)).toList().map((s) {
          final restTimes = s['restTimes'];
          String summary = '--';
          if (restTimes is List && restTimes.isNotEmpty) {
            summary = restTimes.map((r) {
              final start = r['startRestTime'] ?? '';
              final end = r['endRestTime'] ?? '';
              return '$start - $end';
            }).join(', ');
          }
          return {...s, 'shiftRestTimeSummary': summary};
        }).toList();
        setState(() => _shifts = shifts);
      }
    } catch (e) {
      debugPrint('Error fetching shifts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      final res = await http.delete(
          Uri.parse('${AppConfig.dataApiBaseSafe}/shifts/$id'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        setState(() => _shifts.removeWhere((s) => s['id'] == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shift deleted.',
                  style: TextStyle(color: Colors.green)),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting shift: $e');
    }
  }

  void _onDelete(Map<String, dynamic> row) {
    final theme = FlutterFlowTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.cardStroke)),
        title: Text('Delete Shift',
            style: TextStyle(
                color: theme.txtPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        content: Text('Delete "${row['name']}"? This cannot be undone.',
            style: TextStyle(color: theme.txtSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: theme.txtSecondary))),
          ElevatedButton(
            onPressed: () {
              _delete(row['id'] as String);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74852),
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAdd() {
    final userId = AppStateNotifier.instance.uid ?? '';
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AddShiftDialog(onAdded: _fetch, userId: userId),
    );
  }

  void _showEdit(Map<String, dynamic> row) {
    final rawRestTimes = row['restTimes'];
    final restTimes = rawRestTimes is List
        ? rawRestTimes.map((r) => Map<String, String>.from({
              'startRestTime': r['startRestTime']?.toString() ?? '',
              'endRestTime': r['endRestTime']?.toString() ?? '',
            })).toList()
        : <Map<String, String>>[];

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => EditShiftDialog(
        id: row['id'] as String,
        initialCode: row['code']?.toString() ?? '',
        initialName: row['name']?.toString() ?? '',
        initialStartWorkTime: row['startWorkTime']?.toString() ?? '',
        initialFinishWorkTime: row['finishWorkTime']?.toString() ?? '',
        initialValid: row['valid'] == true,
        initialRestTimes: restTimes,
        onEdited: _fetch,
      ),
    );
  }

  Widget _buildValidCell(bool isValid) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: isValid,
        onChanged: null,
        activeColor: const Color(0xFF7A68FF),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF7A68FF).withOpacity(0.4);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        image: DecorationImage(
            fit: BoxFit.cover,
            image: Image.asset('assets/images/backgroundanimated.gif').image),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            breadcrumbs: [
              BreadcrumbItem(label: 'Settings', icon: Icons.settings),
              BreadcrumbItem(label: 'General Factory Setting'),
              BreadcrumbItem(label: 'Shift'),
            ],
            title: 'Shift',
            subtitle: 'Manage your shift schedules and rest times.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C3FE8)))
                  : DataTableWidget(
                      columns: _shiftColumns,
                      rows: _shifts,
                      perPage: 13,
                      primaryKey: 'id',
                      primaryColumnKey: 'name',
                      primaryIcon: Icons.access_time_outlined,
                      sortKey: 'name',
                      onEdit: _showEdit,
                      onDelete: _onDelete,
                      onSelectionChanged: (ids) {},
                      showSelection: false,
                      showFilterDropdown: false,
                      cellBuilder: (key, value, row) {
                        if (key == 'valid') {
                          final isValid = row['valid'] == true;
                          return _buildValidCell(isValid);
                        }
                        if (key == 'startWorkTime' || key == 'finishWorkTime') {
                          return Text(
                            value.isEmpty ? '--' : value,
                            style: TextStyle(
                              color: value.isEmpty
                                  ? theme.txtTertiary
                                  : theme.txtPrimary,
                              fontSize: 13,
                            ),
                          );
                        }
                        if (key == 'shiftRestTimeSummary') {
                          return Text(
                            value,
                            style: TextStyle(
                              color: value == '--'
                                  ? theme.txtTertiary
                                  : theme.txtSecondary,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      },
                      actions: [
                        TableAction(
                            label: 'Add Shift',
                            icon: Icons.add,
                            isPrimary: true,
                            onTap: _showAdd),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
