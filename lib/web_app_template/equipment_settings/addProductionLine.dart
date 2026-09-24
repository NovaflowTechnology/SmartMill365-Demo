import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import '/flutter_flow/nav/nav.dart';
import '/flutter_flow/rbac.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AddProductionLineDialog extends StatefulWidget {
  const AddProductionLineDialog({
    super.key,
    required this.onAdded,
    required this.userId,
  });
  final VoidCallback onAdded;
  final String userId;

  @override
  State<AddProductionLineDialog> createState() => _AddProductionLineDialogState();
}

class _AddProductionLineDialogState extends State<AddProductionLineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lineNoCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Areas: each map has 'name', 'id', 'factory_id'
  List<Map<String, dynamic>> _areas = [];
  // Plants: map id -> name
  Map<String, String> _plantNames = {};

  String? _selectedAreaName;
  String? _autoPlant; // auto-filled plant name
  bool _valid = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAreasAndPlants();
  }

  @override
  void dispose() {
    _lineNoCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAreasAndPlants() async {
    try {
      final userId = widget.userId;
      final factoryId = AppStateNotifier.instance.factoryId ?? '';
      final isSuperAdmin = AppRoles.normalizeRole(AppStateNotifier.instance.userRole ?? '') == AppRoles.superAdmin;

      final areaUri = Uri.parse('${AppConfig.dataApiBaseSafe}/productionAreas')
          .replace(queryParameters: (!isSuperAdmin && factoryId.isNotEmpty) ? {'factory_id': factoryId} : null);

      final results = await Future.wait([
        http.get(areaUri, headers: AppConfig.headers),
        http.get(Uri.parse('${AppConfig.dataApiBaseSafe}/factory'), headers: AppConfig.headers),
      ]);

      final areaRes = results[0];
      final plantRes = results[1];

      final plantMap = <String, String>{};
      if (plantRes.statusCode == 200) {
        final List<dynamic> plants = json.decode(plantRes.body);
        for (final p in plants) {
          final id = p['id']?.toString() ?? '';
          final name = p['name']?.toString() ?? '';
          if (id.isNotEmpty) plantMap[id] = name;
        }
      }

      if (areaRes.statusCode == 200) {
        final List<dynamic> raw = json.decode(areaRes.body);
        final areas = raw
            .map<Map<String, dynamic>>((e) => {
                  'id': e['id']?.toString() ?? '',
                  'name': e['name']?.toString() ?? '',
                  'factory_id': e['factory_id']?.toString() ?? '',
                })
            .where((a) => a['name'] != null && a['name'].toString().isNotEmpty)
            .toList();

        // Additional local filtering by factory_id if not super admin
        final filteredAreas = isSuperAdmin ? areas : areas.where((a) => a['factory_id'] == factoryId || factoryId.isEmpty).toList();

        if (mounted) {
          setState(() {
            _areas = filteredAreas;
            _plantNames = plantMap;
          });
        }
      }
    } catch (_) {}
  }

  void _onAreaChanged(String? areaName) {
    if (areaName == null) {
      setState(() {
        _selectedAreaName = null;
        _autoPlant = null;
      });
      return;
    }
    final area = _areas.firstWhere(
      (a) => a['name'] == areaName,
      orElse: () => <String, dynamic>{},
    );
    final factoryId = area['factory_id'] as String? ?? '';
    final plantName = _plantNames[factoryId];
    setState(() {
      _selectedAreaName = areaName;
      _autoPlant = (plantName != null && plantName.isNotEmpty) ? plantName : null;
    });
  }

  Future<bool> _submit() async {
    setState(() => _error = null);
    try {
      final selectedArea = _areas.firstWhere(
        (a) => a['name'] == _selectedAreaName,
        orElse: () => <String, dynamic>{},
      );
      final factoryId = selectedArea['factory_id']?.toString() ?? '';

      final res = await http.post(
        Uri.parse('${AppConfig.dataApiBaseSafe}/productionLines/add'),
        headers: AppConfig.headers,
        body: json.encode({
          'lineNo': _lineNoCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'productionArea': _selectedAreaName ?? '',
          'factory_id': factoryId,
          'description': _descCtrl.text.trim(),
          'valid': _valid,
          'userId': widget.userId,
        }),
      );
      if (res.statusCode == 201) {
        widget.onAdded();
        return true;
      }
      if (res.statusCode == 400) throw Exception('Production line with same No. already exists.');
      throw Exception('Failed to add: ${res.statusCode}');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  InputDecoration _inputDec(String label, bool isLight) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12),
        filled: true,
        fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF31ECFC), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE74852))),
        focusedErrorBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE74852), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textStyle = TextStyle(color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 14);
    final dropBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1A2A4A);
    final labelColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final isValidArea = _areas.any((a) => a['name'] == _selectedAreaName);
    return CustomDialog(
      formKey: _formKey,
      icon: Icons.linear_scale_outlined,
      title: 'Add Production Line',
      subtitle: 'Enter the production line details to add.',
      requiredNote: true,
      submitLabel: 'ADD',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Production Line Details',
          subtitle: 'Provide the production line information.',
          children: [
            // Line No + Valid toggle
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lineNoCtrl,
                    style: textStyle,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    decoration: _inputDec('Production Line No. *', isLight),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Text('Valid',
                        style:
                            TextStyle(color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Switch(
                      value: _valid,
                      onChanged: (v) => setState(() => _valid = v),
                      activeColor: const Color(0xFF31ECFC),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Production Line Name
            TextFormField(
              controller: _nameCtrl,
              style: textStyle,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDec('Production Line Name *', isLight),
            ),
            const SizedBox(height: 16),
            // Production Area dropdown
            DropdownButtonFormField<String>(
              value: isValidArea ? _selectedAreaName : null,
              dropdownColor: dropBg,
              style: textStyle,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              decoration: _inputDec('Production Area *', isLight),
              hint: Text('Please select', style: TextStyle(color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF5C6987), fontSize: 14)),
              items: _areas
                  .unique((a) => a['name']) // Deduplicate names to prevent dropdown crash
                  .map((area) {
                return DropdownMenuItem<String>(
                  value: area['name'] as String,
                  child: Text(area['name'] as String, style: textStyle),
                );
              }).toList(),
              onChanged: _onAreaChanged,
            ),
            const SizedBox(height: 16),
            // Auto-filled Plant (read-only)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLANT (AUTO-FILLED)', style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.7)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        _autoPlant != null ? const Color(0xFF31ECFC).withOpacity(0.1) : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0D1117)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _autoPlant != null
                            ? const Color(0xFF31ECFC).withOpacity(0.4)
                            : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A))),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.factory_outlined,
                          size: 16,
                          color: _autoPlant != null ? const Color(0xFF9B7EFF) : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563))),
                      const SizedBox(width: 8),
                      Text(
                        _autoPlant ?? 'Select a production area first',
                        style: TextStyle(
                          color: _autoPlant != null ? const Color(0xFF9B7EFF) : (isLight ? const Color(0xFF94A3B8) : const Color(0xFF4B5563)),
                          fontSize: 13,
                          fontWeight: _autoPlant != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descCtrl,
              style: textStyle,
              maxLines: 4,
              decoration: _inputDec('Description', isLight),
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
