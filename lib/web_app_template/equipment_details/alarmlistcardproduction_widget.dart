import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'alarmlistcardproduction_model.dart';
export 'alarmlistcardproduction_model.dart';

class AlarmlistcardproductionWidget extends StatefulWidget {
  final List<dynamic> alarmData;
  final bool isLoading;

  const AlarmlistcardproductionWidget({
    super.key,
    required this.alarmData,
    required this.isLoading,
  });

  @override
  State<AlarmlistcardproductionWidget> createState() =>
      _AlarmlistcardproductionWidgetState();
}

class _AlarmlistcardproductionWidgetState
    extends State<AlarmlistcardproductionWidget> {
  late AlarmlistcardproductionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AlarmlistcardproductionModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  List<dynamic> _getFilteredAlarmData() {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    return widget.alarmData.where((alarm) {
      try {
        final triggerDateStr = alarm["alarm_trigger_date_time"];
        if (triggerDateStr == null ||
            triggerDateStr == "-" ||
            triggerDateStr == "") {
          return false;
        }

        DateTime? triggerDate;
        try {
          triggerDate = DateTime.parse(
              triggerDateStr.toString().replaceAll(' ', 'T'));
        } catch (_) {
          try {
            triggerDate = DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse(triggerDateStr.toString());
          } catch (_) {
            try {
              triggerDate = DateFormat('MM/dd/yyyy HH:mm:ss')
                  .parse(triggerDateStr.toString());
            } catch (_) {
              try {
                triggerDate = DateFormat('dd-MM-yyyy HH:mm:ss')
                    .parse(triggerDateStr.toString());
              } catch (_) {
                return false;
              }
            }
          }
        }

        return triggerDate != null &&
            triggerDate.isAfter(twentyFourHoursAgo);
      } catch (e) {
        debugPrint('Error filtering alarm: $e');
        return false;
      }
    }).toList();
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null ||
        dateTimeStr == "-" ||
        dateTimeStr == "") {
      return "-";
    }
    try {
      final dateTime = DateTime.parse(
          dateTimeStr.toString().replaceAll(' ', 'T'));
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (_) {
      return dateTimeStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlarmData = _getFilteredAlarmData();

    filteredAlarmData.sort((a, b) {
      try {
        final aDate = DateTime.parse(
            a["alarm_trigger_date_time"].toString().replaceAll(' ', 'T'));
        final bDate = DateTime.parse(
            b["alarm_trigger_date_time"].toString().replaceAll(' ', 'T'));
        return bDate.compareTo(aDate);
      } catch (_) {
        return 0;
      }
    });

    // FIX 1: Replace SizedBox(height:410) with ConstrainedBox so the card
    // never clips content but also respects a sensible max height.
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 410,
      ),
      child: CardWidget(
        topPadMultiplier: 1.2,
        builder: (context, sizing) => widget.isLoading
            ? const Center(child: CircularProgressIndicator())
            // FIX 2: Column now stretches to fill the card width correctly.
            : Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Alarm List',
                        style: FlutterFlowTheme.of(context)
                            .headlineSmall
                            .override(
                              fontFamily: 'Poppins',
                              letterSpacing: 0.0,
                              font: GoogleFonts.poppins(),
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Last 24 hours',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Poppins',
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.0,
                                    font: GoogleFonts.poppins(),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // FIX 3: Table container uses Expanded so it fills remaining
                  // vertical space in the Column without overflowing.
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Fixed header row
                          Container(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.05),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                _headerCell(context, 'Trigger Time', flex: 2),
                                _headerCell(context, 'Description', flex: 3),
                                _headerCell(context, 'Resolve Time', flex: 2),
                                _headerCell(context, 'Duration', flex: 2),
                                _headerCell(context, 'PIC', flex: 1),
                              ],
                            ),
                          ),

                          const Divider(height: 1),

                          // FIX 4: Scrollable body is Expanded inside the Column,
                          // never unbounded — this was the root cause of RenderFlex
                          // overflow on the original code.
                          Expanded(
                            child: filteredAlarmData.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 48,
                                          color: FlutterFlowTheme.of(context).txtMuted,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No alarms in the last 24 hours',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Poppins',
                                                color: FlutterFlowTheme.of(context).txtMuted,
                                                letterSpacing: 0.0,
                                                font: GoogleFonts.poppins(),
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredAlarmData.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final alarm = filteredAlarmData[index];
                                      return Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            _dataCell(
                                              context,
                                              _formatDateTime(alarm[
                                                  "alarm_trigger_date_time"]),
                                              flex: 2,
                                            ),
                                            _dataCell(
                                              context,
                                              alarm["alarm_description_status"]
                                                      ?.toString() ??
                                                  "-",
                                              flex: 3,
                                            ),
                                            _dataCell(
                                              context,
                                              _formatDateTime(
                                                  alarm["alarm_resolve_date"]),
                                              flex: 2,
                                            ),
                                            _dataCell(
                                              context,
                                              alarm['spending_duration']
                                                      ?.toString() ??
                                                  "-",
                                              flex: 2,
                                            ),
                                            _dataCell(
                                              context,
                                              alarm['operator']?.toString() ??
                                                  "-",
                                              flex: 1,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // FIX 5: Extracted reusable header/data cell helpers so flex values are
  // defined once — previously the header and body flex values could drift apart.
  Widget _headerCell(BuildContext context, String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
              font: GoogleFonts.poppins(),
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _dataCell(BuildContext context, String value, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Poppins',
              letterSpacing: 0.0,
              font: GoogleFonts.poppins(),
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}