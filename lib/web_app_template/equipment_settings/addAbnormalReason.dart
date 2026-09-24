import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';

class AddAbnormalReasonDialog extends StatefulWidget {
  const AddAbnormalReasonDialog({
    super.key,
    required this.onAdded,
    required this.userId,
  });
  final VoidCallback onAdded;
  final String userId;

  @override
  State<AddAbnormalReasonDialog> createState() => _AddAbnormalReasonDialogState();
}

class _AddAbnormalReasonDialogState extends State<AddAbnormalReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonNoCtrl = TextEditingController();
  final _reasonDescCtrl = TextEditingController();

  List<dynamic> _areas = [];
  List<dynamic> _equipment = [];

  String? _selectedType;
  final List<String> _selectedAreas = [];
  final List<String> _selectedEquipment = [];
  String? _error;

  static const List<String> _typeOptions = ['QC', 'Maintenance', 'Production', 'Safety', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchAreas();
    _fetchEquipment();
  }

  @override
  void dispose() {
    _reasonNoCtrl.dispose();
    _reasonDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAreas() async {
    try {
      final uri = Uri.parse('${AppConfig.dataApiBaseSafe}/productionAreas')
          .replace(queryParameters: widget.userId.isNotEmpty ? {'userId': widget.userId} : null);
      final res = await http.get(uri, headers: AppConfig.headers);
      if (res.statusCode == 200) {
        setState(() => _areas = json.decode(res.body));
      }
    } catch (_) {}
  }

  Future<void> _fetchEquipment() async {
    try {
      final uri = Uri.parse('${AppConfig.dataApiBaseSafe}/equipment')
          .replace(queryParameters: widget.userId.isNotEmpty ? {'userId': widget.userId} : null);
      final res = await http.get(uri, headers: AppConfig.headers);
      if (res.statusCode == 200) {
        setState(() => _equipment = json.decode(res.body));
      }
    } catch (_) {}
  }

  Future<bool> _submit() async {
    setState(() => _error = null);
    if (_selectedType == null) {
      setState(() => _error = 'Please select a type.');
      return false;
    }
    if (_selectedAreas.isEmpty) {
      setState(() => _error = 'Please select at least one production area.');
      return false;
    }
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.dataApiBaseSafe}/abnormalReasons/add'),
        headers: AppConfig.headers,
        body: json.encode({
          'reasonNo': _reasonNoCtrl.text.trim(),
          'reasonDescription': _reasonDescCtrl.text.trim(),
          'type': _selectedType,
          'productionArea': _selectedAreas,
          'equipmentModel': _selectedEquipment.isEmpty ? ['*'] : _selectedEquipment,
          'userId': widget.userId,
        }),
      );
      if (res.statusCode == 201) {
        widget.onAdded();
        return true;
      }
      if (res.statusCode == 400) throw Exception('Abnormal reason with same No. already exists.');
      throw Exception('Failed to add: ${res.statusCode}');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  InputDecoration _inputDec(String label, bool isLight) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12),
        filled: true,
        fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE74852))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE74852), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _tagChip(String label, VoidCallback onRemove, bool isLight) => Container(
        margin: const EdgeInsets.only(right: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFEEF2FF) : const Color(0xFF2C354A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isLight ? const Color(0xFF31ECFC).withOpacity(0.4) : const Color(0xFF31ECFC).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: isLight ? const Color(0xFF31ECFC) : const Color(0xFFB8ADFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 13,
                  color: isLight ? const Color(0xFF31ECFC) : const Color(0xFFB8ADFF)),
            ),
          ],
        ),
      );

  Widget _multiSelectField({
    required String label,
    required List<String> selected,
    required List<dynamic> items,
    required String itemKey,
    required bool isLight,
    bool allowWildcard = false,
    String wildcardHint = '(If shared to all, select [*])',
  }) {
    final borderColor = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    final bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final labelColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final dropBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1A2A4A);
    final textStyle = TextStyle(
        color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 13);

    final allOptions = <String>[
      if (allowWildcard) '*',
      ...items.map((e) => e[itemKey] as String),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        if (selected.isNotEmpty)
          Wrap(
            children: selected
                .map((s) => _tagChip(s, () => setState(() => selected.remove(s)), isLight))
                .toList(),
          ),
        if (selected.isNotEmpty) const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: dropBg,
              hint: Text(allowWildcard ? wildcardHint : 'Please select', style: textStyle),
              value: null,
              items: allOptions
                  .where((o) => !selected.contains(o))
                  .map((o) => DropdownMenuItem<String>(
                        value: o,
                        child: Text(o, style: textStyle),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  if (v == '*') {
                    selected.clear();
                    selected.add('*');
                  } else {
                    selected.remove('*');
                    selected.add(v);
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textStyle = TextStyle(
        color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 14);
    final dropBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1A2A4A);

    return CustomDialog(
      formKey: _formKey,
      icon: Icons.warning_amber_outlined,
      title: 'Add Abnormal Reason',
      subtitle: 'Enter the abnormal reason details to add.',
      requiredNote: true,
      submitLabel: 'ADD',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Abnormal Reason Details',
          subtitle: 'Provide the abnormal reason information.',
          children: [
            TextFormField(
              controller: _reasonNoCtrl,
              style: textStyle,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDec('Reason No. *', isLight),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonDescCtrl,
              style: textStyle,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDec('Reason Description *', isLight),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              dropdownColor: dropBg,
              style: textStyle,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              decoration: _inputDec('Type *', isLight),
              hint: Text('Please select',
                  style: TextStyle(
                      color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF5C6987),
                      fontSize: 14)),
              items: _typeOptions
                  .map((t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(t, style: textStyle),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 16),
            _multiSelectField(
              label: 'Production Area *',
              selected: _selectedAreas,
              items: _areas,
              itemKey: 'name',
              isLight: isLight,
              allowWildcard: true,
              wildcardHint: '(If shared to all areas, select [*])',
            ),
            const SizedBox(height: 16),
            _multiSelectField(
              label: 'Equipment Model *',
              selected: _selectedEquipment,
              items: _equipment,
              itemKey: 'name',
              isLight: isLight,
              allowWildcard: true,
              wildcardHint: '(If shared to all model, select [*])',
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFE74852), fontSize: 12)),
            ],
          ],
        ),
      ],
    );
  }
}
