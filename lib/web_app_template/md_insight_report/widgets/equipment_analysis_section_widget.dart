import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';

import '../md_insight_report_colors.dart';
import '../models/equipment_row.dart';
import 'report_panel_widget.dart';
import 'section_header_widget.dart';

/// "Equipment Analysis" card: top-N MD contributors table, a donut chart of
/// their share of total peak demand, and a Key Insights panel.
class EquipmentAnalysisSection extends StatelessWidget {
  final List<EquipmentRow> ranking;
  final double totalDemandKw;
  final double totalPct;
  final List<String> keyInsights;

  const EquipmentAnalysisSection({
    super.key,
    required this.ranking,
    required this.totalDemandKw,
    required this.totalPct,
    required this.keyInsights,
  });

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      builder: (context, sizing) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(number: '6', title: 'Equipment Analysis — Top ${ranking.length} Maximum Demand Contributors'),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final table = _table(context);
              final donut = SizedBox(height: 220, child: _donut(context));
              final insights = _keyInsightsPanel(context);
              if (!isWide) {
                return Column(children: [table, const SizedBox(height: 16), donut, const SizedBox(height: 16), insights]);
              }
              // Plain Row (no IntrinsicHeight): Table's intrinsic-height dry
              // layout undercounts its own row height, which made the last
              // "Top N Total" row spill outside the panel. Row's default
              // (non-stretch) cross-axis sizing already sizes to the tallest
              // child without needing an intrinsic pass.
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 3, child: table),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: donut),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: insights),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _table(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final headerStyle = GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: theme.secondaryText);
    final cellStyle = GoogleFonts.poppins(fontSize: 13.5, color: theme.primaryText);
    Widget cell(Widget child) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: child);
    return Table(
      columnWidths: const {0: FixedColumnWidth(36), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.3), 3: FlexColumnWidth(1)},
      children: [
        TableRow(children: [
          cell(Text('Rank', style: headerStyle)),
          cell(Text('Equipment', style: headerStyle)),
          cell(Text('Maximum Demand (kW)', style: headerStyle)),
          cell(Text('% of Total Peak', style: headerStyle)),
        ]),
        for (int i = 0; i < ranking.length; i++)
          TableRow(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.alternate.withOpacity(0.4)))),
            children: [
              cell(Text('${i + 1}', style: cellStyle)),
              cell(Text(ranking[i].name, style: cellStyle)),
              cell(Text(ranking[i].demandKw.toStringAsFixed(0), style: cellStyle)),
              cell(Text('${ranking[i].pctOfPeak.toStringAsFixed(1)}%', style: cellStyle)),
            ],
          ),
        TableRow(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.alternate))),
          children: [
            cell(const SizedBox.shrink()),
            cell(Text('Top ${ranking.length} Total', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: MdReportColors.blue))),
            cell(Text(totalDemandKw.toStringAsFixed(0), style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: MdReportColors.blue))),
            cell(Text('$totalPct%', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: MdReportColors.blue))),
          ],
        ),
      ],
    );
  }

  Widget _donut(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 55,
                  sections: [
                    for (int i = 0; i < ranking.length; i++)
                      PieChartSectionData(value: ranking[i].demandKw, color: MdReportColors.donutSeries[i % MdReportColors.donutSeries.length], radius: 40, showTitle: false),
                  ],
                ),
              ),
              Text('$totalPct%', style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.w800, color: theme.primaryText)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Top ${ranking.length} Contribution\nof Total Peak Demand', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12.5, color: theme.secondaryText)),
      ],
    );
  }

  Widget _keyInsightsPanel(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: theme.alternate.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Key Insights', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: theme.primaryText)),
          const SizedBox(height: 10),
          ...keyInsights.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 15, color: MdReportColors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t, style: GoogleFonts.poppins(fontSize: 13, color: theme.secondaryText, height: 1.35))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
