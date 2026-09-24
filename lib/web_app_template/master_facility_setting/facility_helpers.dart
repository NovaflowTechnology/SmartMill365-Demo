import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/components/dialogs/dialog_validator.dart';

const _kBase        = Color.fromRGBO(17, 24, 39, 1);
const _kSurfaceCard = Color.fromRGBO(26, 35, 58, 1);
const _kBorder      = Color.fromRGBO(38, 52, 82, 1);
const _kBorderInput = Color.fromRGBO(56, 78, 120, 0.7);
const _kTextPrimary = Color.fromRGBO(226, 232, 240, 1);
const _kTextLabel   = Color.fromRGBO(148, 163, 196, 1);
const _kTextMuted   = Color.fromRGBO(110, 118, 129, 1);
const _kTextHint    = Color.fromRGBO(72, 79, 88, 1);
const _kFill        = Color.fromRGBO(22, 33, 62, 1);

Widget facilityFieldLabel(BuildContext context, String label,
    {bool isRequired = false}) {
  final t = FlutterFlowTheme.of(context);
  return Row(children: [
    if (isRequired)
      Text('* ',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF22D3EE))),
    Text(label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF22D3EE),
          letterSpacing: 0.7,
        )),
  ]);
}

InputDecoration facilityInputDeco(BuildContext context, String hint) {
  final t = FlutterFlowTheme.of(context);
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _kTextHint, fontSize: 13),
    filled: true,
    fillColor: _kFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorderInput, width: 1)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorderInput, width: 1)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.primary.withOpacity(0.6), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.error, width: 1)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.error, width: 1.5)),
    errorStyle: TextStyle(fontSize: 11, color: t.error),
  );
}

Widget facilityInputField(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  bool isRequired = false,
  List<ValidatorFn> validators = const [],
}) {
  final all      = [if (isRequired) Validators.required(), ...validators];
  final composed = all.isNotEmpty ? Validators.compose(all) : null;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    facilityFieldLabel(context, label, isRequired: isRequired),
    const SizedBox(height: 6),
    TextFormField(
      controller: controller,
      style: const TextStyle(color: _kTextPrimary, fontSize: 13),
      validator: composed,
      decoration: facilityInputDeco(context,
          label == 'Zone' ? 'e.g. Storage Alpha' : 'Enter ${label.toLowerCase()}'),
    ),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown field
// PERUBAHAN: hapus if realItems.isEmpty, dropdown selalu tampil
// + "Add New" button selalu ada di bawah
// ─────────────────────────────────────────────────────────────────────────────

Widget facilityDropdownField(
  BuildContext context, {
  required String label,
  required List<Map<String, dynamic>> items,
  required String? selectedId,
  required void Function(String? id, String? name) onChanged,
  bool isRequired = false,
  String? emptyMessage,
  VoidCallback? onEmpty,
}) {
  final t         = FlutterFlowTheme.of(context);
  final realItems = items.where((e) => e['id'] != '0').toList();

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    facilityFieldLabel(context, label, isRequired: isRequired),
    const SizedBox(height: 6),
    FormField<String>(
      // FormField's initialValue only applies on the field's first build —
      // it's otherwise ignored on rebuilds, so auto-sync updates from the
      // cubit (e.g. selecting an Equipment) would never show up without
      // this. Keying on selectedId forces a fresh FormField state (and a
      // fresh initialValue) whenever the cubit's value changes externally.
      key: ValueKey('$label-$selectedId'),
      initialValue: realItems.any((e) => e['id'] == selectedId) ? selectedId : null,
      validator: isRequired
          ? (v) => (v == null || v == '0') ? '$label is required' : null
          : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _kFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.hasError ? t.error : _kBorderInput,
                width: state.hasError ? 1.2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.value,
                isExpanded: true,
                hint: Text(
                  label == 'Equipment ID' ? 'Select Equipment' : 'Choose $label',
                  style: const TextStyle(color: _kTextHint, fontSize: 13),
                ),
                dropdownColor: const Color.fromRGBO(26, 35, 58, 1),
                style: const TextStyle(color: _kTextPrimary, fontSize: 13),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: _kTextMuted),
                items: realItems.map((item) => DropdownMenuItem<String>(
                      value: item['id']?.toString(),
                      child: Text(item['name']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: _kTextPrimary)),
                    )).toList(),
                onChanged: (id) {
                  final matched = realItems.firstWhere(
                    (e) => e['id'] == id,
                    orElse: () => {},
                  );
                  onChanged(id, matched['name']?.toString());
                  state.didChange(id);
                },
              ),
            ),
          ),

          // ── "Add New" button — selalu tampil ─────────────────────────────
          if (onEmpty != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEmpty,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline, size: 13, color: const Color(0xFF22D3EE)),
                          const SizedBox(width: 5),
                          Text(
                            'Add New $label',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF22D3EE),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 4),
              child: Text(state.errorText!,
                  style: TextStyle(fontSize: 11, color: t.error)),
            ),
        ],
      ),
    ),
  ]);
}

Widget facilityAutoFillField(BuildContext context, String label, String value) {
  final t        = FlutterFlowTheme.of(context);
  final hasValue = value.isNotEmpty;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF22D3EE),
          letterSpacing: 0.7,
        )),
    const SizedBox(height: 6),
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasValue ? t.secondary.withOpacity(0.06) : _kFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasValue ? t.secondary.withOpacity(0.25) : _kBorderInput,
          width: 1,
        ),
      ),
      child: Text(
        hasValue
            ? value
            : (label == 'PLANT' ? 'System auto-fill' : 'Auto-detected type'),
        style: TextStyle(
          color: hasValue ? _kTextPrimary : _kTextHint,
          fontSize: 13,
          fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    ),
  ]);
}

Widget facilityDateField(
  BuildContext context, {
  required String label,
  required DateTime? value,
  required void Function(DateTime) onPicked,
  bool isRequired = false,
}) {
  final t = FlutterFlowTheme.of(context);
  return FormField<DateTime>(
    initialValue: value,
    validator: isRequired ? (v) => v == null ? '$label is required' : null : null,
    builder: (state) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        facilityFieldLabel(context, label, isRequired: isRequired),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                      primary: t.primary,
                      surface: _kSurfaceCard),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              onPicked(picked);
              state.didChange(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.hasError ? t.error : _kBorderInput,
                width: state.hasError ? 1.2 : 1,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  value != null
                      ? '${value.day.toString().padLeft(2, '0')}/'
                          '${value.month.toString().padLeft(2, '0')}/'
                          '${value.year}'
                      : 'Select date',
                  style: TextStyle(
                      color: value != null ? _kTextPrimary : _kTextHint,
                      fontSize: 13),
                ),
              ),
              Icon(Icons.calendar_today_outlined,
                  size: 15,
                  color: state.hasError ? t.error : _kTextMuted),
            ]),
          ),
        ),
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(state.errorText!,
                style: TextStyle(fontSize: 11, color: t.error)),
          ),
      ],
    ),
  );
}

Widget facilityStatusToggle(
  BuildContext context,
  String status,
  void Function(bool) onChanged,
) {
  final t        = FlutterFlowTheme.of(context);
  final isActive = status == 'Active';
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('SYSTEM STATUS',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF22D3EE),
          letterSpacing: 0.7,
        )),
    const SizedBox(height: 6),
    Row(children: [
      Transform.scale(
        scale: 0.85,
        child: Switch(
          value: isActive,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: t.success,
          inactiveThumbColor: _kTextMuted,
          inactiveTrackColor: _kBorder,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? t.success : _kTextMuted,
          letterSpacing: 0.5,
        ),
      ),
    ]),
  ]);
}

Widget facilityLoadingView(BuildContext context) => Center(
      child: CircularProgressIndicator(
          color: FlutterFlowTheme.of(context).primary, strokeWidth: 2),
    );

Widget facilityErrorView(
  BuildContext context, {
  required String message,
  required VoidCallback onRetry,
  required VoidCallback onCancel,
}) {
  final t = FlutterFlowTheme.of(context);
  return AlertDialog(
    backgroundColor: _kSurfaceCard,
    title: const Text('Failed to load data',
        style: TextStyle(color: _kTextPrimary)),
    content: Text(message, style: const TextStyle(color: _kTextLabel)),
    actions: [
      TextButton(
          onPressed: onRetry,
          child: Text('Retry', style: TextStyle(color: t.primary))),
      TextButton(
          onPressed: onCancel,
          child: const Text('Cancel',
              style: TextStyle(color: _kTextMuted))),
    ],
  );
}

Widget facilityDeviceTypeDropdown(
  BuildContext context, {
  required List<Map<String, dynamic>> deviceTypes,
  required String? selectedName,
  required void Function(String? name) onChanged,
}) {
  final t = FlutterFlowTheme.of(context);
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('DEVICE TYPE',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF22D3EE),
          letterSpacing: 0.7,
        )),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(
        color: _kFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorderInput, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: deviceTypes.any((dt) => dt['name']?.toString() == selectedName)
              ? selectedName
              : null,
          isExpanded: true,
          hint: const Text('Select Device Type',
              style: TextStyle(color: _kTextHint, fontSize: 13)),
          dropdownColor: const Color.fromRGBO(26, 35, 58, 1),
          style: const TextStyle(color: _kTextPrimary, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _kTextMuted),
          items: deviceTypes.map((dt) {
            final name = dt['name']?.toString() ?? '';
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name,
                  style: const TextStyle(color: _kTextPrimary, fontSize: 13)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    ),
  ]);
}

const _kImpactCategories = ['PRODUCTION', 'ADJUSTABLE', 'AUXILIARY', 'BACKUP'];

const _kImpactColors = {
  'ADJUSTABLE': Color(0xFF10B981),
  'PRODUCTION': Color(0xFF64748B),
  'AUXILIARY':  Color(0xFFF59E0B),
  'BACKUP':     Color(0xFF6366F1),
};

Widget facilityImpactCategoryDropdown(
  BuildContext context, {
  required String selected,
  required void Function(String category) onChanged,
}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('IMPACT CATEGORY',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF22D3EE),
          letterSpacing: 0.7,
        )),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(
        color: _kFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorderInput, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _kImpactCategories.contains(selected) ? selected : 'PRODUCTION',
          isExpanded: true,
          dropdownColor: const Color.fromRGBO(26, 35, 58, 1),
          style: const TextStyle(color: _kTextPrimary, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _kTextMuted),
          items: _kImpactCategories.map((cat) {
            final color = _kImpactColors[cat] ?? const Color(0xFF64748B);
            return DropdownMenuItem<String>(
              value: cat,
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: 10),
                Text(cat,
                    style: TextStyle(
                        color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(_impactCategoryHint(cat),
                    style: const TextStyle(color: _kTextMuted, fontSize: 11)),
              ]),
            );
          }).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    ),
    const SizedBox(height: 4),
    Text(
      _impactCategoryDescription(selected),
      style: const TextStyle(color: _kTextMuted, fontSize: 11),
    ),
  ]);
}

String _impactCategoryHint(String cat) {
  switch (cat) {
    case 'ADJUSTABLE': return '— can be shut down to reduce MD';
    case 'PRODUCTION': return '— critical, must stay running';
    case 'AUXILIARY':  return '— support systems, low priority';
    case 'BACKUP':     return '— standby, rarely active';
    default:           return '';
  }
}

String _impactCategoryDescription(String cat) {
  switch (cat) {
    case 'ADJUSTABLE': return 'This machine will be flagged first for shutdown during MD overflow risk.';
    case 'PRODUCTION': return 'Critical production machine — will not be suggested for shutdown.';
    case 'AUXILIARY':  return 'Support system — may be considered during high-risk periods.';
    case 'BACKUP':     return 'Standby/backup unit — only active when needed.';
    default:           return '';
  }
}