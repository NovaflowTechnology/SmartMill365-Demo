import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../master_facility_setting/models/facility_data.dart';
import 'metric_field_dropdown.dart';

/// One "Slot → Device ID [+ Metric Field]" mapping row: label + formula
/// hint, a device dropdown sourced from Master Facility Setting, an
/// optional CHANNEL MAPPING — METRIC FIELD dropdown (when [fieldOptions]
/// is non-empty), and a mapped/pending status icon — mirrors the reference
/// mockup's table rows.
class DeviceFieldRow extends StatelessWidget {
  const DeviceFieldRow({
    super.key,
    required this.label,
    required this.formula,
    required this.devices,
    required this.value,
    required this.onChanged,
    this.fieldOptions = const [],
    this.selectedField,
    this.onFieldChanged,
  });

  final String label;
  final String formula;
  final List<FacilityData> devices;
  final String? value;
  final ValueChanged<String?> onChanged;

  // CHANNEL MAPPING — METRIC FIELD: which telemetry field on [value] to
  // read. Hidden when [fieldOptions] is empty (slots that don't offer a
  // field-level mapping).
  final List<String> fieldOptions;
  final String? selectedField;
  final ValueChanged<String?>? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mapped = value != null;
    final showField = fieldOptions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white)),
                    const SizedBox(height: 2),
                    Text(formula, style: GoogleFonts.poppins(fontSize: 9, color: t.txtSubtle)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
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
                      value: value != null && devices.any((d) => d.meterId == value) ? value : null,
                      hint: Text(
                        devices.isEmpty ? 'No devices found' : 'Select Device ID',
                        style: GoogleFonts.poppins(fontSize: 11, color: t.txtSubtle),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: t.txtMuted),
                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                      dropdownColor: isLight ? Colors.white : const Color(0xFF111827),
                      items: [
                        for (final d in devices)
                          DropdownMenuItem(
                            value: d.meterId,
                            child: Text(d.meterName.isNotEmpty ? '${d.meterId} — ${d.meterName}' : d.meterId, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: devices.isEmpty ? null : onChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                mapped ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                size: 18,
                color: mapped ? t.success : t.warning,
              ),
            ],
          ),
          if (showField) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'CHANNEL MAPPING — METRIC FIELD',
                    style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: t.txtSubtle),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: MetricFieldDropdown(options: fieldOptions, value: selectedField, onChanged: onFieldChanged ?? (_) {}),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
