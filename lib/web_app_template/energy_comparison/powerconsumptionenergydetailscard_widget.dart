import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'powerconsumptionenergydetailscard_model.dart';
export 'powerconsumptionenergydetailscard_model.dart';

class PowerconsumptionenergydetailscardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;
  final bool isLoading;
  final String period;
  final String title;

  /// Optional control rendered at the top-right of the card header, before
  /// the period badge — used by the Hourly/Daily charts' date/month filters.
  final Widget? headerAction;

  const PowerconsumptionenergydetailscardWidget({
    super.key,
    required this.chartData,
    required this.isLoading,
    required this.period,
    required this.title,
    this.headerAction,
  });

  @override
  State<PowerconsumptionenergydetailscardWidget> createState() =>
      PowerconsumptionenergydetailscardWidgetState();
}

class PowerconsumptionenergydetailscardWidgetState
    extends State<PowerconsumptionenergydetailscardWidget> {
  late PowerconsumptionenergydetailscardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(
        context, () => PowerconsumptionenergydetailscardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  String _formatNumberWithCommas(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (widget.period == 'Hourly') {
      return value.toStringAsFixed(2);
    } else {
      final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return value
          .toStringAsFixed(0)
          .replaceAllMapped(formatter, (m) => '${m[1]},');
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
    if (index < 0 || index >= widget.chartData.length) return '';
    final rawLabel = widget.chartData[index]['label'].toString();
    if (widget.period == 'Hourly') {
      // Backend returns bare hour digits ("0".."23") for the hourly bucket —
      // show them as "HH:00" so the axis reads like a time, not an index.
      final hour = int.tryParse(rawLabel);
      if (hour != null) return '${hour.toString().padLeft(2, '0')}:00';
    }
    return rawLabel;
  }

  List<BarChartGroupData> _buildBarGroups() {
    if (widget.chartData.isEmpty) {
      return List.generate(
        5,
        (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: Colors.transparent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }
    return widget.chartData.asMap().entries.map((entry) {
      final dataPoint = entry.value;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: (dataPoint['value'] is num)
                ? (dataPoint['value'] as num).toDouble()
                : 0.0,
            color: Colors.lightBlueAccent,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // Chart body (reused in card + expanded dialog)
  // ─────────────────────────────────────────────

  Widget _buildChartWidget(
      BuildContext context, double minY, double maxY, double yAxisInterval,
      {double fontSize = 11}) {
    final theme = FlutterFlowTheme.of(context);
    return Stack(
      children: [
        Positioned(
          top: 100,
          left: 0,
          child: Text(
            'kWh',
            style: GoogleFonts.poppins(color: theme.secondaryText, fontSize: fontSize),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: minY,
              maxY: maxY,
              barGroups: _buildBarGroups(),
              gridData: FlGridData(
                  show: true, horizontalInterval: yAxisInterval),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: theme.alternate, width: 1),
                  bottom: BorderSide(color: theme.alternate, width: 1),
                  top: const BorderSide(color: Colors.transparent),
                  right: const BorderSide(color: Colors.transparent),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          _formatLabel(value.toInt()),
                          style: TextStyle(fontSize: fontSize),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: yAxisInterval,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatNumberWithCommas(value),
                        style: TextStyle(fontSize: fontSize),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.chartData.isEmpty)
          Center(
            child: Text(
              'No data available',
              style: GoogleFonts.poppins(
                  color: FlutterFlowTheme.of(context).secondaryText, fontSize: fontSize + 2),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Expanded pop-up dialog
  // ─────────────────────────────────────────────

  Widget _buildExpandedContent(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    double maxY = widget.chartData.isEmpty
        ? 10
        : widget.chartData
            .map((e) => (e['value'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 10;
    final yAxisInterval = _calculateYAxisInterval(maxY);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color.fromRGBO(0, 4, 51, 1),
        border: Border.all(color: theme.primary, width: 1),
      ),
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                top: 48, left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText),
                    ),
                    Text(
                      widget.period,
                      style: GoogleFonts.poppins(
                          color: theme.primaryText, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 500,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 250,
                        left: 0,
                        child: Text('kWh',
                            style: GoogleFonts.poppins(
                                color: theme.secondaryText, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            minY: 0,
                            maxY: maxY,
                            barGroups: _buildBarGroups(),
                            gridData: FlGridData(
                                show: true,
                                horizontalInterval: yAxisInterval),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                left:
                                    BorderSide(color: theme.alternate, width: 1),
                                bottom:
                                    BorderSide(color: theme.alternate, width: 1),
                                top: const BorderSide(color: Colors.transparent),
                                right: const BorderSide(color: Colors.transparent),
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 12.0),
                                      child: Text(_formatLabel(value.toInt()),
                                          style: const TextStyle(
                                              fontSize: 12)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  interval: yAxisInterval,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                        _formatNumberWithCommas(value),
                                        style: const TextStyle(fontSize: 11));
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.chartData.isEmpty)
                        Center(
                          child: Text('No data available',
                              style: GoogleFonts.poppins(
                                  color: theme.secondaryText, fontSize: 16)),
                        ),
                    ],
                  ),
                ),
              ].divide(const SizedBox(height: 12)),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.close, color: theme.primaryText),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => _buildContent(context, sizing),
    );
  }

  Widget _buildContent(BuildContext context, CardSizing sizing) {
    final theme = FlutterFlowTheme.of(context);
    final titleFs = sizing.titleFs.clamp(12.0, 18.0);
    final bodyFs  = sizing.bodyFs.clamp(9.0, 12.0);

    return GestureDetector(
      onTap: widget.isLoading
          ? null
          : () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: _buildExpandedContent(context),
                ),
              ),
      child: LayoutBuilder(builder: (context, constraints) {
        final heightBounded = constraints.maxHeight.isFinite;
        const double fallbackHeight = 320.0;

        double maxY = widget.chartData.isEmpty
            ? 10
            : widget.chartData
                .map((e) => (e['value'] as num).toDouble())
                .reduce((a, b) => a > b ? a : b);
        if (maxY == 0) maxY = 10;
        final yAxisInterval = _calculateYAxisInterval(maxY);

        // ── Header ──────────────────────────────
        final header = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Accent bar
                  Container(
                    width: sizing.accentW,
                    height: titleFs * 1.2,
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
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: titleFs,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                          letterSpacing: 0.6,
                          shadows: [
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
            if (widget.headerAction != null) ...[
              widget.headerAction!,
              const SizedBox(width: 8),
            ],
            // Period badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: theme.primary.withOpacity(0.4), width: 1),
              ),
              child: Text(
                widget.period,
                style: GoogleFonts.poppins(
                    fontSize: bodyFs,
                    color: theme.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );

        // ── Chart body ──────────────────────────
        Widget chartBody = widget.isLoading
            ? Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.primary)))
            : _buildChartWidget(context, 0, maxY, yAxisInterval,
                fontSize: bodyFs);

        return Column(
          mainAxisSize:
              heightBounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            SizedBox(height: sizing.pad),
            heightBounded
                ? Expanded(child: chartBody)
                : SizedBox(height: fallbackHeight, child: chartBody),
          ],
        );
      }),
    );
  }
}