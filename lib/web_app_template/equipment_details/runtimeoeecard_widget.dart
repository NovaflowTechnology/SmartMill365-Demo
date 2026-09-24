import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/web_app_template/equipment_details/timerangefilter_dialog.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
export 'runtimeoeecard_model.dart';

class RuntimeoeecardWidget extends StatefulWidget {
  final int running;
  final int idle;
  final int stopped;
  final bool isLoading;
  final List<Map<String, dynamic>> utilizationData;
  final String? machineId;
  final String? workOrderId;
  final String? processID;

  const RuntimeoeecardWidget({
    super.key,
    this.running = 0,
    this.idle = 0,
    this.stopped = 0,
    this.isLoading = false,
    this.utilizationData = const [],
    this.machineId,
    this.workOrderId,
    this.processID,
  });

  @override
  State<RuntimeoeecardWidget> createState() => _RuntimeoeecardWidgetState();
}

class _RuntimeoeecardWidgetState extends State<RuntimeoeecardWidget> {
  final Color idleColor = const Color(0xFFFBBF24);
  final Color runningColor = const Color(0xFF22C55E);
  final Color stoppedColor = const Color(0xFFEF4444);
  final Color remainingColor = const Color(0xFF9CA3AF);

  int _displayRunning = 0;
  int _displayIdle = 0;
  int _displayStopped = 0;
  bool _isFiltered = false;
  String _filterInfo = '';
  List<Map<String, dynamic>> _filteredUtilizationData = [];

  @override
  void initState() {
    super.initState();
    _resetToOriginalValues();
  }

  @override
  void didUpdateWidget(RuntimeoeecardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running ||
        oldWidget.idle != widget.idle ||
        oldWidget.stopped != widget.stopped) {
      _resetToOriginalValues();
    }
  }

  void _resetToOriginalValues() {
    setState(() {
      _displayRunning = widget.running;
      _displayIdle = widget.idle;
      _displayStopped = widget.stopped;
      _isFiltered = false;
      _filterInfo = '';
      _filteredUtilizationData = [];
    });
  }

  void _showDetailedView() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return TimeRangeFilterDialog(
          utilizationData: widget.utilizationData,
          machineId: widget.machineId,
          workOrderId: widget.workOrderId,
          processID: widget.processID,
          initialRunning: widget.running,
          initialIdle: widget.idle,
          initialStopped: widget.stopped,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _displayRunning = result['running'] ?? widget.running;
        _displayIdle = result['idle'] ?? widget.idle;
        _displayStopped = result['stopped'] ?? widget.stopped;
        _isFiltered = result['isFiltered'] ?? false;
        _filterInfo = result['filterInfo'] ?? '';
        _filteredUtilizationData = result['filteredData'] ?? [];
      });
    }
  }

  // FIX A: Every path that builds a Row of Expanded children now wraps it in
  // SizedBox(height: 70) so the Row always has a bounded height constraint.
  // This prevents "RenderBox was not laid out" when CardWidget gives the
  // Column an unbounded height (e.g. inside a ListView or ScrollView).
  Widget buildSegmentedProgressBar() {
    final timelineData = _generateTimelineDataFromUtilization();

    // Guard: nothing to show → single grey bar, still inside a sized box.
    if (timelineData.isEmpty) {
      return _barContainer(
        child: SizedBox(
          height: 70,
          child: Container(
            decoration: BoxDecoration(color: remainingColor),
          ),
        ),
      );
    }

    final totalMinutes =
        timelineData.fold<int>(0, (sum, s) => sum + (s['minutes'] as int));

    if (totalMinutes <= 0) {
      return _barContainer(
        child: SizedBox(
          height: 70,
          child: Container(color: remainingColor),
        ),
      );
    }

    final segments =
        timelineData.where((s) => (s['minutes'] as int) > 0).map((segment) {
      final flex = (segment['minutes'] as int).clamp(1, 999999);
      return Expanded(
        flex: flex,
        child: Tooltip(
          message: segment['tooltip'] as String? ?? '',
          child: Container(
            // FIX: no explicit height here — SizedBox below controls it.
            decoration: BoxDecoration(
              color: segment['color'] as Color,
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
          ),
        ),
      );
    }).toList();

    return _barContainer(
      // FIX: SizedBox gives the Row a bounded vertical constraint so every
      // Container child is laid out before paint, preventing the assertion.
      child: SizedBox(
        height: 70,
        child: Row(children: segments),
      ),
    );
  }

  Widget _barContainer({required Widget child}) {
    return Builder(builder: (context) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlutterFlowTheme.of(context).cardStroke,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      );
    });
  }

  List<Map<String, dynamic>> _generateTimelineDataFromUtilization() {
    final dataToUse = _isFiltered && _filteredUtilizationData.isNotEmpty
        ? _filteredUtilizationData
        : widget.utilizationData;

    if (dataToUse.isEmpty) {
      return _generatePatternBasedTimelineData();
    }

    List<Map<String, dynamic>> segments = [];
    int currentMinutes = 0;
    int? currentStatus;

    for (var record in dataToUse) {
      final int recordStatus = record['runStatus'] as int;
      if (currentStatus == null) {
        currentStatus = recordStatus;
        currentMinutes = 1;
      } else if (currentStatus == recordStatus) {
        currentMinutes++;
      } else {
        segments.add(_createSegment(currentStatus, currentMinutes));
        currentStatus = recordStatus;
        currentMinutes = 1;
      }
    }
    if (currentStatus != null && currentMinutes > 0) {
      segments.add(_createSegment(currentStatus, currentMinutes));
    }
    return segments;
  }

  Map<String, dynamic> _createSegment(int status, int minutes) {
    Color color;
    String label;
    switch (status) {
      case 1:
        color = runningColor;
        label = 'Running';
        break;
      case 2:
        color = idleColor;
        label = 'Idle';
        break;
      case 3:
        color = stoppedColor;
        label = 'Stopped';
        break;
      default:
        color = remainingColor;
        label = 'Unknown';
    }
    return {
      'minutes': minutes,
      'color': color,
      'tooltip': '$label: $minutes minutes',
    };
  }

  List<Map<String, dynamic>> _generatePatternBasedTimelineData() {
    final int totalMinutes = _displayIdle + _displayRunning + _displayStopped;

    if (totalMinutes == 0) {
      return [
        {
          'minutes': 1440,
          'color': remainingColor,
          'tooltip': 'No activity data available',
        }
      ];
    }

    final List<Map<String, dynamic>> timeline = [];

    if (_displayRunning > 0) {
      timeline.add({
        'minutes': _displayRunning,
        'color': runningColor,
        'tooltip': 'Running: $_displayRunning minutes',
      });
    }
    if (_displayIdle > 0) {
      timeline.add({
        'minutes': _displayIdle,
        'color': idleColor,
        'tooltip': 'Idle: $_displayIdle minutes',
      });
    }
    if (_displayStopped > 0) {
      timeline.add({
        'minutes': _displayStopped,
        'color': stoppedColor,
        'tooltip': 'Stopped: $_displayStopped minutes',
      });
    }

    // Only show remaining gap for full 24h view.
    if (!_isFiltered && totalMinutes < 1440) {
      timeline.add({
        'minutes': 1440 - totalMinutes,
        'color': remainingColor,
        'tooltip': 'No data: ${1440 - totalMinutes} minutes',
      });
    }

    return timeline;
  }

  Widget buildTimelineLabels() {
    if (_isFiltered) return const SizedBox.shrink();

    final DateTime now = DateTime.now();
    final labels = List.generate(24, (i) {
      final t = now.subtract(Duration(hours: 23 - i));
      return t.hour.toString().padLeft(2, '0');
    });

    return LayoutBuilder(builder: (context, constraints) {
      final displayLabels =
          labels.asMap().entries.where((e) => e.key % 2 == 0).toList();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: displayLabels.map((e) {
          return Text(
            e.value,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: FlutterFlowTheme.of(context).secondaryText),
          );
        }).toList(),
      );
    });
  }

  Widget buildLegendItem(Color color, String label, int minutes) {
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;

    final int totalMinutes = _displayIdle + _displayRunning + _displayStopped;
    final double percentage =
        totalMinutes > 0 ? (minutes / totalMinutes) * 100 : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 15, color: FlutterFlowTheme.of(context).secondaryText),
        ),
        const SizedBox(width: 4.0),
        Text(
          '${hours}h ${mins}m (${percentage.toStringAsFixed(0)}%)',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: FlutterFlowTheme.of(context).txtPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildDataSourceInfo() {
    final String dataSource = _isFiltered && _filteredUtilizationData.isNotEmpty
        ? 'Data (${_filteredUtilizationData.length} records)'
        : widget.utilizationData.isNotEmpty
            ? 'Data (${widget.utilizationData.length} records)'
            : '';

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataSource,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_isFiltered && _filterInfo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.filter_alt,
                          size: 12,
                          color: FlutterFlowTheme.of(context).primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Filtered: $_filterInfo',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: FlutterFlowTheme.of(context).primary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: _resetToOriginalValues,
                        child: Icon(Icons.clear,
                            size: 14,
                            color: FlutterFlowTheme.of(context).primary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (widget.machineId != null && widget.workOrderId != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'WO ID: ${widget.workOrderId}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'OP ID: ${widget.processID}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showDetailedView,
      child: CardWidget(
        topPadMultiplier: 1.2,
        builder: (context, sizing) => Column(
          // FIX B: Changed from MainAxisSize.max to MainAxisSize.min.
          // MainAxisSize.max requires the Column to have bounded height.
          // When CardWidget wraps content without a fixed height (e.g. inside
          // a ListView or ScrollView), the Column height is unbounded and
          // Spacer() expands infinitely → RenderBox not laid out assertion.
          // MainAxisSize.min lets the Column size itself to its children
          // naturally without requiring bounded height from the parent.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isFiltered
                        ? 'Filtered Utilization Status'
                        : 'Last 24 Hours Utilization Status',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FlutterFlowTheme.of(context).txtPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.touch_app,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 8.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isFiltered ? 'Custom Range' : '24h Runtime',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: FlutterFlowTheme.of(context).txtPrimary),
                ),
                Flexible(
                  child: Text(
                    widget.machineId != null
                        ? 'Machine Name : ${widget.machineId}'
                        : 'Today',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: FlutterFlowTheme.of(context).secondaryText),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            buildSegmentedProgressBar(),

            const SizedBox(height: 8.0),

            buildTimelineLabels(),

            SizedBox(height: _isFiltered ? 8.0 : 20.0),

            Wrap(
              spacing: 16.0,
              runSpacing: 10.0,
              children: [
                buildLegendItem(idleColor, 'Idle', _displayIdle),
                buildLegendItem(runningColor, 'Running', _displayRunning),
                buildLegendItem(stoppedColor, 'Stopped', _displayStopped),
              ],
            ),

            const SizedBox(height: 12),

            buildDataSourceInfo(),
          ],
        ),
      ),
    );
  }
}
