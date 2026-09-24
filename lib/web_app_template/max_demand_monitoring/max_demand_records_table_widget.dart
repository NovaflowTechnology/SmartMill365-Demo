import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_theme.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_util.dart';

class MaxDemandEventRecordsTable extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final double contractCapacity;
  final double highRiskMin;
  final double mediumRiskMin;
  final double mediumRiskMax;
  final double lowRiskMin;
  final double lowRiskMax;

  const MaxDemandEventRecordsTable({
    super.key,
    required this.events,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.contractCapacity,
    this.highRiskMin = 80.0,
    this.mediumRiskMin = 60.0,
    this.mediumRiskMax = 80.0,
    this.lowRiskMin = 0.0,
    this.lowRiskMax = 60.0,
  });

  double _calculatePercentage(String peakLoad) {
    if (contractCapacity <= 0) return 0.0;
    double maxDemand = double.tryParse(peakLoad) ?? 0.0;
    return (maxDemand / contractCapacity) * 100;
  }

  String _getRiskLevel(double percentage) {
    if (percentage >= 100) return 'Critical';
    if (percentage >= highRiskMin && percentage < 100) return 'High';
    if (percentage >= mediumRiskMin && percentage < mediumRiskMax) return 'Medium';
    if (percentage >= lowRiskMin && percentage < lowRiskMax) return 'Low';
    return 'Normal';
  }

  String _getStatus(double percentage) {
    if (percentage >= 100) return 'Critical';
    if (percentage >= highRiskMin) return 'Warning';
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => _buildContent(context, sizing),
    );
  }

  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: sizing.accentW,
                    height: sizing.titleFs.clamp(12.0, 16.0) * 1.2,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withOpacity(0.9),
                          blurRadius: sizing.pad * 0.7,
                          spreadRadius: sizing.accentW * 0.3,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: sizing.pad * 0.5),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Monthly Maximum Demand Event Records',
                        style: GoogleFonts.poppins(
                          fontSize: sizing.titleFs.clamp(12.0, 16.0),
                          fontWeight: FontWeight.w700,
                          color: isLight ? theme.txtPrimary : Colors.white,
                          letterSpacing: 0.6,
                          shadows: isLight ? null : [
                            Shadow(
                              color: theme.primary.withOpacity(0.7),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, color: theme.secondaryText, size: 20),
                    onPressed: onRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Risk levels are calculated based on: (Max Demand / Contract Capacity) × 100',
                  child: Icon(Icons.info_outline, color: theme.secondaryText, size: 20),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTableContent(context, sizing),
      ],
    );
  }

  Widget _buildTableContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);

    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(color: theme.error, fontSize: sizing.bodyFs.clamp(10.0, 13.0)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            'No demand event records available',
            style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: sizing.bodyFs.clamp(10.0, 13.0)),
          ),
        ),
      );
    }

    return _buildDataTable(context, sizing);
  }

  // Below this, 6 flex-based columns squeeze into unreadable slivers — switch
  // to fixed column widths inside a horizontally-scrolling table instead.
  static const double _colDate = 90;
  static const double _colTime = 70;
  static const double _colDuration = 90;
  static const double _colMaxDemand = 140;
  static const double _colContractPct = 150;
  static const double _colStatus = 110;

  Widget _tableCell(bool narrow, double width, {required int flex, required Widget child}) {
    return narrow ? SizedBox(width: width, child: child) : Expanded(flex: flex, child: child);
  }

  Widget _buildDataTable(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final bool narrow = MediaQuery.sizeOf(context).width < kBreakpointMedium;

    final table = Column(
      children: [
        // Header Row
        Container(
          color: theme.primary.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              _tableCell(narrow, _colDate, flex: 2, child: _buildHeaderCell(context, 'Date', sizing)),
              _tableCell(narrow, _colTime, flex: 2, child: _buildHeaderCell(context, 'Time', sizing)),
              _tableCell(narrow, _colDuration, flex: 2, child: _buildHeaderCell(context, 'Duration', sizing)),
              _tableCell(narrow, _colMaxDemand, flex: 2, child: _buildHeaderCell(context, 'Maximum Demand (kW)', sizing)),
              _tableCell(narrow, _colContractPct, flex: 3, child: _buildHeaderCell(context, 'Contract Capacity %', sizing)),
              _tableCell(narrow, _colStatus, flex: 2, child: _buildHeaderCell(context, 'Status', sizing)),
            ],
          ),
        ),
        // Data Rows
        ...events.asMap().entries.map((entry) {
          final record = entry.value;
          double percentage = _calculatePercentage(record['peakLoad'] ?? '0');
          String riskLevel = _getRiskLevel(percentage);
          String status = _getStatus(percentage);
          return _buildDataRow(
            context,
            record['date'] ?? '',
            record['time'] ?? '',
            record['duration'] ?? '',
            record['peakLoad'] ?? '',
            percentage,
            riskLevel,
            status,
            entry.key,
            sizing,
            narrow,
          );
        }),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primary.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: narrow
            ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: table)
            : table,
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String label, CardSizing sizing) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: sizing.bodyFs.clamp(10.0, 13.0),
        fontWeight: FontWeight.w600,
        color: FlutterFlowTheme.of(context).primaryText,
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    String date,
    String time,
    String duration,
    String peakLoad,
    double percentage,
    String riskLevel,
    String status,
    int index,
    CardSizing sizing,
    bool narrow,
  ) {
    final theme = FlutterFlowTheme.of(context);

    return InkWell(
      onTap: () {},
      hoverColor: theme.primary.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.primary.withOpacity(0.1), width: 1)),
        ),
        child: Row(
          children: [
            _tableCell(narrow, _colDate, flex: 2, child: _buildDataCellText(context, date, sizing)),
            _tableCell(narrow, _colTime, flex: 2, child: _buildDataCellText(context, time, sizing)),
            _tableCell(narrow, _colDuration, flex: 2, child: _buildDataCellText(context, duration, sizing)),
            _tableCell(narrow, _colMaxDemand, flex: 2, child: _buildDataCellText(context, peakLoad, sizing)),
            _tableCell(narrow, _colContractPct, flex: 3, child: _buildPercentageCell(context, percentage, sizing)),
            _tableCell(narrow, _colStatus, flex: 2, child: _buildRiskLevelBadge(context, riskLevel, sizing)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCellText(BuildContext context, String value, CardSizing sizing) {
    return Text(
      value,
      style: GoogleFonts.poppins(
        fontSize: sizing.bodyFs.clamp(10.0, 12.0),
        color: FlutterFlowTheme.of(context).secondaryText,
      ),
    );
  }

  Widget _buildPercentageCell(BuildContext context, double percentage, CardSizing sizing) {
    Color percentageColor;
    if (percentage >= 100) {
      percentageColor = const Color(0xFFEF5350);
    } else if (percentage >= highRiskMin) {
      percentageColor = const Color(0xFFFFD54F);
    } else if (percentage >= mediumRiskMin) {
      percentageColor = const Color(0xFFFFA726);
    } else {
      percentageColor = const Color(0xFF66BB6A);
    }

    return Row(
      children: [
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: GoogleFonts.poppins(
            fontSize: sizing.bodyFs.clamp(10.0, 12.0),
            fontWeight: FontWeight.w600,
            color: percentageColor,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRiskLevelBadge(BuildContext context, String riskLevel, CardSizing sizing) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (riskLevel) {
      case 'Critical':
        backgroundColor = const Color(0xFFEF5350).withOpacity(0.3);
        textColor = const Color(0xFFEF5350);
        icon = Icons.error;
        break;
      case 'High':
        backgroundColor = const Color(0xFFFFD54F).withOpacity(0.3);
        textColor = const Color(0xFFFFD54F);
        icon = Icons.warning;
        break;
      case 'Medium':
        backgroundColor = const Color(0xFFFFA726).withOpacity(0.3);
        textColor = const Color(0xFFFFA726);
        icon = Icons.info;
        break;
      case 'Low':
        backgroundColor = const Color(0xFF66BB6A).withOpacity(0.3);
        textColor = const Color(0xFF66BB6A);
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = const Color(0xFF42A5F5).withOpacity(0.3);
        textColor = const Color(0xFF42A5F5);
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            riskLevel,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: sizing.bodyFs.clamp(9.0, 11.0),
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
