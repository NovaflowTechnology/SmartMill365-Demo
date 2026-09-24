import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/rbac.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/addFactory.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/edit_factory.dart';

const List<TableColumn> _plantColumns = [
  TableColumn('ID', 'id', 120),
  TableColumn('Plant Name', 'name', 200, sortable: true),
  TableColumn('Client', 'client_name', 180),
  TableColumn('Discovery Plant ID', 'discovery_plant_id', 200),
];

class PlantSettingWidget extends StatefulWidget {
  final String userRole;
  final String factoryId;
  const PlantSettingWidget({super.key, required this.userRole, required this.factoryId});

  @override
  State<PlantSettingWidget> createState() => _PlantSettingWidgetState();
}

class _PlantSettingWidgetState extends State<PlantSettingWidget> {
  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _clients = [];
  Map<String, String> _clientMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final factoryUrl = '${AppConfig.dataApiBaseSafe}/factory';
      final configUrl = '${AppConfig.dataApiBaseSafe}/integrationConfig/loadConfigs';
      final results = await Future.wait([
        http.get(Uri.parse(factoryUrl), headers: AppConfig.headers),
        http.get(Uri.parse(configUrl)),
      ]);

      final res       = results[0];
      final configRes = results[1];

      final clientMap = <String, String>{};
      final clients   = <Map<String, dynamic>>[];

      if (configRes.statusCode == 200) {
        final List<dynamic> configList = json.decode(configRes.body);
        for (final m in configList) {
          final id   = m['id']?.toString() ?? '';
          final name = m['name']?.toString() ?? m['code']?.toString() ?? '';
          if (id.isNotEmpty && name.isNotEmpty) {
            clientMap[id] = name;
            // A customer site offers only its own client in the picker; the
            // name map stays complete so existing plants keep their label.
            if (AppConfig.showsClient(id)) clients.add({'id': id, 'name': name});
          }
        }
        clients.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      }

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final activeClientId = AppConfig.clientId;
        var plants = data.cast<Map<String, dynamic>>().map((p) {
          final cid = (p['customer_id']?.toString() ?? '').isNotEmpty
              ? p['customer_id'].toString()
              : activeClientId;
          return {...p, 'customer_id': cid, 'client_name': clientMap[cid] ?? ''};
        }).toList();
        final isSuperAdmin = AppRoles.normalizeRole(widget.userRole) == AppRoles.superAdmin;
        if (!isSuperAdmin && widget.factoryId.isNotEmpty) {
          plants = plants.where((p) => p['id'] == widget.factoryId).toList();
        }
        setState(() {
          _plants = plants;
          _clients = clients;
          _clientMap = clientMap;
        });

        // Auto-clear plants whose assigned client was removed from integration_config
        final orphaned = plants.where((p) {
          final cid = p['customer_id']?.toString() ?? '';
          return cid.isNotEmpty && !clientMap.containsKey(cid);
        }).toList();
        for (final plant in orphaned) {
          _updateClient(plant, null);
        }
      }
    } catch (e) {
      debugPrint('Error fetching plants: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateClient(Map<String, dynamic> row, String? customerId) async {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return;

    // Optimistic update — replace the list so DataTableWidget detects the change
    final idx = _plants.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      setState(() {
        _plants = [
          for (int i = 0; i < _plants.length; i++)
            if (i == idx)
              {
                ..._plants[i],
                'customer_id': customerId ?? '',
                'client_name': _clientMap[customerId ?? ''] ?? '',
              }
            else
              _plants[i],
        ];
      });
    }

    try {
      final body = <String, dynamic>{
        'name': row['name'] ?? '',
        'customer_id': customerId ?? '',
        'discovery_plant_id': row['discovery_plant_id'] ?? '',
      };
      final res = await http.put(
        Uri.parse('${AppConfig.dataApiBaseSafe}/factory/$id'),
        headers: AppConfig.headers,
        body: json.encode(body),
      );
      if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 204) {
        debugPrint('Failed to update client on server: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
    }
  }

  Future<void> _delete(String name) async {
    try {
      final res = await http.delete(Uri.parse('${AppConfig.dataApiBaseSafe}/factory/$name'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        setState(() => _plants.removeWhere((p) => p['name'] == name));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plant deleted.', style: TextStyle(color: Colors.green)), backgroundColor: Colors.black, duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting plant: $e');
    }
  }

  void _onDelete(Map<String, dynamic> row) {
    final theme = FlutterFlowTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.cardStroke)),
        title: Text('Delete Plant', style: TextStyle(color: theme.txtPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('Delete "${row['name']}"? This cannot be undone.', style: TextStyle(color: theme.txtSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: TextStyle(color: theme.txtSecondary))),
          ElevatedButton(
            onPressed: () { _delete(row['name']); Navigator.of(ctx).pop(); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74852), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool get _isSuperAdmin =>
      AppRoles.normalizeRole(widget.userRole) == AppRoles.superAdmin;

  void _showAdd() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AddFactoryDialog(
        onEquipmentAdded: () {},
        userRole: widget.userRole,
      ),
    ).then((_) => _fetch());
  }

  void _onEdit(Map<String, dynamic> row) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => EditFactoryDialog(
        initialData: row,
        onUpdated: () {},
        userRole: widget.userRole,
      ),
    ).then((_) => _fetch());
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        image: DecorationImage(fit: BoxFit.cover, image: Image.asset('assets/images/backgroundanimated.gif').image),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          breadcrumbs: [
            BreadcrumbItem(label: 'Settings', icon: Icons.settings),
            BreadcrumbItem(label: 'General Factory Setting'),
            BreadcrumbItem(label: 'Plant'),
          ],
          title: 'Plant',
          subtitle: 'Manage your plants / factories.',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FE8)))
                : DataTableWidget(
                    columns: _plantColumns,
                    rows: _plants,
                    perPage: 13,
                    primaryKey: 'id',
                    primaryColumnKey: 'name',
                    primaryIcon: Icons.factory_outlined,
                    sortKey: 'name',
                    onEdit: _isSuperAdmin ? _onEdit : null,
                    onDelete: _onDelete,
                    onSelectionChanged: (ids) {},
                    showSelection: false,
                    showFilterDropdown: false,
                    cellBuilder: (key, value, row) {
                      if (key != 'client_name') return null;
                      final currentId = row['customer_id']?.toString() ?? '';
                      final validId = _clients.any((c) => c['id'] == currentId) ? currentId : null;
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: validId,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A2A4A),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF8B949E)),
                          hint: const Text('— none —', style: TextStyle(color: Color(0xFF4B5563), fontSize: 12)),
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('— none —', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
                            ..._clients.map((c) => DropdownMenuItem<String>(
                                  value: c['id'] as String,
                                  child: Text(c['name'] as String, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
                                )),
                          ],
                          onChanged: (v) => _updateClient(row, v),
                        ),
                      );
                    },
                    actions: [
                      TableAction(label: 'Add Plant', icon: Icons.add, isPrimary: true, onTap: _showAdd),
                    ],
                  ),
          ),
        ),
      ],
      ),
    );
  }
}
