import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

Widget polRow2(Widget a, Widget b) => Row(children: [
      Expanded(child: a),
      const SizedBox(width: 16),
      Expanded(child: b),
    ]);

Widget polDateField(
  BuildContext context,
  DateTime date,
  VoidCallback onTap,
) {
  final t = FlutterFlowTheme.of(context);
  final isLight = Theme.of(context).brightness == Brightness.light;
  final fill = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF16213E);
  final border = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF26345A);
  final dateStr =
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Date *',
          style: TextStyle(color: t.tertiary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(children: [
            Expanded(child: Text(dateStr, style: TextStyle(color: t.primaryText, fontSize: 13))),
            Icon(Icons.calendar_today_outlined, size: 16, color: t.secondaryText),
          ]),
        ),
      ),
    ],
  );
}

Widget polDropdown(
  BuildContext context,
  String label,
  List<String> items,
  String? value,
  ValueChanged<String?> onChanged,
) {
  final t = FlutterFlowTheme.of(context);
  final isLight = Theme.of(context).brightness == Brightness.light;
  final fill = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF16213E);
  final border = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF26345A);
  // Deduplicate so Flutter never sees two items with the same value
  final uniqueItems = items.toSet().toList();
  final resolvedValue =
      uniqueItems.contains(value) ? value : (uniqueItems.isNotEmpty ? uniqueItems.first : null);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(color: t.tertiary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: resolvedValue,
        dropdownColor: isLight ? Colors.white : const Color(0xFF1E2432),
        style: TextStyle(color: t.primaryText, fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.primary, width: 1.5)),
        ),
        items: uniqueItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

Widget polReadOnlyField(
  BuildContext context,
  String label,
  String value, {
  String hint = '= Meter Reading Now − Previous Reading',
}) {
  final t = FlutterFlowTheme.of(context);
  final isLight = Theme.of(context).brightness == Brightness.light;
  final fill = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF16213E);
  final border = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF26345A);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(color: t.tertiary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1),
        ),
        child: Text(value,
            style: TextStyle(color: t.primaryText, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 4),
      Text(hint, style: TextStyle(color: t.secondaryText, fontSize: 11)),
    ],
  );
}

Widget polTextField(
  BuildContext context,
  String label,
  TextEditingController ctrl, {
  String hint = '',
  bool isNumber = false,
}) {
  final t = FlutterFlowTheme.of(context);
  final isLight = Theme.of(context).brightness == Brightness.light;
  final fill = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF16213E);
  final border = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF26345A);
  final hintColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF48474F);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(color: t.tertiary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType:
            isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: TextStyle(color: t.primaryText, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 12),
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: t.primary, width: 1.5)),
        ),
      ),
    ],
  );
}
