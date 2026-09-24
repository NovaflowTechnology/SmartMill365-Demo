import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/flutter_flow/rbac.dart';
import 'package:smartmachine365/services/app_config.dart';

class EditFactoryDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final VoidCallback onUpdated;
  final String userRole;

  const EditFactoryDialog({
    super.key,
    required this.initialData,
    required this.onUpdated,
    this.userRole = 'Admin',
  });

  @override
  State<EditFactoryDialog> createState() => _EditFactoryDialogState();
}

class _EditFactoryDialogState extends State<EditFactoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;

  List<Map<String, dynamic>> _customers = [];
  String? _selectedCustomerId;
  bool _fetchingCustomers = true;

  List<String> _siteIds = [];
  String? _selectedSiteId;
  bool _fetchingSites = true;

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
    final cid = widget.initialData['customer_id']?.toString() ?? '';
    _selectedCustomerId = cid.isNotEmpty ? cid : null;
    final sid = widget.initialData['discovery_plant_id']?.toString() ?? '';
    _selectedSiteId = sid.isNotEmpty ? sid : null;
    _fetchCustomers();
    _fetchSiteIds();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.dataApiBaseSafe}/integrationConfig/loadConfigs'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final clients = data.map((d) {
          final name = d['name']?.toString() ?? d['code']?.toString() ?? '';
          return {'id': d['id']?.toString() ?? '', 'name': name};
        })
            .where((c) => (c['name'] as String).isNotEmpty)
            // A customer site offers only its own client.
            .where((c) => AppConfig.showsClient(c['id'] as String))
            .toList();
        clients.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        if (mounted) setState(() => _customers = clients);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _fetchingCustomers = false);
    }
  }

  Future<void> _fetchSiteIds() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.dataApiBaseSafe}/discoveryDevice/meta')
            .replace(queryParameters: {'start': '-7d'}),
        headers: AppConfig.headers,
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List<dynamic>;
        final ids = data
            .map((e) => (e as Map<String, dynamic>)['site_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        // Ensure pre-filled value is in the list even if not in discovery results
        if (_selectedSiteId != null && !ids.contains(_selectedSiteId)) {
          ids.add(_selectedSiteId!);
          ids.sort();
        }
        if (mounted) setState(() => _siteIds = ids);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _fetchingSites = false);
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
      if (_selectedCustomerId != null) body['customer_id'] = _selectedCustomerId;
      if (_isSuperAdmin) {
        final newId = _idCtrl.text.trim();
        if (newId.isNotEmpty) body['id'] = newId;
      }
      body['discovery_plant_id'] = _selectedSiteId ?? '';
      final res = await http.put(
        Uri.parse('${AppConfig.dataApiBaseSafe}/factory/$id'),
        headers: AppConfig.headers,
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
        widget.onUpdated();
        return true;
      }
      throw Exception(_parseError(res, 'Failed to update plant (${res.statusCode})'));
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
      title: 'Edit Plant',
      subtitle: 'Editing: ${widget.initialData['name'] ?? '-'}',
      requiredNote: true,
      submitLabel: 'SAVE CHANGES',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Plant Details',
          subtitle: 'Update the plant information.',
          children: [
            _fieldLabel('Select Client', isLight),
            const SizedBox(height: 6),
            _customerDropdown(isLight),
            const SizedBox(height: 16),
            _nameField(isLight),
            const SizedBox(height: 16),
            _idField(isLight),
            const SizedBox(height: 16),
            _fieldLabel('Discovery Plant ID', isLight),
            const SizedBox(height: 6),
            _siteIdDropdown(isLight),
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

  Widget _customerDropdown(bool isLight) {
    if (_fetchingCustomers) {
      return const SizedBox(
          height: 44,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final fill = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final border = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    final textColor = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final hintColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
    final iconColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF8B949E);
    final validId = _customers.any((c) => c['id'] == _selectedCustomerId)
        ? _selectedCustomerId
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
          hint: Text('Optional', style: TextStyle(color: hintColor, fontSize: 13)),
          style: TextStyle(color: textColor, fontSize: 13),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Optional', style: TextStyle(color: textColor, fontSize: 13)),
            ),
            ..._customers.map((c) => DropdownMenuItem<String>(
                  value: c['id'] as String,
                  child: Text(c['name'] as String,
                      style: TextStyle(color: textColor, fontSize: 13)),
                )),
          ],
          onChanged: (v) => setState(() => _selectedCustomerId = v),
        ),
      ),
    );
  }

  Widget _siteIdDropdown(bool isLight) {
    if (_fetchingSites) {
      return const SizedBox(
          height: 44,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final fill = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final border = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    final textColor = isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final hintColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
    final iconColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF8B949E);
    final validValue = _siteIds.contains(_selectedSiteId) ? _selectedSiteId : null;
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          dropdownColor: isLight ? Colors.white : const Color(0xFF1A2A4A),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: iconColor),
          hint: Text(
            _siteIds.isEmpty ? 'No sites discovered' : 'Select from Device Discovery',
            style: TextStyle(color: hintColor, fontSize: 13),
          ),
          style: TextStyle(color: textColor, fontSize: 13),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('None', style: TextStyle(color: textColor, fontSize: 13)),
            ),
            ..._siteIds.map((id) => DropdownMenuItem<String>(
                  value: id,
                  child: Text(id, style: TextStyle(color: textColor, fontSize: 13)),
                )),
          ],
          onChanged: (v) => setState(() => _selectedSiteId = v),
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
      _fieldLabel('Plant Name', isLight, required: true),
      const SizedBox(height: 6),
      TextFormField(
        controller: _nameCtrl,
        style: TextStyle(
            color: isLight
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            fontSize: 14),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Plant Name is required'
            : null,
        decoration: _inputDeco('Enter plant name', inputFill, inputBorder),
      ),
    ]);
  }

  Widget _idField(bool isLight) {
    final inputFill =
        isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final inputBorder =
        isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Plant ID', isLight),
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
