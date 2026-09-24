import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/web_app_template/product_settings/firestore_service.dart';
import 'package:smartmachine365/services/app_config.dart';

class EditProductDialog extends StatefulWidget {
  const EditProductDialog({
    super.key,
    required this.firestoreService,
    required this.id,
    required this.initialNumber,
    required this.initialName,
    required this.initialSpecification,
    required this.initialDescription,
    required this.initialBatchQuantity,
    required this.initialPackingQuantity,
    required this.initialClassification,
    required this.initialCategory,
    required this.initialEquipment,
    required this.initialProcessRoute,
    required this.onProductAdded,
  });
  final FirestoreService firestoreService;
  final String id, initialNumber, initialName, initialSpecification, initialDescription, initialClassification, initialCategory, initialEquipment, initialProcessRoute;
  final int initialBatchQuantity, initialPackingQuantity;
  final VoidCallback onProductAdded;
  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl, _nameCtrl, _specCtrl, _descCtrl, _batchQtyCtrl, _packingQtyCtrl, _classCtrl, _categoryCtrl;
  List<dynamic> _equipments = [];
  List<dynamic> _processRoutes = [];
  String? _selectedEquipment, _selectedProcessRoute, _error;
  String _prevEquipment = '';

  @override
  void initState() {
    super.initState();
    _numberCtrl     = TextEditingController(text: widget.initialNumber);
    _nameCtrl       = TextEditingController(text: widget.initialName);
    _specCtrl       = TextEditingController(text: widget.initialSpecification);
    _descCtrl       = TextEditingController(text: widget.initialDescription);
    _batchQtyCtrl   = TextEditingController(text: widget.initialBatchQuantity.toString());
    _packingQtyCtrl = TextEditingController(text: widget.initialPackingQuantity.toString());
    _classCtrl      = TextEditingController(text: widget.initialClassification);
    _categoryCtrl   = TextEditingController(text: widget.initialCategory);
    _selectedProcessRoute = widget.initialProcessRoute;
    _fetchEquipment();
  }

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
        setState(() {
          _equipments = data;
          _selectedEquipment = widget.initialEquipment.isNotEmpty ? widget.initialEquipment : (_equipments.isNotEmpty ? _equipments[0]['id'] : '0');
        });
      }
    } catch (e) { setState(() => _error = 'Error fetching equipment: $e'); }
  }

  Future<bool> _save() async {
    setState(() => _error = null);
    if (_selectedEquipment == null || _selectedProcessRoute == null) {
      setState(() => _error = 'All fields are required.');
      return false;
    }
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final res = await http.put(
        Uri.parse('${AppConfig.dataApiBaseSafe}/products/${widget.id}'),
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
          'previousEquipment': _prevEquipment,
        }),
      );
      if (res.statusCode != 200) {
        final body = json.decode(res.body);
        setState(() => _error = body['error'] ?? 'Failed to save');
        return false;
      }
      widget.onProductAdded();
      return true;
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.inventory_2_outlined,
      title: 'Edit Product',
      subtitle: 'Update the product details below.',
      requiredNote: true,
      submitLabel: 'SAVE',
      onSubmit: _save,
      sections: [
        CustomDialogSection(
          title: 'Product Details',
          subtitle: 'Update the product information.',
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
              (v) => setState(() { _prevEquipment = _selectedEquipment ?? ''; _selectedEquipment = v; }), isLight: isLight),
            const SizedBox(height: 16),
            _dropdown('Process Route *', _selectedProcessRoute,
              [{'id': '0', 'name': 'Not Assigned'}, ..._processRoutes],
              (v) => setState(() { _selectedProcessRoute = v; }), isLight: isLight),
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
