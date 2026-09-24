import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';

class EditDeviceTypeDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final VoidCallback onUpdated;

  const EditDeviceTypeDialog({
    super.key,
    required this.initialData,
    required this.onUpdated,
  });

  @override
  State<EditDeviceTypeDialog> createState() => _EditDeviceTypeDialogState();
}

class _EditDeviceTypeDialogState extends State<EditDeviceTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.initialData['name']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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
      final res = await http.put(
        Uri.parse('${AppConfig.dataApiBaseSafe}/deviceTypes/$id'),
        headers: AppConfig.headers,
        body: json.encode({'name': _nameCtrl.text.trim()}),
      );
      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
        widget.onUpdated();
        return true;
      }
      throw Exception(_parseError(res, 'Failed to update device type (${res.statusCode})'));
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
      title: 'Edit Device Type',
      subtitle: 'Editing: ${widget.initialData['name'] ?? '-'}',
      requiredNote: true,
      submitLabel: 'SAVE CHANGES',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Device Type Details',
          subtitle: 'Update the device type information.',
          children: [
            _nameField(isLight),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Color(0xFFE74852), fontSize: 12)),
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
                color: Color(0xFF31ECFC), fontSize: 11, fontWeight: FontWeight.w700)),
      Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.7)),
    ]);
  }

  Widget _nameField(bool isLight) {
    final inputFill = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117);
    final inputBorder = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF2C354A);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Device Type Name', isLight, required: true),
      const SizedBox(height: 6),
      TextFormField(
        controller: _nameCtrl,
        style: TextStyle(
            color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            fontSize: 14),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Device type name is required' : null,
        decoration: _inputDeco('Enter device type name', inputFill, inputBorder),
      ),
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
          borderSide: const BorderSide(color: Color(0xFFE74852), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
