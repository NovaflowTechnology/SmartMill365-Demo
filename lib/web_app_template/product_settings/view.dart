import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/components/data_table/data_table_widget.dart';
import 'package:smartmachine365/components/data_table/table_column.dart';
import 'package:smartmachine365/components/page_header/breadcrumb_item.dart';
import 'package:smartmachine365/components/page_header/page_header_widget.dart';
import 'package:smartmachine365/web_app_template/product_settings/add.dart';
import 'package:smartmachine365/web_app_template/product_settings/edit.dart';
import 'package:smartmachine365/web_app_template/product_settings/firestore_service.dart';
import 'package:smartmachine365/services/app_config.dart';

const List<TableColumn> _productColumns = [
  TableColumn('Product ID',              'id',              120),
  TableColumn('Product No.',             'number',          110),
  TableColumn('Product Name',            'name',            160, sortable: true),
  TableColumn('Specification',           'specification',   130),
  TableColumn('Description',             'description',     150),
  TableColumn('Batch Qty',               'batchQuantity',   90),
  TableColumn('Packing Qty',             'packingQuantity', 90),
  TableColumn('Classification',          'classification',  120),
  TableColumn('Category',                'category',        110),
  TableColumn('Equipment',               'equipment',       130),
  TableColumn('Process Route',           'processRoute',    130),
];

class ProductView extends StatefulWidget {
  const ProductView({super.key});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  List<Map<String, dynamic>> _products = [];
  Map<String, String> _equipmentIdToName = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchEquipments();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final res = await http.get(
        Uri.parse('${AppConfig.dataApiBaseSafe}/products'),
        headers: AppConfig.headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() => _products = data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEquipments() async {
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final res = await http.get(
        Uri.parse('${AppConfig.dataApiBaseSafe}/equipment'),
        headers: AppConfig.headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          _equipmentIdToName = {for (var e in data) e['id'] as String: (e['name'] ?? '') as String};
        });
      }
    } catch (e) {
      debugPrint('Error fetching equipments: $e');
    }
  }

  String _resolveEquipment(String id) =>
      id == '0' ? 'Not assigned' : (_equipmentIdToName[id] ?? 'Unknown');

  Widget? _cellBuilder(String key, String value, Map<String, dynamic> row) {
    if (key == 'equipment') {
      return Text(_resolveEquipment(value), overflow: TextOverflow.ellipsis);
    }
    return null;
  }

  void _onEdit(Map<String, dynamic> row) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => EditProductDialog(
        firestoreService: FirestoreService(),
        id: row['id'],
        initialNumber: row['number'],
        initialName: row['name'],
        initialSpecification: row['specification'],
        initialDescription: row['description'],
        initialBatchQuantity: row['batchQuantity'],
        initialPackingQuantity: row['packingQuantity'],
        initialClassification: row['classification'],
        initialCategory: row['category'],
        initialEquipment: row['equipment'],
        initialProcessRoute: row['processRoute'],
        onProductAdded: _fetch,
      ),
    );
  }

  void _onDelete(Map<String, dynamic> row) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.cardStroke)),
        title: Text('Delete Product', style: TextStyle(color: theme.txtPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text('Delete "${row['name']}"? This cannot be undone.', style: TextStyle(color: theme.txtSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: TextStyle(color: theme.txtSecondary))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final delRes = await http.delete(
                  Uri.parse('${AppConfig.dataApiBaseSafe}/products/${row['id']}'),
                  headers: AppConfig.headers,
                );
                if (delRes.statusCode != 200) throw Exception('Delete failed');
                setState(() => _products.removeWhere((p) => p['id'] == row['id']));
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Product deleted.', style: TextStyle(color: Colors.green)), backgroundColor: isLight ? Colors.white : Colors.black, duration: const Duration(seconds: 2)));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e', style: const TextStyle(color: Colors.red)), backgroundColor: isLight ? Colors.white : Colors.black, duration: const Duration(seconds: 2)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74852), foregroundColor: Colors.white),
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
      builder: (_) => AddProductDialog(firestoreService: FirestoreService(), onProductAdded: _fetch),
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
        image: DecorationImage(fit: BoxFit.cover, image: Image.asset('assets/images/backgroundanimated.gif').image),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            breadcrumbs: [
              BreadcrumbItem(label: 'Settings', icon: Icons.settings),
              BreadcrumbItem(label: 'General Factory Setting'),
              BreadcrumbItem(label: 'Product'),
            ],
            title: 'Product',
            subtitle: 'Manage your products.',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FE8)))
                  : DataTableWidget(
                      columns: _productColumns,
                      rows: _products,
                      perPage: 13,
                      primaryKey: 'id',
                      primaryColumnKey: 'name',
                      primarySubtitleKey: 'number',
                      primaryIcon: Icons.inventory_2_outlined,
                      sortKey: 'name',
                      cellBuilder: _cellBuilder,
                      onEdit: _onEdit,
                      onDelete: _onDelete,
                      onSelectionChanged: (ids) {},
                      showSelection: false,
                      showFilterDropdown: false,
                      actions: [
                        TableAction(label: 'Add Product', icon: Icons.add, isPrimary: true, onTap: _showAdd),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
