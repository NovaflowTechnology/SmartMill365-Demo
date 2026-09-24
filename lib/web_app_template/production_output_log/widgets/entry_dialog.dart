import 'package:flutter/material.dart';
import 'package:smartmachine365/components/dialogs/custom_dialog.dart';
import 'entry_form_widgets.dart';

class EntryDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final List<String> machines;
  final List<String> departments;
  final List<String> productNames;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const EntryDialog({
    super.key,
    this.initialData,
    required this.machines,
    required this.departments,
    required this.productNames,
    required this.onSubmit,
  });

  @override
  State<EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<EntryDialog> {
  // Malaysia time (UTC+8, no DST) — matches the convention used across the
  // rest of the app (see kwh_add_data_tab.dart's _nowMYT()), so the saved
  // 'date'/'time' payload reflects MYT regardless of the operator's device.
  static DateTime _nowMYT() => DateTime.now().toUtc().add(const Duration(hours: 8));

  final _formKey = GlobalKey<FormState>();
  final _workOrderCtrl = TextEditingController();
  final _previousReadingCtrl = TextEditingController();
  final _meterReadingNowCtrl = TextEditingController();
  final _tonnesCtrl = TextEditingController();
  final _reportByCtrl = TextEditingController();

  DateTime _date = _nowMYT();
  String? _machine;
  String? _product;
  String? _department;
  String? _validationMsg;

  bool get _isEdit => widget.initialData != null;

  double? _parseNum(String raw) => double.tryParse(raw.replaceAll(',', '').trim());

  double? get _kwhConsumed {
    final prev = _parseNum(_previousReadingCtrl.text);
    final now = _parseNum(_meterReadingNowCtrl.text);
    if (prev == null || now == null) return null;
    return now - prev;
  }

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    if (d != null) {
      _date = DateTime.tryParse(d['date']?.toString() ?? '') ?? _nowMYT();
      _machine = d['machine']?.toString();
      _product = d['product']?.toString();
      _department = d['processDepartment']?.toString();
      _workOrderCtrl.text = d['workOrderNumber']?.toString() ?? '';
      _previousReadingCtrl.text = d['previousReading']?.toString() ?? '';
      _meterReadingNowCtrl.text = d['meterReadingNow']?.toString() ?? '';
      _tonnesCtrl.text = d['tonnes']?.toString() ?? '';
      _reportByCtrl.text = d['reportBy']?.toString() ?? '';
    }
    _machine ??= widget.machines.isNotEmpty ? widget.machines.first : null;
    _department ??= widget.departments.first;
    _product ??= widget.productNames.isNotEmpty ? widget.productNames.first : null;
    _previousReadingCtrl.addListener(_onFormChanged);
    _meterReadingNowCtrl.addListener(_onFormChanged);
  }

  void _onFormChanged() => setState(() {});

  @override
  void dispose() {
    _previousReadingCtrl.removeListener(_onFormChanged);
    _meterReadingNowCtrl.removeListener(_onFormChanged);
    _workOrderCtrl.dispose();
    _previousReadingCtrl.dispose();
    _meterReadingNowCtrl.dispose();
    _tonnesCtrl.dispose();
    _reportByCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_machine == null) {
      setState(() => _validationMsg = 'Please select a machine.');
      return false;
    }
    final prev = _parseNum(_previousReadingCtrl.text);
    if (prev == null) {
      setState(() => _validationMsg = 'Please enter a valid Previous Reading value.');
      return false;
    }
    final now = _parseNum(_meterReadingNowCtrl.text);
    if (now == null) {
      setState(() => _validationMsg = 'Please enter a valid Meter Reading Now value.');
      return false;
    }
    if (now < prev) {
      setState(() => _validationMsg = 'Meter Reading Now must be greater than or equal to Previous Reading.');
      return false;
    }
    if (_tonnesCtrl.text.trim().isEmpty || double.tryParse(_tonnesCtrl.text.trim()) == null) {
      setState(() => _validationMsg = 'Please enter a valid Tonnes value.');
      return false;
    }
    setState(() => _validationMsg = null);
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    try {
      final now = _nowMYT();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final prevReading = _parseNum(_previousReadingCtrl.text) ?? 0;
      final meterNow = _parseNum(_meterReadingNowCtrl.text) ?? 0;

      await widget.onSubmit({
        'date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        if (!_isEdit) 'time': timeStr,
        'machine': _machine,
        'workOrderNumber': _workOrderCtrl.text.trim(),
        'product': _product ?? '',
        'processDepartment': _department,
        'previousReading': prevReading,
        'meterReadingNow': meterNow,
        'kwh': meterNow - prevReading,
        'tonnes': double.tryParse(_tonnesCtrl.text.trim()) ?? 0,
        'reportBy': _reportByCtrl.text.trim(),
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _validationMsg = e.toString());
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      formKey: _formKey,
      icon: _isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
      title: _isEdit ? 'Edit Production Output' : 'Add Production Output (Kg)',
      subtitle: _isEdit ? 'Update this production output entry' : 'Log a new production output record',
      requiredNote: true,
      submitLabel: _isEdit ? 'UPDATE' : 'ADD ENTRY',
      cancelLabel: 'CANCEL',
      onSubmit: () async {
        await _submit();
        return false;
      },
      sections: [
        CustomDialogSection(
          number: 1,
          title: 'Production Details',
          subtitle: 'Date, machine and work order information.',
          children: [
            polRow2(
              polDateField(context, _date, _pickDate),
              polDropdown(context, 'Machine *', widget.machines, _machine, (v) => setState(() => _machine = v)),
            ),
            const SizedBox(height: 16),
            polRow2(
              polTextField(context, 'Work Order ID', _workOrderCtrl, hint: 'e.g. 120'),
              polDropdown(context, 'Process Department', widget.departments, _department, (v) => setState(() => _department = v)),
            ),
          ],
        ),
        CustomDialogSection(
          number: 2,
          title: 'Output Metrics',
          subtitle: 'Meter readings, product type and production quantities.',
          children: [
            polRow2(
              polTextField(context, 'Previous Reading *', _previousReadingCtrl, hint: 'e.g. 39780.00', isNumber: true),
              polTextField(context, 'Meter Reading Now *', _meterReadingNowCtrl, hint: 'e.g. 42815.20', isNumber: true),
            ),
            const SizedBox(height: 16),
            polRow2(
              polDropdown(
                context,
                'Product type',
                widget.productNames.isNotEmpty ? widget.productNames : ['—'],
                _product,
                (v) => setState(() => _product = v),
              ),
              polTextField(context, 'Tonnes produced *', _tonnesCtrl, hint: 'e.g. 120', isNumber: true),
            ),
            const SizedBox(height: 16),
            polRow2(
              polReadOnlyField(context, 'kWh consumed', _kwhConsumed != null ? _kwhConsumed!.toStringAsFixed(2) : '-'),
              polTextField(context, 'Report By', _reportByCtrl, hint: 'e.g. John'),
            ),
            if (_validationMsg != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.warning_amber, color: Color(0xFFF59E0B), size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_validationMsg!, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
                ),
              ]),
            ],
          ],
        ),
      ],
    );
  }
}
