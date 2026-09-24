import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/flutter_flow/rbac.dart';
import 'package:smartmachine365/services/app_config.dart';

class AddProductionAreaDialog extends StatefulWidget {
  final VoidCallback onEquipmentAdded;
  final String factoryId;
  final String userRole;

  const AddProductionAreaDialog({
    super.key,
    required this.onEquipmentAdded,
    this.factoryId = '',
    this.userRole = 'Admin',
  });

  @override
  State<AddProductionAreaDialog> createState() =>
      _AddProductionAreaDialogState();
}

class _AddProductionAreaDialogState extends State<AddProductionAreaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();

  List<Map<String, dynamic>> _plants = [];
  String? _selectedPlantId;
  bool _fetchingPlants = true;
  String? _error;

  bool get _isSuperAdmin =>
      AppRoles.normalizeRole(widget.userRole) == AppRoles.superAdmin;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPlants() async {
    try {
      final res =
          await http.get(Uri.parse('${AppConfig.dataApiBaseSafe}/factory'), headers: AppConfig.headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          _plants = data
              .map((e) => {
                    'id': e['id']?.toString() ?? '',
                    'name': e['name']?.toString() ?? '',
                  })
              .where((p) => (p['name'] as String).isNotEmpty)
              .toList();
          if (widget.factoryId.isNotEmpty &&
              _plants.any((p) => p['id'] == widget.factoryId)) {
            _selectedPlantId = widget.factoryId;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _fetchingPlants = false);
    }
  }

  String _parseError(http.Response res, String fallback) {
    try {
      final decoded = json.decode(res.body) as Map<String, dynamic>;
      return (decoded['error'] ?? decoded['message'] ?? fallback).toString();
    } catch (_) {
      return fallback;
    }
  }

  Future<bool> _submit() async {
    setState(() => _error = null);
    try {
      final body = <String, dynamic>{'name': _nameCtrl.text.trim()};
      if (_selectedPlantId != null && _selectedPlantId!.isNotEmpty) {
        body['factory_id'] = _selectedPlantId;
      }
      if (_isSuperAdmin && _idCtrl.text.trim().isNotEmpty) {
        body['id'] = _idCtrl.text.trim();
      }
      final res = await http.post(
        Uri.parse('${AppConfig.dataApiBaseSafe}/productionAreas/add'),
        headers: AppConfig.headers,
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        widget.onEquipmentAdded();
        return true;
      }
      throw Exception(_parseError(res, 'Failed to add production area (${res.statusCode})'));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.domain_outlined,
      title: 'Add Production Area',
      subtitle: 'Enter the production area name to add.',
      requiredNote: true,
      submitLabel: 'ADD',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Production Area Details',
          subtitle: 'Provide the production area information.',
          children: [
            _fieldLabel('Select Plant', isLight),
            const SizedBox(height: 6),
            _plantDropdown(isLight),
            const SizedBox(height: 16),
            _nameField(isLight),
            const SizedBox(height: 16),
            _idField(isLight),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFE74852), fontSize: 12)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, bool isLight, {bool required = false}) {
    final color = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    return Row(children: [
      if (required)
        const Text('* ',
            style: TextStyle(
                color: Color(0xFF31ECFC),
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      Text(label.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7)),
    ]);
  }

  Widget _plantDropdown(bool isLight) {
    if (_fetchingPlants) {
      return const SizedBox(
          height: 44,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final fill = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final border = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    final textColor = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final hintColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
    final iconColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF8B949E);
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPlantId,
          isExpanded: true,
          dropdownColor: isLight ? Colors.white : const Color(0xFF1A2A4A),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: iconColor),
          hint: Text('Select plant', style: TextStyle(color: hintColor, fontSize: 13)),
          style: TextStyle(color: textColor, fontSize: 13),
          items: _plants
              .map((p) => DropdownMenuItem<String>(
                    value: p['id'] as String,
                    child: Text(p['name'] as String,
                        style: TextStyle(color: textColor, fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedPlantId = v),
        ),
      ),
    );
  }

  Widget _nameField(bool isLight) {
    final inputFill =
        isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final inputBorder =
        isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Production Area Name', isLight, required: true),
      const SizedBox(height: 6),
      TextFormField(
        controller: _nameCtrl,
        style: TextStyle(
            color: isLight
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            fontSize: 14),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Production Area Name is required'
            : null,
        decoration:
            _inputDeco('Enter production area name', inputFill, inputBorder),
      ),
    ]);
  }

  Widget _idField(bool isLight) {
    final inputFill =
        isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final inputBorder =
        isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Production Area ID', isLight),
      const SizedBox(height: 6),
      if (_isSuperAdmin)
        TextFormField(
          controller: _idCtrl,
          style: TextStyle(
              color: isLight
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFE2E8F0),
              fontSize: 14),
          decoration:
              _inputDeco('Leave empty to auto-generate', inputFill, inputBorder),
        )
      else
        _lockedPill('Only Developer / Super Admin can edit'),
    ]);
  }

  InputDecoration _inputDeco(String hint, Color fill, Color border) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE74852))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFFE74852), width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _lockedPill(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF9EF01A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.lock_outline, size: 14, color: Color(0xFF0A0E1A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: Color(0xFF0A0E1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}
