import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/components/card_widget/card_widget.dart';

import 'powerconsumptionenergydetailscard_model.dart';
export 'powerconsumptionenergydetailscard_model.dart';

class PowerconsumptionenergydetailscardWidget extends StatefulWidget {
  final String period;
  final List<Map<String, dynamic>> chartData;
  final double totalEnergy;
  final ValueChanged<String> onPeriodChanged;
  final bool isLoading;
  final String lastPeriod;

  const PowerconsumptionenergydetailscardWidget({
    super.key,
    required this.period,
    required this.chartData,
    required this.totalEnergy,
    required this.lastPeriod,
    required this.onPeriodChanged,
    required this.isLoading,
  });

  @override
  State<PowerconsumptionenergydetailscardWidget> createState() =>
      PowerconsumptionenergydetailscardWidgetState();
}

class PowerconsumptionenergydetailscardWidgetState
    extends State<PowerconsumptionenergydetailscardWidget> {
  late PowerconsumptionenergydetailscardModel _model;

  final NumberFormat _numberFormatWithDecimals =
      NumberFormat('#,##0.000', 'en_US');
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model =
        createModel(context, () => PowerconsumptionenergydetailscardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _formatNumber(double number) {
    return _numberFormat.format(number.round());
  }

  String _formatYAxisNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (widget.period.toLowerCase() == "hourly") {
      return value.toStringAsFixed(2);
    } else {
      final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return value
          .toStringAsFixed(0)
          .replaceAllMapped(formatter, (Match m) => '${m[1]},');
    }
  }

  double _calculateYAxisInterval(double maxY) {
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    return maxY / 5;
  }

  String _formatLabel(int index) {
    if (index >= 0 && index < widget.chartData.length) {
      return widget.chartData[index]['label'].toString();
    }
    return "";
  }

  List<BarChartGroupData> _buildBarGroups(double maxY) {
    return widget.chartData.asMap().entries.map((entry) {
      final dataPoint = entry.value;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: (dataPoint['value'] is num)
                ? (dataPoint['value'] as num).toDouble()
                : 0.0,
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.6), // Muted, solid flat color for zero eye strain
            width: 24, // Wider bars for the pill effect
            borderRadius: BorderRadius.circular(8), // Softer corners, less pill-like
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: FlutterFlowTheme.of(context).primary.withOpacity(0.05), // Extremely faint track
            ),
          )
        ],
      );
    }).toList();
  }

  // ── Footer ───────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Usage',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
            Text(
              "${_formatNumber(widget.totalEnergy)} kWh",
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).primary,
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'vs Last Period',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
            Text(
              widget.lastPeriod,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).tertiary,
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Header with dropdown ─────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Energy Consumption',
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  fontFamily: 'Poppins',
                  letterSpacing: 0.0,
                  font: GoogleFonts.poppins(),
                ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 118,
          height: 40,
          child: FlutterFlowDropDown<String>(
            controller: _model.dropDownValueController ??=
                FormFieldController<String>(null),
            options: const ['Daily', 'Monthly', 'Yearly'],
            onChanged: (newVal) {
              if (newVal != null) {
                setState(() {
                  _model.dropDownValue = newVal.toLowerCase();
                });
                widget.onPeriodChanged(newVal.toLowerCase());
              }
            },
            width: 118,
            height: 40,
            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  letterSpacing: 0.0,
                  font: GoogleFonts.poppins(),
                ),
            hintText: 'Daily',
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 24,
            ),
            fillColor: FlutterFlowTheme.of(context).secondary,
            elevation: 2,
            borderColor: FlutterFlowTheme.of(context).primary.withOpacity(0.5),
            borderWidth: 1,
            borderRadius: 8,
            margin: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
            hidesUnderline: true,
            isOverButton: false,
            isSearchable: false,
            isMultiSelect: false,
            value: null,
          ),
        ),
      ],
    );
  }

  // ── BarChartData ─────────────────────────────────────────────────
  BarChartData _buildChartData(double minY, double maxY) {
    final yAxisInterval = _calculateYAxisInterval(maxY);
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: minY,
      maxY: maxY,
      barGroups: _buildBarGroups(maxY),
      gridData: FlGridData(
        show: true,
        horizontalInterval: yAxisInterval,
        getDrawingHorizontalLine: (_) => FlLine(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        getDrawingVerticalLine: (_) => const FlLine(color: Colors.transparent),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  _formatLabel(value.toInt()),
                  style: TextStyle(
                    fontSize: 10,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: yAxisInterval,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatYAxisNumber(value),
                style: TextStyle(
                  fontSize: 10,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Expanded dialog ──────────────────────────────────────────────
  Widget _buildExpandedContent(BuildContext context) {
    double minY = 0;
    double maxY = widget.chartData.isNotEmpty
        ? widget.chartData
            .map((e) => (e['value'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b)
        : 0.0001;
    if (maxY == 0) maxY = 0.0001;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: FlutterFlowTheme.of(context).secondaryBackground, // Use standard secondary background instead of glaring dark blue
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2), // Subtle border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5), // Pure drop shadow, no glowing neon
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Energy Consumption',
                      style:
                          FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Poppins',
                                letterSpacing: 0.0,
                                fontSize: 24,
                                font: GoogleFonts.poppins(),
                              ),
                    ),
                    Text(
                      widget.period[0].toUpperCase() +
                          widget.period.substring(1),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Poppins',
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            font: GoogleFonts.poppins(),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                widget.chartData.isEmpty
                    ? const Center(child: Text("No valid data available"))
                    : SizedBox(
                        height: 500,
                        child: BarChart(_buildChartData(minY, maxY)),
                      ),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.close,
                  color: FlutterFlowTheme.of(context).primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    double minY = 0;
    double maxY = widget.chartData.isNotEmpty
        ? widget.chartData
            .map((e) => (e['value'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b)
        : 0.0001;
    if (maxY == 0) maxY = 0.0001;

    Widget cardContent;

    if (widget.isLoading) {
      cardContent = SizedBox(
        width: double.infinity,
        height: 380,
        child: CardWidget(
          armLenMultiplier: 0.20,
          topPadMultiplier: 0.3,
          bottomPadMultiplier: 0.0,
          glowColor: FlutterFlowTheme.of(context).primary,
          builder: (context, s) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  _buildHeader(),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      cardContent = SizedBox(
        width: double.infinity,
        height: 380,
        child: CardWidget(
          armLenMultiplier: 0.20,
          topPadMultiplier: 0.0,
          bottomPadMultiplier: 0.0,
          glowColor: FlutterFlowTheme.of(context).primary,
          builder: (context, s) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  Expanded(
                    child: widget.chartData.isEmpty
                        ? const Center(child: Text("No valid data available"))
                        : BarChart(_buildChartData(minY, maxY)),
                  ),
                  const SizedBox(height: 0),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      );
    }

    return MouseRegion(
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading
          ? null
          : () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildExpandedContent(context),
                  );
                },
              );
            },
      child: cardContent,
      ),
    );
  }
}
