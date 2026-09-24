import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'workordercard_model.dart';
export 'workordercard_model.dart';

class WorkordercardWidget extends StatefulWidget {
  final String workOrderName;
  final String productionArea;
  final String productName;
  final String processID;
  final String date;
  final int progress;
  final int quantity;
  final String unit;
  final String name;
  final int status;
  final bool show;
  final bool isLoading;

  final String plannedStartTime;
  final String checkInTime;
  final String targetCompletionTime;
  final String estimatedCompletionTime;
  final int remainingHours;
  final double estimatedDelay;
  final bool isLateStart;
  final bool isOverdue;
  final String woPlannedCycleTime;
  final String woActualCycleTime;

  const WorkordercardWidget({
    super.key,
    required this.workOrderName,
    required this.productionArea,
    required this.productName,
    required this.processID,
    required this.date,
    required this.progress,
    required this.quantity,
    required this.unit,
    required this.name,
    required this.show,
    required this.status,
    required this.isLoading,
    this.plannedStartTime = '',
    this.checkInTime = '',
    this.targetCompletionTime = '',
    this.estimatedCompletionTime = '',
    this.remainingHours = 0,
    this.estimatedDelay = 0.0,
    this.isLateStart = false,
    this.isOverdue = false,
    this.woPlannedCycleTime = '',
    this.woActualCycleTime = '',
  });

  @override
  State<WorkordercardWidget> createState() => _WorkordercardWidgetState();
}

class _WorkordercardWidgetState extends State<WorkordercardWidget> {
  late WorkordercardModel _model;
  String status = '';
  Color color = const Color(0xFFBDBDBD);

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WorkordercardModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return '----/--/-- --:--';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _calculateLateStartDuration() {
    if (!widget.isLateStart ||
        widget.plannedStartTime.isEmpty ||
        widget.checkInTime.isEmpty) {
      return '00:00';
    }
    try {
      final planned = DateTime.parse(widget.plannedStartTime);
      final checkIn = DateTime.parse(widget.checkInTime);
      final difference = checkIn.difference(planned);
      if (difference.isNegative) return '00:00';
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return '00:00';
    }
  }

  Color _getCycleTimeColor(BuildContext context) {
    if (!widget.show ||
        widget.woPlannedCycleTime.isEmpty ||
        widget.woActualCycleTime.isEmpty) {
      return FlutterFlowTheme.of(context).txtPrimary;
    }
    try {
      final planned = double.tryParse(widget.woPlannedCycleTime) ?? 0.0;
      final actual = double.tryParse(widget.woActualCycleTime) ?? 0.0;
      if (actual > planned) return Colors.red;
      if (actual < planned) return Colors.green;
      return FlutterFlowTheme.of(context).txtPrimary;
    } catch (e) {
      return FlutterFlowTheme.of(context).txtPrimary;
    }
  }

  double _convertSecondsToHours(int seconds) => seconds / 3600.0;

  double _calculateEstimatedDelay() {
    if (widget.estimatedCompletionTime.isEmpty ||
        widget.targetCompletionTime.isEmpty) {
      return 0.0;
    }
    try {
      final estimated = DateTime.parse(widget.estimatedCompletionTime);
      final target = DateTime.parse(widget.targetCompletionTime);
      final difference = estimated.difference(target);
      return difference.isNegative ? 0.0 : difference.inMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  // FIX: Safe progress percent — guards against quantity == 0 divide-by-zero.
  double _safeProgressPercent() {
    if (!widget.show || widget.quantity <= 0) return 0.0;
    return (widget.progress / widget.quantity).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == 0) {
      status = 'In Progress';
      color = const Color(0xFF07F077);
    } else if (widget.status == 1) {
      status = 'Idle';
      color = const Color.fromARGB(255, 252, 248, 11);
    } else if (widget.status == 2) {
      status = 'Stopped';
      color = Colors.red;
    }

    final remainingHoursValue = _convertSecondsToHours(widget.remainingHours);
    final calculatedEstimatedDelay = _calculateEstimatedDelay();

    if (widget.isLoading) {
      return CardWidget(
        topPadMultiplier: 1.2,
        builder: (context, sizing) => const SizedBox(
          height: 410,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return CardWidget(
      topPadMultiplier: 1.2,
      // FIX 1: Card body is ConstrainedBox instead of bare SizedBox so it
      // can shrink below 410 on small screens.
      builder: (context, sizing) => ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 0,
          maxHeight: 410,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header — WO name + on-time badge
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Current Running WO : ',
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).txtPrimary,
                                letterSpacing: 0.0,
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                        TextSpan(
                          text: widget.show
                              ? widget.workOrderName
                              : 'WO-XXXXXXXX-XXXX',
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                fontFamily: 'Poppins',
                                color: FlutterFlowTheme.of(context).txtPrimary,
                                letterSpacing: 0.0,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                font: GoogleFonts.poppins(),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                // FIX 2: Badge wrapped in Column with crossAxisAlignment.end
                // so it doesn't push siblings when hidden.
                if (widget.show &&
                    widget.estimatedCompletionTime.isNotEmpty &&
                    widget.targetCompletionTime.isNotEmpty)
                  Builder(builder: (context) {
                    final isOverdue = calculatedEstimatedDelay > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOverdue ? 'OVERDUE' : 'ON-TIME',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              font: GoogleFonts.poppins(),
                            ),
                      ),
                    );
                  }),
              ],
            ),

            const SizedBox(height: 4),

            // Process ID
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Process ID : ',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Poppins',
                          color: FlutterFlowTheme.of(context).txtPrimary,
                          letterSpacing: 0.0,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          font: GoogleFonts.poppins(),
                        ),
                  ),
                  TextSpan(
                    text: widget.show ? widget.processID : 'N/A',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Poppins',
                          color: FlutterFlowTheme.of(context).txtPrimary,
                          letterSpacing: 0.0,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          font: GoogleFonts.poppins(),
                        ),
                  ),
                ],
              ),
            ),

            // Equipment name
            Text(
              widget.show ? widget.name : 'Equipment Name',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Poppins',
                    color: FlutterFlowTheme.of(context).primary,
                    fontSize: 12,
                    letterSpacing: 0.0,
                    font: GoogleFonts.poppins(),
                  ),
              overflow: TextOverflow.ellipsis,
            ),

            Divider(
              thickness: 1.0,
              color: FlutterFlowTheme.of(context).primary,
            ),

            // Product + WO Quantity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Poppins',
                              color: FlutterFlowTheme.of(context).primary,
                              fontSize: 11,
                              letterSpacing: 0.0,
                              font: GoogleFonts.poppins(),
                            ),
                      ),
                      Text(
                        widget.show ? widget.productName : 'Product Name',
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              letterSpacing: 0.0,
                              font: GoogleFonts.poppins(),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Work order Quantity',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            letterSpacing: 0.0,
                            font: GoogleFonts.poppins(),
                          ),
                    ),
                    Text(
                      widget.show
                          ? '${widget.quantity} ${widget.unit}'
                          : '0 pcs',
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            letterSpacing: 0.0,
                            font: GoogleFonts.poppins(),
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Cycle Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Cycle Time',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Poppins',
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 11,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                Text(
                  widget.show && widget.woActualCycleTime.isNotEmpty
                      ? '${widget.woActualCycleTime} sec'
                      : 'N/A',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        color: _getCycleTimeColor(context),
                        font: GoogleFonts.poppins(),
                      ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // FIX 3: Timeline section — the 3-column row now uses
            // IntrinsicHeight so all columns match height, and the right
            // column's two sub-rows are wrapped in Expanded to prevent
            // overflow when text is long.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left column
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _timelineLabel(
                            context,
                            'Planned start time:',
                            widget.show
                                ? _formatDateTime(widget.plannedStartTime)
                                : '----/--/-- --:--'),
                        const SizedBox(height: 6),
                        _timelineLabel(
                            context,
                            'Check In Time',
                            widget.show
                                ? _formatDateTime(widget.checkInTime)
                                : '----/--/-- --:--'),
                      ],
                    ),
                  ),

                  // Middle column — late start badge
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.show && widget.isLateStart
                                ? Colors.orange
                                : Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.show
                                ? (widget.isLateStart
                                    ? 'Late start'
                                    : 'On time')
                                : 'Unknown',
                            textAlign: TextAlign.center,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 9,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      font: GoogleFonts.poppins(),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.show ? _calculateLateStartDuration() : '00:00',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    color: widget.show && widget.isLateStart
                                        ? Colors.orange
                                        : Colors.green,
                                    fontSize: 11,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    font: GoogleFonts.poppins(),
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Right column — FIX: two sub-rows each wrapped in Expanded
                  // so neither overflows at narrow widths.
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _timelineLabel(
                                context,
                                'Target Completion:',
                                widget.show
                                    ? _formatDateTime(
                                        widget.targetCompletionTime)
                                    : '----/--/-- --:--',
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Remaining Hr',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Poppins',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontSize: 10,
                                        letterSpacing: 0.0,
                                        font: GoogleFonts.poppins(),
                                      ),
                                ),
                                Text(
                                  widget.show
                                      ? '${remainingHoursValue.toStringAsFixed(1)}h'
                                      : '0.0h',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Poppins',
                                        color: remainingHoursValue <= 1.0
                                            ? Colors.red
                                            : FlutterFlowTheme.of(context)
                                                .primary,
                                        fontSize: 11,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        font: GoogleFonts.poppins(),
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _timelineLabel(
                                context,
                                'Estimated Completion',
                                widget.show
                                    ? _formatDateTime(
                                        widget.estimatedCompletionTime)
                                    : '----/--/-- --:--',
                                labelColor:
                                    FlutterFlowTheme.of(context).primary,
                                valueColor:
                                    FlutterFlowTheme.of(context).primary,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'EST. Delay',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Poppins',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        fontSize: 10,
                                        letterSpacing: 0.0,
                                        font: GoogleFonts.poppins(),
                                      ),
                                ),
                                Text(
                                  widget.show
                                      ? '${calculatedEstimatedDelay.toStringAsFixed(1)}h'
                                      : '0.0h',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Poppins',
                                        color: calculatedEstimatedDelay > 0
                                            ? Colors.red
                                            : FlutterFlowTheme.of(context)
                                                .primary,
                                        fontSize: 11,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        font: GoogleFonts.poppins(),
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Divider(
              thickness: 1.0,
              color: FlutterFlowTheme.of(context).primary,
            ),

            // Progress section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        letterSpacing: 0.0,
                        font: GoogleFonts.poppins(),
                      ),
                ),
                Text(
                  widget.show && widget.quantity > 0
                      ? '${(widget.progress / widget.quantity * 100).toStringAsFixed(0)}%'
                      : '0%',
                  style: FlutterFlowTheme.of(context).headlineLarge.override(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        font: GoogleFonts.poppins(),
                      ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // FIX 4: Progress bar uses _safeProgressPercent() to avoid
            // divide-by-zero when quantity is 0.
            LinearPercentIndicator(
              percent: _safeProgressPercent(),
              lineHeight: 22.0,
              animation: true,
              animateFromLastPercent: true,
              progressColor: calculatedEstimatedDelay > 0
                  ? Colors.red
                  : const Color(0xFF07F077),
              backgroundColor: const Color(0xFFF00707).withOpacity(0.3),
              barRadius: const Radius.circular(10.0),
              padding: EdgeInsets.zero,
              center: Text(
                widget.show
                    ? '${widget.progress} / ${widget.quantity}'
                    : '0 / 0',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      font: GoogleFonts.poppins(),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for aligned label+value pairs in the timeline section.
  Widget _timelineLabel(
    BuildContext context,
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Poppins',
                color: labelColor ?? FlutterFlowTheme.of(context).txtPrimary,
                fontSize: 10,
                letterSpacing: 0.0,
                font: GoogleFonts.poppins(),
              ),
        ),
        Text(
          value,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Poppins',
                color: valueColor,
                fontSize: 11,
                letterSpacing: 0.0,
                font: GoogleFonts.poppins(),
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
