import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '/flutter_flow/rbac.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/addProductionArea.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/edit_production_area.dart';

const List<TableColumn> _paColumns = [
  TableColumn('ID', 'id', 120),
  TableColumn('Production Area Name', 'name', 200, sortable: true),
  TableColumn('Plant', 'factory_id', 160),
];

class ProductionAreaSettingWidget extends StatefulWidget {
  final String factoryId;
  final String userRole;

  const ProductionAreaSettingWidget({
    super.key,
    required this.factoryId,
    this.userRole = '',
  });

  @override
  State<ProductionAreaSettingWidget> createState() =>
      _ProductionAreaSettingWidgetState();
}

class _ProductionAreaSettingWidgetState
    extends State<ProductionAreaSettingWidget> {
  List<Map<String, dynamic>> _areas = [];
  Map<String, String> _plantNames = {};
  bool _isLoading = false;

  bool get _isSuperAdmin =>
      AppRoles.normalizeRole(widget.userRole) == AppRoles.superAdmin;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
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

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final userId = AppStateNotifier.instance.uid ?? '';
      final userRole = AppStateNotifier.instance.userRole ?? '';
      final normalizedRole = AppRoles.normalizeRole(userRole);
      final isSuperAdminOrAdmin = normalizedRole == AppRoles.superAdmin || normalizedRole == AppRoles.admin;

      final params = <String, String>{};
      if (!isSuperAdminOrAdmin) {
        if (userId.isNotEmpty) params['userId'] = userId;
        if (widget.factoryId.isNotEmpty) {
          params['factory_id'] = widget.factoryId;
        }
      }

      final uri =
          Uri.parse('${AppConfig.dataApiBaseSafe}/productionAreas')
              .replace(
        queryParameters: params.isNotEmpty ? params : null,
      );
      final res = await http.get(uri, headers: AppConfig.headers);
      debugPrint('Fetching Production Areas from: $uri');
      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() => _areas = data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (e) {
      debugPrint('Error fetching production areas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String name) async {
    try {
      final res = await http.delete(
          Uri.parse('${AppConfig.dataApiBaseSafe}/productionAreas/$name'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        setState(() => _areas.removeWhere((a) => a['name'] == name));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Production area deleted.',
                    style: TextStyle(color: Colors.green)),
                backgroundColor: Colors.black,
                duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting production area: $e');
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
        title: Text('Delete Production Area',
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
              _delete(row['name']);
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
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AddProductionAreaDialog(
        factoryId: widget.factoryId,
        onEquipmentAdded: _fetch,
        userRole: widget.userRole,
      ),
    );
  }

  void _onEdit(Map<String, dynamic> row) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => EditProductionAreaDialog(
        initialData: row,
        onUpdated: _fetch,
        userRole: widget.userRole,
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
              BreadcrumbItem(label: 'Production Area'),
            ],
            title: 'Production Area',
            subtitle: 'Manage your production areas.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C3FE8)))
                  : DataTableWidget(
                      columns: _paColumns,
                      rows: _areas,
                      perPage: 13,
                      primaryKey: 'id',
                      primaryColumnKey: 'name',
                      primaryIcon: Icons.domain_outlined,
                      sortKey: 'name',
                      cellBuilder: (key, value, row) {
                        if (key == 'factory_id') {
                          final pid = row['factory_id']?.toString() ?? '';
                          final pname = _plantNames[pid];
                          if (pname != null && pname.isNotEmpty) {
                            return Text(pname, overflow: TextOverflow.ellipsis);
                          }
                          return Text('—', style: TextStyle(color: Colors.white.withOpacity(0.3)));
                        }
                        return null;
                      },
                      onEdit: _isSuperAdmin ? _onEdit : null,
                      onDelete: _onDelete,
                      onSelectionChanged: (ids) {},
                      showSelection: false,
                      showFilterDropdown: false,
                      actions: [
                        TableAction(
                            label: 'Add Production Area',
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
