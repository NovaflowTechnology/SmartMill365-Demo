import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import '../md_insight_report_colors.dart';
import 'report_panel_widget.dart';
import 'section_header_widget.dart';

/// "Cost Analysis" card: headline surcharge + excess/tariff/billing period on
/// the left, a bordered cost-breakdown table on the right, and a potential
/// saving banner below.
class CostAnalysisSection extends StatelessWidget {
  final double contractCapacity;
  final double mdRate;
  final double excessKw;
  final double baseCharge;
  final double excessCharge;
  final double totalSurcharge;
  final String billingPeriodLabel;

  const CostAnalysisSection({
    super.key,
    required this.contractCapacity,
    required this.mdRate,
    required this.excessKw,
    required this.baseCharge,
    required this.excessCharge,
    required this.totalSurcharge,
    required this.billingPeriodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      builder: (context, sizing) {
        final theme = FlutterFlowTheme.of(context);
        Widget kv(String label, String value) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: theme.secondaryText)),
                  Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: theme.primaryText)),
                ],
              ),
            );
        Widget breakdownRow(String label, String value, {bool bold = false}) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText))),
                  Text(value, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? MdReportColors.red : theme.primaryText)),
                ],
              ),
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(icon: Icons.attach_money_rounded, title: 'Cost Analysis'),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 420;
              final leftCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Estimated MD Surcharge', style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText)),
                  Text('RM ${totalSurcharge.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: MdReportColors.red)),
                  const SizedBox(height: 8),
                  kv('Excess Demand', '${excessKw.toStringAsFixed(0)} kW'),
                  kv('Tariff Rate (MD)', 'RM ${mdRate.toStringAsFixed(2)} /kW'),
                  kv('Billing Period', billingPeriodLabel),
                ],
              );
              final rightCol = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: theme.alternate.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cost Breakdown', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.primaryText)),
                    const Divider(height: 14),
                    breakdownRow('Base MD Charge (${contractCapacity.toStringAsFixed(0)} kW)', 'RM ${baseCharge.toStringAsFixed(2)}'),
                    breakdownRow('Excess Demand Charge (${excessKw.toStringAsFixed(0)} kW)', 'RM ${excessCharge.toStringAsFixed(2)}'),
                    const Divider(height: 14),
                    breakdownRow('Total Estimated MD Charge', 'RM ${totalSurcharge.toStringAsFixed(2)}', bold: true),
                  ],
                ),
              );

              if (!isWide) return Column(children: [leftCol, const SizedBox(height: 12), rightCol]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: leftCol), const SizedBox(width: 14), Expanded(child: rightCol)]);
            }),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: MdReportColors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: MdReportColors.green.withOpacity(0.3))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.attach_money_rounded, color: MdReportColors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Potential Saving Opportunity', style: GoogleFonts.poppins(fontSize: 12.5, color: MdReportColors.green, fontWeight: FontWeight.w700)),
                          Text('Reduce Maximum Demand to ${contractCapacity.toStringAsFixed(0)} kW', style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText)),
                          Text('Potential Monthly Saving', style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText)),
                        ],
                      ),
                    ),
                    Text('RM ${excessCharge.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 21, fontWeight: FontWeight.w800, color: MdReportColors.green)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
