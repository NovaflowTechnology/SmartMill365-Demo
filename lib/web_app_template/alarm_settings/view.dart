import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/firestore_service.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/add.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/esop.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/edit.dart';
import 'package:smartmachine365/services/app_config.dart';

const List<TableColumn> _alarmColumns = [
  TableColumn('Alarm ID',        'id',                  90),
  TableColumn('Equipment',       'equipment_name',      150),
  TableColumn('Device',          'device_name',         140),
  TableColumn('Alarm Name',      'name',                150, sortable: true),
  TableColumn('Message',         'message',             160),
  TableColumn('Min Value',       'threshold_minimum',   90),
  TableColumn('Max Value',       'threshold_maximum',   90),
  TableColumn('PIC',             'pic',                 100),
  TableColumn('Status',          'status',              120),
];

class AlarmView extends StatefulWidget {
  const AlarmView({super.key, required this.companyID, required this.userRole});
  final String companyID;
  final String userRole;
  @override
  State<AlarmView> createState() => _AlarmViewState();
}

class _AlarmViewState extends State<AlarmView> {
  List<Map<String, dynamic>> _alarms = [];
  Map<String, String> _deviceIdToName = {};
  Map<String, String> _deviceIdToEquipmentId = {};
  Map<String, String> _equipmentIdToName = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();

      final responses = await Future.wait([
        http.get(Uri.parse('${AppConfig.dataApiBaseSafe}/equipment'), headers: AppConfig.headers),
        http.get(Uri.parse('${AppConfig.dataApiBaseSafe}/devices'), headers: AppConfig.headers),
      ]);

      if (responses[0].statusCode == 200) {
        final List<dynamic> equipments = json.decode(responses[0].body);
        _equipmentIdToName = {for (var e in equipments) e['id'] as String: (e['name'] ?? '') as String};
      }
      if (responses[1].statusCode == 200) {
        final List<dynamic> devices = json.decode(responses[1].body);
        _deviceIdToName = {for (var d in devices) d['id'] as String: (d['device_name'] ?? '') as String};
        _deviceIdToEquipmentId = {for (var d in devices) d['id'] as String: (d['equipment_id'] ?? '0') as String};
      }

      final alarmUri = widget.userRole == 'Super Admin'
          ? Uri.parse('${AppConfig.dataApiBaseSafe}/alarms')
          : Uri.parse('${AppConfig.dataApiBaseSafe}/alarms').replace(queryParameters: {'company_id': widget.companyID});

      final alarmRes = await http.get(alarmUri, headers: AppConfig.headers);
      if (alarmRes.statusCode == 200) {
        final List<dynamic> raw = json.decode(alarmRes.body);
        setState(() {
          _alarms = raw.map((a) {
            final map = Map<String, dynamic>.from(a as Map);
            final devId = map['device_id'] as String? ?? '0';
            final eqId = _deviceIdToEquipmentId[devId] ?? '0';
            return {
              ...map,
              'device_name': devId == '0' ? 'Not assigned' : (_deviceIdToName[devId] ?? 'Unknown'),
              'equipment_name': (devId == '0' || eqId == '0') ? 'Not assigned' : (_equipmentIdToName[eqId] ?? 'Unknown'),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget? _cellBuilder(String key, String value, Map<String, dynamic> row) {
    if (key == 'id') return Text('#${value.padLeft(5, '0')}', overflow: TextOverflow.ellipsis);
    if (key == 'status') {
      final ok = row['status'] == true;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ok ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(ok ? 'No Issue' : 'Action Required',
            style: TextStyle(color: ok ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
      );
    }
    return null;
  }

  Widget? _actionBuilder(Map<String, dynamic> row) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = isLight ? const Color(0xFF2563EB) : const Color(0xFF00D4FF);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      TextButton(
        onPressed: () => _showESOPDialog(row['id'], row['esop'] ?? ''),
        style: TextButton.styleFrom(foregroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 8)),
        child: const Text('ESOP', style: TextStyle(fontSize: 11)),
      ),
      IconButton(icon: Icon(Icons.edit, size: 16, color: accent), onPressed: () => _showEdit(row), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
      IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE74852)), onPressed: () => _confirmDelete(row), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
    ]);
  }

  void _confirmDelete(Map<String, dynamic> row) {
    final theme = FlutterFlowTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.cardStroke)),
        title: Text('Delete Alarm', style: TextStyle(color: theme.txtPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('Delete "${row['name']}"? This cannot be undone.', style: TextStyle(color: theme.txtSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: TextStyle(color: theme.txtSecondary))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final delRes = await http.delete(
                  Uri.parse('${AppConfig.dataApiBaseSafe}/alarms/${row['id']}'),
                  headers: AppConfig.headers,
                );
                if (delRes.statusCode != 200) throw Exception('Delete failed');
                setState(() => _alarms.removeWhere((a) => a['id'] == row['id']));
              } catch (e) { debugPrint('$e'); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74852), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAdd() => showDialog(barrierDismissible: false, context: context,
      builder: (_) => AddAlarmDialog(companyId: widget.companyID, firestoreService: FirestoreService(), onAlarmAdded: _fetchAll));

  void _showESOPDialog(String id, String esop) => showDialog(barrierDismissible: false, context: context,
      builder: (_) => showESOPDialog(firestoreService: FirestoreService(), id: id, esop: esop, onAlarmAdded: _fetchAll));

  void _showEdit(Map<String, dynamic> row) => showDialog(barrierDismissible: false, context: context,
      builder: (_) => EditAlarmDialog(
        id: row['id'], initialName: row['name'], initialDevice: row['device_id'],
        initialMessage: row['message'], initialMinValue: row['threshold_minimum'],
        initialMaxValue: row['threshold_maximum'], initialPIC: row['pic'],
        initialESOP: row['esop'] ?? '', firestoreService: FirestoreService(), onAlarmAdded: _fetchAll,
      ));

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
              BreadcrumbItem(label: 'Alarm'),
            ],
            title: 'Alarm',
            subtitle: 'Manage your alarm settings.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FE8)))
                  : DataTableWidget(
                      columns: _alarmColumns,
                      rows: _alarms,
                      perPage: 13,
                      primaryKey: 'id',
                      primaryColumnKey: 'name',
                      primarySubtitleKey: 'device_name',
                      primaryIcon: Icons.notifications_outlined,
                      sortKey: 'name',
                      cellBuilder: _cellBuilder,
                      actionBuilder: _actionBuilder,
                      onSelectionChanged: (ids) {},
                      showSelection: false,
                      showFilterDropdown: false,
                      actions: [
                        TableAction(label: 'Add Alarm', icon: Icons.add, isPrimary: true, onTap: _showAdd),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
