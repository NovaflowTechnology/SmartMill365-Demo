import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../../master_facility_setting/models/facility_data.dart';
import 'metric_field_dropdown.dart';

/// One "Demand Side" load row: fixed label, manual pressure/flow
/// requirement inputs, a live-flow Device ID dropdown, and an optional
/// CHANNEL MAPPING — METRIC FIELD dropdown (shown when [fieldOptions] is
/// non-empty) — mirrors [DeviceFieldRow]'s mapped/pending status icon.
class DemandLoadRow extends StatelessWidget {
  const DemandLoadRow({
    super.key,
    required this.label,
    required this.reqPressureCtrl,
    required this.reqFlowCtrl,
    required this.devices,
    required this.deviceId,
    required this.onDeviceChanged,
    this.fieldOptions = const [],
    this.selectedField,
    this.onFieldChanged,
  });

  final String label;
  final TextEditingController reqPressureCtrl;
  final TextEditingController reqFlowCtrl;
  final List<FacilityData> devices;
  final String? deviceId;
  final ValueChanged<String?> onDeviceChanged;
  final List<String> fieldOptions;
  final String? selectedField;
  final ValueChanged<String?>? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mapped = deviceId != null;
    final showField = fieldOptions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _numberField(t, isLight, reqPressureCtrl, 'bar')),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _numberField(t, isLight, reqFlowCtrl, 'm³/min')),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
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
                      value: deviceId != null && devices.any((d) => d.meterId == deviceId) ? deviceId : null,
                      hint: Text(
                        devices.isEmpty ? 'No devices found' : 'Select Device ID',
                        style: GoogleFonts.poppins(fontSize: 10.5, color: t.txtSubtle),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: t.txtMuted),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
                      dropdownColor: isLight ? Colors.white : const Color(0xFF111827),
                      items: [
                        for (final d in devices)
                          DropdownMenuItem(
                            value: d.meterId,
                            child: Text(d.meterName.isNotEmpty ? '${d.meterId} — ${d.meterName}' : d.meterId, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: devices.isEmpty ? null : onDeviceChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(mapped ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 16, color: mapped ? t.success : t.warning),
            ],
          ),
          if (showField) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(flex: 2, child: SizedBox.shrink()),
                const SizedBox(width: 8),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: MetricFieldDropdown(options: fieldOptions, value: selectedField, onChanged: onFieldChanged ?? (_) {}),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberField(FlutterFlowTheme t, bool isLight, TextEditingController ctrl, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0D1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E2D48)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isLight ? t.txtPrimary : Colors.white),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: '–',
          hintStyle: GoogleFonts.poppins(fontSize: 11, color: t.txtSubtle),
          suffixText: unit,
          suffixStyle: GoogleFonts.poppins(fontSize: 8.5, color: t.txtMuted),
        ),
      ),
    );
  }
}
