import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/firestore_service.dart';
import 'package:smartmachine365/web_app_template/alarm_settings/esop_file_picker.dart';
import 'package:smartmachine365/services/app_config.dart';

class EditAlarmDialog extends StatefulWidget {
  const EditAlarmDialog({
    super.key,
    required this.id,
    required this.initialName,
    required this.initialDevice,
    required this.initialMessage,
    required this.initialMinValue,
    required this.initialMaxValue,
    required this.initialPIC,
    required this.initialESOP,
    required this.firestoreService,
    required this.onAlarmAdded,
  });
  final String id, initialName, initialDevice, initialMessage, initialMinValue, initialMaxValue, initialPIC, initialESOP;
  final FirestoreService firestoreService;
  final VoidCallback onAlarmAdded;
  @override
  State<EditAlarmDialog> createState() => _EditAlarmDialogState();
}

class _EditAlarmDialogState extends State<EditAlarmDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl, _msgCtrl, _minCtrl, _maxCtrl, _picCtrl, _esopCtrl;
  List<dynamic> _devices = [];
  String? _selectedDevice;
  String? _fileName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _msgCtrl  = TextEditingController(text: widget.initialMessage);
    _minCtrl  = TextEditingController(text: widget.initialMinValue);
    _maxCtrl  = TextEditingController(text: widget.initialMaxValue);
    _picCtrl  = TextEditingController(text: widget.initialPIC);
    final esop = widget.initialESOP.split('\n').map((l) => l.replaceAll(RegExp(r'\(T\)|\(F\)'), '').trim()).join('\n');
    _esopCtrl = TextEditingController(text: esop);
    _fetchDevices();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _msgCtrl, _minCtrl, _maxCtrl, _picCtrl, _esopCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final res = await http.get(
        Uri.parse('${AppConfig.dataApiBaseSafe}/devices'),
        headers: AppConfig.headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          _devices = data;
          _selectedDevice = widget.initialDevice.isNotEmpty ? widget.initialDevice : (_devices.isNotEmpty ? _devices[0]['id'] : '0');
        });
      }
    } catch (e) { setState(() => _error = 'Error fetching devices: $e'); }
  }

  Future<void> _pickFile() async {
    final picked = await pickEsopFile();
    if (!mounted) return;
    if (picked == null) {
      setState(() => _error = 'File picker is not available on this platform.');
      return;
    }
    setState(() {
      _fileName = picked.fileName;
      _esopCtrl.text = picked.content;
    });
  }

  Future<bool> _submit() async {
    setState(() => _error = null);
    if (_selectedDevice == null) { setState(() => _error = 'Device is required.'); return false; }
    try {
      final esopLines = _esopCtrl.text.split('\n').map((line) {
        final orig = widget.initialESOP.split('\n').firstWhere((o) => o.contains(line.trim()), orElse: () => '$line (F)');
        return orig.startsWith('(T)') || orig.startsWith('(F)') ? orig : '$line (F)';
      }).join('\n');
      if (AppConfig.clientId.isEmpty) await AppConfig.refresh();
      final res = await http.put(
        Uri.parse('${AppConfig.dataApiBaseSafe}/alarms/${widget.id}'),
        headers: AppConfig.headers,
        body: json.encode({
          'name': _nameCtrl.text,
          'device_id': _selectedDevice!,
          'message': _msgCtrl.text,
          'threshold_minimum': _minCtrl.text,
          'threshold_maximum': _maxCtrl.text,
          'pic': _picCtrl.text,
          'esop': esopLines,
        }),
      );
      if (res.statusCode != 200) {
        final body = json.decode(res.body);
        setState(() => _error = body['error'] ?? 'Failed to save');
        return false;
      }
      widget.onAlarmAdded();
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
      icon: Icons.notifications_outlined,
      title: 'Edit Alarm',
      subtitle: 'Update the alarm details below.',
      requiredNote: true,
      submitLabel: 'SAVE',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Alarm Details',
          subtitle: 'Update the alarm parameters.',
          children: [
            _dropdown('Device *', _selectedDevice,
              [{'id': '0', 'device_name': 'Not Assigned'}, ..._devices],
              (v) => setState(() => _selectedDevice = v), isLight: isLight, isDevice: true),
            const SizedBox(height: 16),
            _field('Alarm Name *', _nameCtrl, isLight: isLight),
            const SizedBox(height: 16),
            _field('Message *', _msgCtrl, lines: 3, isLight: isLight),
            const SizedBox(height: 16),
            _field('Minimum Value *', _minCtrl, isNumeric: true, isLight: isLight),
            const SizedBox(height: 16),
            _field('Maximum Value *', _maxCtrl, isNumeric: true, isLight: isLight),
            const SizedBox(height: 16),
            _field('PIC *', _picCtrl, isLight: isLight),
            const SizedBox(height: 16),
            _field('ESOP', _esopCtrl, lines: 5, isLight: isLight),
            const SizedBox(height: 16),
            _filePicker(isLight),
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

  Widget _dropdown(String label, String? value, List<dynamic> items, ValueChanged<String?> onChanged, {bool isDevice = false, required bool isLight}) =>
    DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1E2432),
      style: TextStyle(color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), fontSize: 14),
      items: items.map((item) => DropdownMenuItem<String>(
        value: item['id'] ?? '0',
        child: Text(isDevice ? (item['device_name'] ?? 'Not Assigned') : (item['name'] ?? 'Not Assigned'),
            style: TextStyle(color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0))),
      )).toList(),
      onChanged: onChanged,
      decoration: _deco(label, isLight),
    );

  Widget _filePicker(bool isLight) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Replace ESOP File', style: TextStyle(color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12)),
    const SizedBox(height: 8),
    ElevatedButton.icon(
      onPressed: _pickFile,
      icon: const Icon(Icons.upload_file, size: 16),
      label: const Text('Upload CSV / Excel'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF2C354A),
        foregroundColor: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      ),
    ),
    if (_fileName != null) ...[
      const SizedBox(height: 6),
      Text(_fileName!, style: TextStyle(color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12)),
    ],
  ]);

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
