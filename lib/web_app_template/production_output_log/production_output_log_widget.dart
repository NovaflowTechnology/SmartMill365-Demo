import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/filter/date_filter_btn.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/web_app_template/product_settings/firestore_service.dart';
import 'widgets/delete_dialog.dart';
import 'widgets/entry_dialog.dart';
import 'services/production_output_service.dart';

class ProductionOutputLogWidget extends StatefulWidget {
  const ProductionOutputLogWidget({super.key});

  @override
  State<ProductionOutputLogWidget> createState() => _ProductionOutputLogWidgetState();
}

class _ProductionOutputLogWidgetState extends State<ProductionOutputLogWidget> {
  static const List<TableColumn> _columns = [
    TableColumn('Date', 'date', 110, sortable: true),
    TableColumn('Time', 'time', 120),
    TableColumn('Machine', 'machine', 100),
    TableColumn('Work Order No.', 'workOrderNumber', 150),
    TableColumn('Product', 'product', 120),
    TableColumn('Process Dept.', 'processDepartment', 140),
    TableColumn('Previous Reading', 'previousReading', 130),
    TableColumn('Meter Reading Now', 'meterReadingNow', 140),
    TableColumn('kWh', 'kwh', 80),
    TableColumn('Tonnes', 'tonnes', 80),
    TableColumn('Report By', 'reportBy', 110),
  ];

  static const _departments = ['Fabrication', 'Finishing', 'Assembly'];

  List<Map<String, dynamic>> _entries = [];
  List<String> _machines = ['CNC-01', 'CNC-02', 'Mixer-1', 'Press-A', 'Press-B'];
  List<String> _productNames = [];
  bool _isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> get _filteredEntries {
    if (_startDate == null && _endDate == null) return _entries;
    return _entries.where((e) {
      final d = DateTime.tryParse(e['date']?.toString() ?? '');
      if (d == null) return false;
      final date = DateTime(d.year, d.month, d.day);
      if (_startDate != null && date.isBefore(_startDate!)) return false;
      if (_endDate != null && date.isAfter(_endDate!)) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadDropdowns();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await ProductionOutputService.getAll();
    if (!mounted) return;
    setState(() {
      _entries = data;
      _isLoading = false;
    });
  }

  Future<void> _loadDropdowns() async {
    final results = await Future.wait([
      ProductionOutputService.getMachineNames(),
      FirestoreService().fetchProduct(),
    ]);
    if (!mounted) return;
    final machines = results[0] as List<String>;
    final products = results[1] as List<Map<String, dynamic>>;
    setState(() {
      if (machines.isNotEmpty) _machines = machines;
      _productNames = products.map((p) => p['name']?.toString() ?? '').where((n) => n.isNotEmpty).toSet().toList();
    });
  }

  // Maps EntryDialog's camelCase output → MySQL column names for KwhDataLogService
  Map<String, dynamic> _toMysqlFields(Map<String, dynamic> data) {
    return {
      'date': data['date'],
      'machine_id': data['machine'],
      'product_type': data['product'] ?? '',
      'zone_id': data['processDepartment'] ?? '',
      'kWh_consumed': data['kwh'] ?? 0,
      'tonnes_produced': data['tonnes'] ?? 0,
    };
  }

  // ── Dialog launchers ──────────────────────────────────────────────────────

  void _showAdd() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EntryDialog(
        machines: _machines,
        departments: _departments,
        productNames: _productNames,
        onSubmit: (data) async {
          await ProductionOutputService.create(data);
          if (!mounted) return;
          Navigator.of(context).pop();
          await _load();
          _snack('Entry added successfully');
        },
      ),
    );
  }

  void _showEdit(Map<String, dynamic> row) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EntryDialog(
        initialData: row,
        machines: _machines,
        departments: _departments,
        productNames: _productNames,
        onSubmit: (data) async {
          await ProductionOutputService.update(row['id']?.toString() ?? '', data);
          if (!mounted) return;
          Navigator.of(context).pop();
          await _load();
          _snack('Entry updated successfully');
        },
      ),
    );
  }

  void _showDelete(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (_) => ProductionOutputDeleteDialog(
        row: row,
        onConfirm: () async {
          await ProductionOutputService.delete(row['id']?.toString() ?? '');
          if (!mounted) return;
          setState(() => _entries.removeWhere((e) => e['id']?.toString() == row['id']?.toString()));
          _snack('Entry deleted');
        },
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    final t = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? t.error : t.success, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(color: t.primaryText, fontSize: 14))),
      ]),
      backgroundColor: t.secondaryBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: t.primaryBackground,
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
              BreadcrumbItem(label: 'kWh / Tonne'),
              BreadcrumbItem(label: 'Production Output Data Log'),
            ],
            title: 'Production Output Data Log',
            subtitle: 'Log and track production output with energy consumption data.',
          ),
          const SizedBox(
            height: 15.0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DateFilterBtn(
                  label: 'startDate',
                  value: _startDate,
                  t: t,
                  lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                  onPicked: (d) => setState(() {
                    _startDate = d;
                    if (d != null && _endDate != null && _endDate!.isBefore(d)) _endDate = d;
                  }),
                ),
                DateFilterBtn(
                  label: 'EndDate',
                  value: _endDate,
                  t: t,
                  firstDate: _startDate ?? DateTime(2020),
                  onPicked: (d) => setState(() => _endDate = d),
                ),
                if (_startDate != null || _endDate != null)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    icon: Icon(Icons.clear_all, size: 15, color: t.secondaryText),
                    label: Text('Clear', style: TextStyle(fontSize: 12, color: t.secondaryText)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FE8)))
                  : DataTableWidget(
                      columns: _columns,
                      rows: _filteredEntries,
                      primaryKey: 'id',
                      primaryColumnKey: 'machine',
                      primarySubtitleKey: 'product',
                      primaryIcon: Icons.factory_outlined,
                      sortKey: 'date',
                      onEdit: _showEdit,
                      onDelete: _showDelete,
                      showSelection: false,
                      showFilterDropdown: false,
                      actions: [
                        TableAction(
                          label: 'Add Production Output',
                          icon: Icons.add,
                          isPrimary: true,
                          onTap: _showAdd,
                        ),
                        TableAction(
                          label: 'Refresh',
                          icon: Icons.refresh,
                          onTap: _load,
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
