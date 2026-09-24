import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../md_insight_report_colors.dart';
import 'report_panel_widget.dart';
import 'section_header_widget.dart';

/// "Capacity Analysis" card: a 0–150% utilization gauge, a stacked info panel
/// (contract capacity / monthly MD / exceeded / remaining / available), and a
/// warning banner when over capacity.
class CapacityAnalysisSection extends StatelessWidget {
  final double contractCapacity;
  final double monthlyMaxDemandKw;
  final double utilizationPct;
  final double exceededKw;
  final String warningText;

  const CapacityAnalysisSection({
    super.key,
    required this.contractCapacity,
    required this.monthlyMaxDemandKw,
    required this.utilizationPct,
    required this.exceededKw,
    required this.warningText,
  });

  bool get _isOverCapacity => utilizationPct > 100;

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      builder: (context, sizing) {
        final theme = FlutterFlowTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(number: '3', title: 'Capacity Analysis'),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: _gauge(theme)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _infoRow(context, 'Contract Capacity', '${contractCapacity.toStringAsFixed(0)} kW'),
                        _infoRow(context, 'Monthly Maximum Demand', '${monthlyMaxDemandKw.toStringAsFixed(0)} kW'),
                        _infoRow(context, 'Exceeded Capacity', '${exceededKw.toStringAsFixed(0)} kW', color: _isOverCapacity ? MdReportColors.red : null),
                        _infoRow(context, 'Remaining Capacity', '${_isOverCapacity ? '-' : ''}${exceededKw.toStringAsFixed(0)} kW', color: _isOverCapacity ? MdReportColors.red : null),
                        _infoRow(context, 'Available Capacity', _isOverCapacity ? '0%' : '${(100 - utilizationPct).clamp(0, 100).toStringAsFixed(0)}%', color: _isOverCapacity ? MdReportColors.red : null),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isOverCapacity)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(color: MdReportColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: MdReportColors.red.withOpacity(0.4))),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: MdReportColors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(warningText, style: GoogleFonts.poppins(fontSize: 12.5, color: MdReportColors.red))),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _gauge(FlutterFlowTheme theme) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 150,
          startAngle: 180,
          endAngle: 0,
          showLabels: true,
          axisLabelStyle: GaugeTextStyle(fontSize: 10.5, color: theme.secondaryText),
          axisLineStyle: const AxisLineStyle(thickness: 0),
          ranges: [
            GaugeRange(startValue: 0, endValue: 100, color: MdReportColors.green, startWidth: 0.22, endWidth: 0.22, sizeUnit: GaugeSizeUnit.factor),
            GaugeRange(startValue: 100, endValue: 120, color: MdReportColors.orange, startWidth: 0.22, endWidth: 0.22, sizeUnit: GaugeSizeUnit.factor),
            GaugeRange(startValue: 120, endValue: 150, color: MdReportColors.red, startWidth: 0.22, endWidth: 0.22, sizeUnit: GaugeSizeUnit.factor),
          ],
          pointers: [NeedlePointer(value: utilizationPct.clamp(0, 150), needleColor: theme.primaryText, knobStyle: KnobStyle(color: theme.primaryText))],
          annotations: [
            GaugeAnnotation(
              angle: 90,
              positionFactor: 0.65,
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Utilization', style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText)),
                  Text(
                    '${utilizationPct.toStringAsFixed(2)}%',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: _isOverCapacity ? MdReportColors.red : theme.primaryText),
                  ),
                  Text(
                    _isOverCapacity ? 'Over Capacity' : 'Within Capacity',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: _isOverCapacity ? MdReportColors.red : MdReportColors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {Color? color}) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: theme.secondaryText)),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color ?? theme.primaryText)),
        ],
      ),
    );
  }
}
