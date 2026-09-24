import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/flutter_flow/rbac.dart';

class EditProductionAreaDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final VoidCallback onUpdated;
  final String userRole;

  const EditProductionAreaDialog({
    super.key,
    required this.initialData,
    required this.onUpdated,
    this.userRole = 'Admin',
  });

  @override
  State<EditProductionAreaDialog> createState() =>
      _EditProductionAreaDialogState();
}

class _EditProductionAreaDialogState extends State<EditProductionAreaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;

  List<Map<String, dynamic>> _plants = [];
  String? _selectedPlantId;
  bool _fetchingPlants = true;
  String? _error;

  bool get _isSuperAdmin =>
      AppRoles.normalizeRole(widget.userRole) == AppRoles.superAdmin;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.initialData['name']?.toString() ?? '');
    _idCtrl = TextEditingController(
        text: widget.initialData['id']?.toString() ?? '');
    final fid = widget.initialData['factory_id']?.toString() ?? '';
    _selectedPlantId = fid.isNotEmpty ? fid : null;
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
          // Keep pre-selected plant if it exists in the list
          if (_selectedPlantId != null &&
              !_plants.any((p) => p['id'] == _selectedPlantId)) {
            _selectedPlantId = null;
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
      final id = widget.initialData['id']?.toString() ?? '';
      final body = <String, dynamic>{'name': _nameCtrl.text.trim()};
      if (_selectedPlantId != null && _selectedPlantId!.isNotEmpty) {
        body['factory_id'] = _selectedPlantId;
      }
      if (_isSuperAdmin) {
        final newId = _idCtrl.text.trim();
        if (newId.isNotEmpty) body['id'] = newId;
      }
      final res = await http.put(
        Uri.parse('${AppConfig.dataApiBaseSafe}/productionAreas/$id'),
        headers: AppConfig.headers,
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
        widget.onUpdated();
        return true;
      }
      throw Exception(_parseError(res, 'Failed to update production area (${res.statusCode})'));
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
      icon: Icons.edit_outlined,
      title: 'Edit Production Area',
      subtitle: 'Editing: ${widget.initialData['name'] ?? '-'}',
      requiredNote: true,
      submitLabel: 'SAVE CHANGES',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Production Area Details',
          subtitle: 'Update the production area information.',
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
    final validId = _plants.any((p) => p['id'] == _selectedPlantId)
        ? _selectedPlantId
        : null;
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validId,
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
          decoration: _inputDeco(
              'Current: ${widget.initialData['id'] ?? '-'}',
              inputFill,
              inputBorder),
        )
      else
        _lockedIdPill(),
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

  Widget _lockedIdPill() {
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
          child: Text(
            widget.initialData['id']?.toString() ?? '—',
            style: const TextStyle(
                color: Color(0xFF0A0E1A),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 6),
        const Text('(read-only)',
            style: TextStyle(color: Color(0xFF4A5568), fontSize: 11)),
      ]),
    );
  }
}
