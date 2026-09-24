import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/web_app_template/product_settings/firestore_service.dart';
import 'package:smartmachine365/services/app_config.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key, required this.firestoreService, required this.onProductAdded});
  final FirestoreService firestoreService;
  final VoidCallback onProductAdded;
  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey        = GlobalKey<FormState>();
  final _numberCtrl     = TextEditingController();
  final _nameCtrl       = TextEditingController();
  final _specCtrl       = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _batchQtyCtrl   = TextEditingController();
  final _packingQtyCtrl = TextEditingController();
  final _classCtrl      = TextEditingController();
  final _categoryCtrl   = TextEditingController();
  List<dynamic> _equipments = [];
  List<dynamic> _processRoutes = [];
  String? _selectedEquipment;
  String? _selectedProcessRoute;
  String? _error;

  @override
  void initState() { super.initState(); _fetchEquipment(); }

  @override
  void dispose() {
    for (final c in [_numberCtrl, _nameCtrl, _specCtrl, _descCtrl, _batchQtyCtrl, _packingQtyCtrl, _classCtrl, _categoryCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _fetchEquipment() async {
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final res = await http.get(
        Uri.parse('${AppConfig.dataApiBaseSafe}/equipment'),
        headers: AppConfig.headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() => _equipments = data);
      }
    } catch (e) { setState(() => _error = 'Error fetching equipment: $e'); }
  }

  Future<bool> _submit() async {
    setState(() => _error = null);
    if (_selectedEquipment == null || _selectedProcessRoute == null) {
      setState(() => _error = 'All fields are required.');
      return false;
    }
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final res = await http.post(
        Uri.parse('${AppConfig.dataApiBaseSafe}/products/add'),
        headers: AppConfig.headers,
        body: json.encode({
          'number': _numberCtrl.text,
          'name': _nameCtrl.text,
          'specification': _specCtrl.text,
          'description': _descCtrl.text,
          'batchQuantity': int.tryParse(_batchQtyCtrl.text) ?? 0,
          'packingQuantity': int.tryParse(_packingQtyCtrl.text) ?? 0,
          'classification': _classCtrl.text,
          'category': _categoryCtrl.text,
          'equipment': _selectedEquipment!,
          'processRoute': _selectedProcessRoute!,
        }),
      );
      if (res.statusCode != 201) {
        final body = json.decode(res.body);
        setState(() => _error = body['error'] ?? 'Error adding product');
        return false;
      }
      widget.onProductAdded();
      return true;
    } catch (e) {
      setState(() => _error = 'Error adding product: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.inventory_2_outlined,
      title: 'Add Product',
      subtitle: 'Fill in the product details below.',
      requiredNote: true,
      submitLabel: 'ADD',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Product Details',
          subtitle: 'Configure the product information.',
          children: [
            _field('Product Number *', _numberCtrl, isLight: isLight),
            const SizedBox(height: 16),
            _field('Product Name *', _nameCtrl, isLight: isLight),
            const SizedBox(height: 16),
            _field('Specification *', _specCtrl, isLight: isLight),
            const SizedBox(height: 16),
            _field('Description *', _descCtrl, lines: 3, isLight: isLight),
            const SizedBox(height: 16),
            _field('Standard Batch Quantity *', _batchQtyCtrl, isNumeric: true, isLight: isLight),
            const SizedBox(height: 16),
            _field('Packing Quantity *', _packingQtyCtrl, isNumeric: true, isLight: isLight),
            const SizedBox(height: 16),
            _field('Item Classification *', _classCtrl, isLight: isLight),
            const SizedBox(height: 16),
            _field('Item Category *', _categoryCtrl, isLight: isLight),
            const SizedBox(height: 16),
            _dropdown('Equipment *', _selectedEquipment,
              [{'id': '0', 'name': 'Not Assigned'}, ..._equipments],
              (v) => setState(() => _selectedEquipment = v), isLight: isLight),
            const SizedBox(height: 16),
            _dropdown('Process Route *', _selectedProcessRoute,
              [{'id': '0', 'name': 'Not Assigned'}, ..._processRoutes],
              (v) => setState(() => _selectedProcessRoute = v), isLight: isLight),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFE74852), fontSize: 12)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int lines = 1, bool isNumeric = false, required bool isLight}) =>
    TextFormField(
      controller: ctrl,
      style: TextStyle(color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 14),
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.multiline,
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))] : [],
      minLines: lines, maxLines: lines,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      decoration: _deco(label, isLight),
    );

  Widget _dropdown(String label, String? value, List<dynamic> items, ValueChanged<String?> onChanged, {required bool isLight}) =>
    DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1E2432),
      style: TextStyle(color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 14),
      items: items.toSet().map((item) => DropdownMenuItem<String>(
        value: item['id'] ?? '0',
        child: Text(item['name'] ?? 'Not Assigned', style: TextStyle(color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0))),
      )).toList(),
      onChanged: onChanged,
      decoration: _deco(label, isLight),
    );

  InputDecoration _deco(String label, bool isLight) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12),
    filled: true,
    fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF7A68FF), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE74852))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
