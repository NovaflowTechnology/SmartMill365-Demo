import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// A labelled date-picker button consistent with the EnergyDataLogger filter bar style.
///
/// Shows "Any date" when [value] is null; highlights in primary colour when set.
/// An inline ✕ clears the selection by calling [onPicked] with null.
class DateFilterBtn extends StatelessWidget {
  final String label;
  final DateTime? value;
  final FlutterFlowTheme t;
  final ValueChanged<DateTime?> onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateFilterBtn({
    super.key,
    required this.label,
    required this.value,
    required this.t,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = value != null;
    final str = isSet
        ? '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/${value!.year}'
        : 'Any date';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: t.secondaryText)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(2020),
              lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isSet ? t.primary.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSet ? t.primary.withOpacity(0.4) : t.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  str,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                    color: isSet ? t.primary : t.secondaryText,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.calendar_today_outlined, size: 13, color: isSet ? t.primary : t.secondaryText),
                if (isSet) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onPicked(null),
                    child: Icon(Icons.close, size: 12, color: t.secondaryText),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
