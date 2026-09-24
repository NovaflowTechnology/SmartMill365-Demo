import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// CHANNEL MAPPING — METRIC FIELD dropdown: the second half of a two-level
/// Device ID + Field mapping (mirrors Group Energy Command Center's
/// "CHANNEL MAPPING — DATA SCOPE" / "— METRIC FIELD" columns). Shown next
/// to a device dropdown so a slot maps to both a source device and which
/// telemetry field on it to read.
class MetricFieldDropdown extends StatelessWidget {
  const MetricFieldDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.width,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final field = SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            isDense: true,
            value: value != null && options.contains(value) ? value : null,
            hint: Text('– select field –', style: GoogleFonts.poppins(fontSize: 11, color: t.txtSubtle)),
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: t.txtMuted),
            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
            dropdownColor: isLight ? Colors.white : const Color(0xFF111827),
            items: [for (final f in options) DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))],
            onChanged: onChanged,
          ),
        ),
      ),
    );

    return field;
  }
}
