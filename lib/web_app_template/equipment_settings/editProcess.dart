import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';

class EditProcessDialog extends StatefulWidget {
  const EditProcessDialog({
    super.key,
    required this.id,
    required this.initialName,
    required this.initialDescription,
    required this.initialValid,
    required this.onEdited,
  });

  final String id;
  final String initialName;
  final String initialDescription;
  final bool initialValid;
  final VoidCallback onEdited;

  @override
  State<EditProcessDialog> createState() => _EditProcessDialogState();
}

class _EditProcessDialogState extends State<EditProcessDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  late bool _valid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDescription);
    _valid = widget.initialValid;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    setState(() => _error = null);
    try {
      final res = await http.put(
        Uri.parse('${AppConfig.dataApiBaseSafe}/process/${widget.id}'),
        headers: AppConfig.headers,
        body: json.encode({
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'valid': _valid,
        }),
      );
      if (res.statusCode == 200) {
        widget.onEdited();
        return true;
      }
      throw Exception('Failed to update: ${res.statusCode}');
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

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textStyle = TextStyle(
        color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 14);

    return CustomDialog(
      formKey: _formKey,
      icon: Icons.settings_outlined,
      title: 'Edit Process',
      subtitle: 'Update the process details.',
      requiredNote: true,
      submitLabel: 'SAVE',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Process Details',
          subtitle: 'Modify the process information.',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: textStyle,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    decoration: _inputDec('Process Name *', isLight),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Text('Valid',
                        style: TextStyle(
                            color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
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
