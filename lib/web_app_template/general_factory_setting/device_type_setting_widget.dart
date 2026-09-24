import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/add_device_type_dialog.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/edit_device_type_dialog.dart';

const List<TableColumn> _deviceTypeColumns = [
  TableColumn('ID', 'id', 120),
  TableColumn('Device Type Name', 'name', 240, sortable: true),
];

class DeviceTypeSettingWidget extends StatefulWidget {
  const DeviceTypeSettingWidget({super.key});

  @override
  State<DeviceTypeSettingWidget> createState() => _DeviceTypeSettingWidgetState();
}

class _DeviceTypeSettingWidgetState extends State<DeviceTypeSettingWidget> {
  List<Map<String, dynamic>> _deviceTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.dataApiBaseSafe}/deviceTypes'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() => _deviceTypes = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Error fetching device types: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('${AppConfig.dataApiBaseSafe}/deviceTypes/$id'), headers: AppConfig.headers,
      );
      if (res.statusCode == 200) {
        setState(() => _deviceTypes.removeWhere((dt) => dt['id'] == id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device type deleted.', style: TextStyle(color: Colors.green)),
              backgroundColor: Colors.black,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting device type: $e');
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
          side: BorderSide(color: theme.cardStroke),
        ),
        title: Text(
          'Delete Device Type',
          style: TextStyle(color: theme.txtPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete "${row['name']}"? This cannot be undone.',
          style: TextStyle(color: theme.txtSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: theme.txtSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _delete(row['id'].toString());
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74852),
              foregroundColor: Colors.white,
            ),
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
      builder: (_) => AddDeviceTypeDialog(onAdded: _fetch),
    );
  }

  void _onEdit(Map<String, dynamic> row) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => EditDeviceTypeDialog(initialData: row, onUpdated: _fetch),
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
              BreadcrumbItem(label: 'Device Type Setting'),
            ],
            title: 'Device Type Setting',
            subtitle: 'Manage device types for equipment.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C3FE8)),
                    )
                  : DataTableWidget(
                      columns: _deviceTypeColumns,
                      rows: _deviceTypes,
                      perPage: 13,
                      primaryKey: 'id',
                      primaryColumnKey: 'name',
                      primaryIcon: Icons.devices_other_outlined,
                      sortKey: 'name',
                      onEdit: _onEdit,
                      onDelete: _onDelete,
                      onSelectionChanged: (ids) {},
                      showSelection: false,
                      showFilterDropdown: false,
                      actions: [
                        TableAction(
                          label: 'Add Device Type',
                          icon: Icons.add,
                          isPrimary: true,
                          onTap: _showAdd,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
