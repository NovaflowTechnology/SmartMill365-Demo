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
import 'package:smartmachine365/web_app_template/equipment_settings/addProductionLine.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/editProductionLine.dart';

const List<TableColumn> _plColumns = [
  TableColumn('No.', 'lineNo', 120),
  TableColumn('Production Line Name', 'name', 200, sortable: true),
  TableColumn('Production Area', 'productionArea', 180),
  TableColumn('Plant', 'factory_id', 150),
  TableColumn('Description', 'description', 250),
  TableColumn('Valid', 'valid', 100),
];

class ProductionLineSettingWidget extends StatefulWidget {
  const ProductionLineSettingWidget({super.key});

  @override
  State<ProductionLineSettingWidget> createState() => _ProductionLineSettingWidgetState();
}

class _ProductionLineSettingWidgetState extends State<ProductionLineSettingWidget> {
  List<Map<String, dynamic>> _lines = [];
  List<Map<String, dynamic>> _areas = [];
  Map<String, String> _plantNames = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
    _fetchAreas();
    _fetch();
  }

  Future<void> _fetchPlants() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.dataApiBaseSafe}/factory'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final map = <String, String>{};
        for (final p in data) {
          final id = p['id']?.toString() ?? '';
          final name = p['name']?.toString() ?? '';
          if (id.isNotEmpty) map[id] = name;
        }
        if (mounted) setState(() => _plantNames = map);
      }
    } catch (_) {}
  }

  Future<void> _fetchAreas() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.dataApiBaseSafe}/productionAreas'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        if (mounted) setState(() => _areas = data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final userId = AppStateNotifier.instance.uid ?? '';
      final userRole = AppStateNotifier.instance.userRole ?? '';
      final normalizedRole = AppRoles.normalizeRole(userRole);
      final factoryId = AppStateNotifier.instance.factoryId ?? '';
      final isSuperAdmin = normalizedRole == AppRoles.superAdmin;

      final params = <String, String>{};
      if (!isSuperAdmin) {
        if (userId.isNotEmpty) params['userId'] = userId;
        if (factoryId.isNotEmpty) params['factory_id'] = factoryId;
      }

      final uri = Uri.parse('${AppConfig.dataApiBaseSafe}/productionLines')
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri, headers: AppConfig.headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() => _lines = data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (e) {
      debugPrint('Error fetching production lines: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      final res =
          await http.delete(Uri.parse('${AppConfig.dataApiBaseSafe}/productionLines/$id'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        setState(() => _lines = _lines.where((l) => l['id'] != id).toList());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Production line deleted.', style: TextStyle(color: Colors.green)),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting production line: $e');
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
        title: Text('Delete Production Line',
            style: TextStyle(color: theme.txtPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('Delete "${row['name']}"? This cannot be undone.',
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
      builder: (_) => AddProductionLineDialog(onAdded: _fetch, userId: userId),
    );
  }

  void _showEdit(Map<String, dynamic> row) {
    final userId = AppStateNotifier.instance.uid ?? '';
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => EditProductionLineDialog(
        id: row['id'] as String,
        initialLineNo: row['lineNo']?.toString() ?? '',
        initialName: row['name']?.toString() ?? '',
        initialProductionArea: row['productionArea']?.toString() ?? '',
        initialDescription: row['description']?.toString() ?? '',
        initialValid: row['valid'] == true,
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
            fit: BoxFit.cover, image: Image.asset('assets/images/backgroundanimated.gif').image),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            breadcrumbs: [
              BreadcrumbItem(label: 'Settings', icon: Icons.settings),
              BreadcrumbItem(label: 'General Factory Setting'),
              BreadcrumbItem(label: 'Production Line'),
            ],
            title: 'Production Line',
            subtitle: 'Manage your production lines.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FE8)))
                  : DataTableWidget(
                      columns: _plColumns,
                      rows: _lines,
                      perPage: 13,
                      primaryKey: 'id',
                      primaryColumnKey: 'name',
                      primaryIcon: Icons.linear_scale_outlined,
                      sortKey: 'name',
                      cellBuilder: (key, value, row) {
                        if (key == 'factory_id') {
                          // Try both snake_case and camelCase
                          final pid = (row['factory_id'] ?? row['factoryId'])?.toString() ?? '';
                          String? pname = _plantNames[pid];
                          
                          // Fallback: lookup via production area if pid is missing
                          if (pname == null || pname.isEmpty) {
                            final areaName = row['productionArea']?.toString() ?? '';
                            if (areaName.isNotEmpty) {
                              final area = _areas.firstWhere(
                                (a) => a['name'] == areaName,
                                orElse: () => {},
                              );
                              final areaPid = area['factory_id']?.toString() ?? '';
                              pname = _plantNames[areaPid];
                            }
                          }

                          if (pname != null && pname.isNotEmpty) {
                            return Text(pname, overflow: TextOverflow.ellipsis);
                          }
                          return Text('—', style: TextStyle(color: Colors.white.withOpacity(0.3)));
                        }
                        return null;
                      },
                      onEdit: _showEdit,
                      onDelete: _onDelete,
                      onSelectionChanged: (ids) {},
                      showSelection: false,
                      showFilterDropdown: false,
                      actions: [
                        TableAction(
                            label: 'Add Production Line',
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
