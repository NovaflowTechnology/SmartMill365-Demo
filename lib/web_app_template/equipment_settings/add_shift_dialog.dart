import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'package:smartmachine365/web_app_template/equipment_settings/shift_form_widgets.dart';

class AddShiftDialog extends StatefulWidget {
  const AddShiftDialog({
    super.key,
    required this.onAdded,
    required this.userId,
  });
  final VoidCallback onAdded;
  final String userId;

  @override
  State<AddShiftDialog> createState() => _AddShiftDialogState();
}

class _AddShiftDialogState extends State<AddShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  String _startWorkTime = '';
  String _finishWorkTime = '';
  bool _valid = true;
  String? _error;

  final List<Map<String, String>> _restTimes = [];

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = _parseTime(isStart ? _startWorkTime : _finishWorkTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startWorkTime = formatted;
        } else {
          _finishWorkTime = formatted;
        }
      });
    }
  }

  Future<void> _pickRestTime(int index, bool isStart) async {
    final current = _restTimes[index];
    final initial =
        _parseTime(isStart ? current['startRestTime']! : current['endRestTime']!);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _restTimes[index]['startRestTime'] = formatted;
        } else {
          _restTimes[index]['endRestTime'] = formatted;
        }
      });
    }
  }

  TimeOfDay _parseTime(String hhmm) {
    if (hhmm.isEmpty) return TimeOfDay.now();
    final parts = hhmm.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h, minute: m);
    }
    return TimeOfDay.now();
  }

  Future<bool> _submit() async {
    setState(() => _error = null);
    if (_startWorkTime.isEmpty) {
      setState(() => _error = 'Start Work Time is required.');
      return false;
    }
    if (_finishWorkTime.isEmpty) {
      setState(() => _error = 'Finish Work Time is required.');
      return false;
    }
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.dataApiBaseSafe}/shifts/add'),
        headers: AppConfig.headers,
        body: json.encode({
          'code': _codeCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'startWorkTime': _startWorkTime,
          'finishWorkTime': _finishWorkTime,
          'valid': _valid,
          'restTimes': _restTimes,
          'userId': widget.userId,
        }),
      );
      if (res.statusCode == 201) {
        widget.onAdded();
        return true;
      }
      final body = json.decode(res.body);
      throw Exception(body['error'] ?? 'Failed to add shift.');
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
      icon: Icons.access_time_outlined,
      title: 'Add Shift',
      subtitle: 'Enter the shift details to add.',
      requiredNote: true,
      submitLabel: 'ADD',
      onSubmit: _submit,
      sections: [
        CustomDialogSection(
          title: 'Shift Details',
          subtitle: 'Provide the shift information.',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeCtrl,
                    style: _textStyle(isLight),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    decoration: _inputDec('Shift Code *', isLight),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Text('Valid',
                        style: TextStyle(
                            color: isLight
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFE2E8F0),
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
              controller: _nameCtrl,
              style: _textStyle(isLight),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              decoration: _inputDec('Shift Name *', isLight),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ShiftTimePickerField(
                    label: 'Start Work Time (HH:MM) *',
                    value: _startWorkTime,
                    isLight: isLight,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ShiftTimePickerField(
                    label: 'Finish Work Time (HH:MM) *',
                    value: _finishWorkTime,
                    isLight: isLight,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFE74852), fontSize: 12)),
            ],
          ],
        ),
        CustomDialogSection(
          title: 'Shift Rest Times',
          subtitle: 'Add rest periods within the shift.',
          children: [
            ShiftRestTimeTable(
              restTimes: _restTimes,
              isLight: isLight,
              onAdd: () => setState(
                  () => _restTimes.add({'startRestTime': '', 'endRestTime': ''})),
              onRemove: (i) => setState(() => _restTimes.removeAt(i)),
              onPickTime: _pickRestTime,
            ),
          ],
        ),
      ],
    );
  }

  TextStyle _textStyle(bool isLight) => TextStyle(
      color: isLight ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
      fontSize: 14);

  InputDecoration _inputDec(String label, bool isLight) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isLight
                ? const Color(0xFF64748B)
                : const Color(0xFF94A3B8),
            fontSize: 12),
        filled: true,
        fillColor:
            isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1117),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: isLight
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF2C354A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFF31ECFC), width: 1.5)),
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
