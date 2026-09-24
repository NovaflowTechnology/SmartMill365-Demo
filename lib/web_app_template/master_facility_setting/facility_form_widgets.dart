import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';

const _kSurfaceCard = Color.fromRGBO(26, 35, 58, 1);
const _kBorder      = Color.fromRGBO(38, 52, 82, 1);
const _kTextPrimary = Color.fromRGBO(226, 232, 240, 1);
const _kTextMuted   = Color.fromRGBO(107, 122, 153, 1);
const _kTextHint    = Color.fromRGBO(72, 79, 88, 1);
const _kFill        = Color.fromRGBO(22, 33, 62, 1);
const _kTextLabel   = Color.fromRGBO(148, 163, 196, 1);

/// Section label with accent bar
Widget facilitySection(BuildContext context, String label) {
  final theme = FlutterFlowTheme.of(context);
  return Row(
    children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: theme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          height: 0.5,
          color: theme.primary.withOpacity(0.25),
        ),
      ),
    ],
  );
}

/// Two-column row
Widget facilityRow2(Widget left, Widget right) {
  return Row(children: [
    Expanded(child: left),
    const SizedBox(width: 16),
    Expanded(child: right),
  ]);
}

/// Text form field
Widget facilityField(
  BuildContext context,
  String label,
  TextEditingController ctrl, {
  bool required = false,
}) {
  final theme = FlutterFlowTheme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: theme.tertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          children: required
              ? [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: theme.tertiary),
                  )
                ]
              : [],
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        style: const TextStyle(color: _kTextPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Enter $label',
          hintStyle: const TextStyle(color: _kTextHint, fontSize: 12),
          filled: true,
          fillColor: _kFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.primary, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.error, width: 0.8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.error, width: 1.2),
          ),
          errorStyle: TextStyle(color: theme.error, fontSize: 11),
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    ],
  );
}

/// Date picker field
Widget facilityDatePicker(
  BuildContext context,
  String label,
  DateTime? date,
  VoidCallback onTap,
) {
  final theme = FlutterFlowTheme.of(context);
  final fmt = date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: theme.tertiary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _kFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: date != null ? theme.primary : _kTextHint,
              ),
              const SizedBox(width: 8),
              Text(
                date != null ? fmt : 'Select date',
                style: TextStyle(
                  color: date != null ? _kTextPrimary : _kTextHint,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Status dropdown widget
class FacilityStatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const FacilityStatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Status',
            style: TextStyle(
              color: theme.tertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.tertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _kFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: _kSurfaceCard,
              style: const TextStyle(color: _kTextPrimary, fontSize: 13),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: _kTextMuted,
                size: 18,
              ),
              items: ['Active', 'Inactive']
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          style: TextStyle(
                            color: s == 'Active'
                                ? const Color(0xFF00C853)
                                : const Color(0xFFFF5252),
                            fontSize: 13,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog shell widget
class FacilityDialogShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget footer;
  final ScrollController scroll;

  const FacilityDialogShell({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.body,
    required this.footer,
    required this.scroll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: responsiveDialogWidth(context, 800),
      constraints: const BoxConstraints(maxHeight: 700),
      decoration: BoxDecoration(
        color: _kSurfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: _kBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                color: _kTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close,
                        color: _kTextMuted, size: 16),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Scrollbar(
              controller: scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(24),
                child: body,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: _kBorder, width: 1)),
            ),
            child: footer,
          ),
        ],
      ),
    );
  }
}

/// Footer action buttons
class FacilityDialogActions extends StatelessWidget {
  final String submitLabel;
  final bool loading;
  final VoidCallback onSubmit;

  const FacilityDialogActions({
    super.key,
    required this.submitLabel,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kTextMuted,
            side: const BorderSide(color: _kBorder, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: loading ? null : onSubmit,
          icon: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined, size: 15, color: Colors.white),
          label: Text(
            loading ? 'Saving...' : submitLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2661B6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}

/// Date picker helper function
Future<void> showFacilityDatePicker(
  BuildContext context, {
  required Function(DateTime) onPicked,
  DateTime? initial,
}) async {
  final theme = FlutterFlowTheme.of(context);
  final picked = await showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    builder: (ctx, child) => Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: theme.primary,
          surface: _kSurfaceCard,
        ),
        dialogBackgroundColor: _kSurfaceCard,
      ),
      child: child!,
    ),
  );
  if (picked != null) onPicked(picked);
}

/// Format DateTime to dd/MM/yyyy
String formatFacilityDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Parse dd/MM/yyyy string to DateTime
DateTime? parseFacilityDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final p = raw.split('/');
    if (p.length != 3) return null;
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  } catch (_) {
    return null;
  }
}

/// Column definition model
class FacilityColDef {
  final String label;
  final String key;
  final double flex;
  final bool sortable;
  const FacilityColDef(this.label, this.key,
      {this.flex = 1.0, this.sortable = false});
}

class FacilityEquipmentPicker extends StatelessWidget {
  final List<EquipmentItem> equipments;
  final EquipmentItem? selected;
  final ValueChanged<EquipmentItem?> onChanged;
  final VoidCallback? onEmpty;
  final bool isRequired;

  const FacilityEquipmentPicker({
    super.key,
    required this.equipments,
    required this.selected,
    required this.onChanged,
    this.onEmpty,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (isRequired)
            Text('* ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: t.tertiary)),
          Text('EQUIPMENT NAME / ID',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:  _kTextLabel,
                  letterSpacing: 0.7)),
        ]),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: equipments.isEmpty
              ? _EmptyBanner(key: const ValueKey('empty'), onEmpty: onEmpty)
              : _PickerField(
                  key: const ValueKey('picker'),
                  equipments: equipments,
                  selected: selected,
                  onChanged: onChanged,
                  onEmpty: onEmpty,
                  isRequired: isRequired,
                ),
        ),
      ],
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  final VoidCallback? onEmpty;
  const _EmptyBanner({super.key, this.onEmpty});

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onEmpty,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: t.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.error.withOpacity(0.4), width: 1),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_outlined, size: 16, color: t.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No equipment registered. Tap to add equipment first.',
              style: TextStyle(color: t.error, fontSize: 13),
            ),
          ),
          Icon(Icons.open_in_new, size: 14, color: t.error),
        ]),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final List<EquipmentItem> equipments;
  final EquipmentItem? selected;
  final ValueChanged<EquipmentItem?> onChanged;
  final VoidCallback? onEmpty;
  final bool isRequired;

  const _PickerField({
    super.key,
    required this.equipments,
    required this.selected,
    required this.onChanged,
    required this.onEmpty,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return FormField<EquipmentItem>(
      initialValue: selected,
      validator: isRequired ? (v) => v == null ? 'Equipment is required' : null : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _kFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.hasError ? t.error : _kBorder,
                width: state.hasError ? 1 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EquipmentItem>(
                value: selected,
                isExpanded: true,
                itemHeight: 52,
                hint: const Text('Select equipment',
                    style: TextStyle(color: _kTextHint, fontSize: 13)),
                dropdownColor: _kSurfaceCard,
                style: const TextStyle(color: _kTextPrimary, fontSize: 13),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: _kTextMuted),
                items: equipments.map((e) => DropdownMenuItem(
                  value: e,
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: t.tertiary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.precision_manufacturing_outlined,
                          size: 14, color: t.tertiary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: _kTextPrimary,
                                  fontWeight: FontWeight.w600)),
                          Row(children: [
                            Flexible(
                              child: Text(e.equipmentId,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: _kTextMuted)),
                            ),
                            if (e.workId.isNotEmpty) ...[
                              const Text('  ·  ',
                                  style: TextStyle(
                                      fontSize: 11, color: _kTextHint)),
                              Flexible(
                                child: Text(e.workId,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11, color: t.secondary)),
                              ),
                            ],
                          ]),
                        ],
                      ),
                    ),
                  ]),
                )).toList(),
                onChanged: (item) {
                  onChanged(item);
                  state.didChange(item);
                },
              ),
            ),
          ),

          // ── "Add New" button — selalu tampil ─────────────────────────────
          if (onEmpty != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                onTap: onEmpty,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline, size: 13, color: t.primary),
                      const SizedBox(width: 5),
                      Text(
                        'Add New Equipment',
                        style: TextStyle(
                          fontSize: 12,
                          color: t.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: selected != null
                ? Padding(
                    key: const ValueKey('hint'),
                    padding: const EdgeInsets.only(top: 6, left: 2),
                    child: Row(children: [
                      Icon(Icons.check_circle_outline,
                          size: 13, color: t.secondary),
                      const SizedBox(width: 5),
                      Text(
                        'Type "${selected!.workId}" will be auto-filled',
                        style: TextStyle(fontSize: 12, color: t.secondary),
                      ),
                    ]),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
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
}