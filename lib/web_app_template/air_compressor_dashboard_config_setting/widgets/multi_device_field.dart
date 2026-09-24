import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../master_facility_setting/models/facility_data.dart';
import 'metric_field_dropdown.dart';

/// "Σ of selected devices" field — a pill per selected Device ID with a
/// remove (×) action, plus a "+ Add device" popup menu of the remaining
/// unselected devices. Used for Total Power, which sums however many
/// compressors are configured. An optional CHANNEL MAPPING — METRIC FIELD
/// dropdown (shown when [fieldOptions] is non-empty) applies the same
/// telemetry field across every selected device in the sum.
class MultiDeviceField extends StatelessWidget {
  const MultiDeviceField({
    super.key,
    required this.label,
    required this.formula,
    required this.devices,
    required this.selectedIds,
    required this.onChanged,
    this.addLabel = '+ Add device',
    this.fieldOptions = const [],
    this.selectedField,
    this.onFieldChanged,
  });

  final String label;
  final String formula;
  final List<FacilityData> devices;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String addLabel;
  final List<String> fieldOptions;
  final String? selectedField;
  final ValueChanged<String?>? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final remaining = devices.where((d) => !selectedIds.contains(d.meterId)).toList();
    final showField = fieldOptions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final id in selectedIds)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(id, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white)),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => onChanged([...selectedIds]..remove(id)),
                                  child: Icon(Icons.close_rounded, size: 13, color: t.error),
                                ),
                              ],
                            ),
                          ),
                        if (remaining.isNotEmpty)
                          PopupMenuButton<String>(
                            tooltip: 'Add device',
                            onSelected: (id) => onChanged([...selectedIds, id]),
                            itemBuilder: (context) => [
                              for (final d in remaining)
                                PopupMenuItem(
                                  value: d.meterId,
                                  child: Text(d.meterName.isNotEmpty ? '${d.meterId} — ${d.meterName}' : d.meterId, style: GoogleFonts.poppins(fontSize: 11.5)),
                                ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: t.primary.withOpacity(0.4)),
                              ),
                              child: Text(addLabel, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: t.primary)),
                            ),
                          ),
                      ],
                    ),
                    if (selectedIds.length > 1) ...[
                      const SizedBox(height: 6),
                      Text('Σ = ${selectedIds.length} devices summed', style: GoogleFonts.poppins(fontSize: 9.5, color: t.success, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selectedIds.isNotEmpty ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  size: 18,
                  color: selectedIds.isNotEmpty ? t.success : t.warning,
                ),
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
