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
import 'package:smartmachine365/web_app_template/equipment_settings/addAbnormalReason.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/editAbnormalReason.dart';

const List<TableColumn> _abnormalColumns = [
  TableColumn('Reason No.', 'reasonNo', 120),
  TableColumn('Reason Description', 'reasonDescription', 220, sortable: true),
  TableColumn('Type', 'type', 130),
  TableColumn('Production Area', 'productionArea', 180),
  TableColumn('Equipment Model', 'equipmentModel', 180),
];

class AbnormalReasonSettingWidget extends StatefulWidget {
  const AbnormalReasonSettingWidget({super.key});

  @override
  State<AbnormalReasonSettingWidget> createState() => _AbnormalReasonSettingWidgetState();
}

class _AbnormalReasonSettingWidgetState extends State<AbnormalReasonSettingWidget> {
  List<Map<String, dynamic>> _reasons = [];
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

      final uri = Uri.parse('${AppConfig.dataApiBaseSafe}/abnormalReasons')
          .replace(queryParameters: (!isSuperAdminOrAdmin && userId.isNotEmpty) ? {'userId': userId} : null);
      final res = await http.get(uri, headers: AppConfig.headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() => _reasons = data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (e) {
      debugPrint('Error fetching abnormal reasons: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('${AppConfig.dataApiBaseSafe}/abnormalReasons/$id'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        setState(() => _reasons.removeWhere((r) => r['id'] == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Abnormal reason deleted.', style: TextStyle(color: Colors.green)),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting abnormal reason: $e');
    }
  }

  void _onDelete(Map<String, dynamic> row) {
    final theme = FlutterFlowTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.cardStroke)),
        title: Text('Delete Abnormal Reason',
            style: TextStyle(
                color: theme.txtPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('Delete "${row['reasonDescription']}"? This cannot be undone.',
            style: TextStyle(color: theme.txtSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: theme.txtSecondary))),
          ElevatedButton(
            onPressed: () {
              _delete(row['id']);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74852), foregroundColor: Colors.white),
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
      builder: (_) => AddAbnormalReasonDialog(onAdded: _fetch, userId: userId),
    );
  }

  void _showEdit(Map<String, dynamic> row) {
    final userId = AppStateNotifier.instance.uid ?? '';
    final rawAreas = row['productionArea'];
    final rawEquipment = row['equipmentModel'];
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => EditAbnormalReasonDialog(
        id: row['id'] as String,
        initialReasonNo: row['reasonNo']?.toString() ?? '',
        initialReasonDescription: row['reasonDescription']?.toString() ?? '',
        initialType: row['type']?.toString() ?? '',
        initialProductionArea: rawAreas is List ? List<String>.from(rawAreas) : [],
        initialEquipmentModel: rawEquipment is List ? List<String>.from(rawEquipment) : [],
        userId: userId,
        onEdited: _fetch,
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
              BreadcrumbItem(label: 'Abnormal Reason Setting'),
            ],
            title: 'Abnormal Reason Setting',
            subtitle: 'Manage abnormal reason codes.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FE8)))
                  : DataTableWidget(
                      columns: _abnormalColumns,
                      rows: _reasons,
                      perPage: 13,
                      primaryKey: 'id',
                      primaryColumnKey: 'reasonDescription',
                      primaryIcon: Icons.warning_amber_outlined,
                      sortKey: 'reasonDescription',
                      onEdit: _showEdit,
                      onDelete: _onDelete,
                      onSelectionChanged: (ids) {},
                      showSelection: false,
                      showFilterDropdown: false,
                      actions: [
                        TableAction(
                            label: 'Add Abnormal Reason',
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
