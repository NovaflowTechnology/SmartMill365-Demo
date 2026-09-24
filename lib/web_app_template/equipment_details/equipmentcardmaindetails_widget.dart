import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartmachine365/components/card_widget/card_widget.dart';
import 'package:smartmachine365/web_app_template/equipment_details/multisegmentcircualpainter_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:percent_indicator/percent_indicator.dart';

class EquipmentcardmaindetailsWidget extends StatefulWidget {
  final Map<String, Map<String, dynamic>> equipmentData;
  final String productionAreaName;
  final bool isLoading;
  final int progress;
  final int quantity;
  final String unit;
  final String selectedWorkID;
  final String selectedEquipmentId;
  final String equipmentName;
  final String equipmentStatus;

  final double availability;
  final double performance;
  final double quality;
  final double oee;
  final bool isLoadingOEE;
  final int jobOrderGrossQuantity;
  final jobOrderExpectedQuantity;
  final runStatus;
  final processID;
  final jobOrderID;
  final List<dynamic>? equipmentFromFirestore;
  final Map<String, dynamic>? equipmentPerformanceData;

  const EquipmentcardmaindetailsWidget({
    Key? key,
    required this.equipmentData,
    required this.productionAreaName,
    required this.isLoading,
    required this.progress,
    required this.quantity,
    required this.unit,
    required this.selectedWorkID,
    required this.selectedEquipmentId,
    required this.equipmentName,
    required this.equipmentStatus,
    required this.availability,
    required this.performance,
    required this.quality,
    required this.oee,
    required this.isLoadingOEE,
    required this.jobOrderGrossQuantity,
    required this.jobOrderExpectedQuantity,
    required this.runStatus,
    required this.processID,
    required this.jobOrderID,
    this.equipmentPerformanceData,
    this.equipmentFromFirestore,
  }) : super(key: key);

  @override
  _EquipmentcardmaindetailsWidgetState createState() =>
      _EquipmentcardmaindetailsWidgetState();
}

class _EquipmentcardmaindetailsWidgetState
    extends State<EquipmentcardmaindetailsWidget> {
  String status = 'No Data';
  int progress = 0;
  int quantity = 0;
  String unit = 'units';
  String selectedWorkID = 'N/A';
  String? equipmentImageUrl;
  String? workOrderId;

  @override
  void initState() {
    super.initState();
    updateData();
  }

  @override
  void didUpdateWidget(covariant EquipmentcardmaindetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEquipmentId != widget.selectedEquipmentId ||
        oldWidget.equipmentData != widget.equipmentData ||
        oldWidget.progress != widget.progress ||
        oldWidget.quantity != widget.quantity ||
        oldWidget.unit != widget.unit ||
        oldWidget.selectedWorkID != widget.selectedWorkID ||
        oldWidget.availability != widget.availability ||
        oldWidget.performance != widget.performance ||
        oldWidget.quality != widget.quality ||
        oldWidget.oee != widget.oee) {
      updateData();
    }
  }

  void updateData() {
    final parent = widget.productionAreaName.toLowerCase();
    final equipmentData =
        widget.equipmentData[parent]?[widget.selectedEquipmentId];

    setState(() {
      status = _getStatus(widget.runStatus);
      progress = widget.jobOrderGrossQuantity;
      quantity = widget.jobOrderExpectedQuantity;
      unit = equipmentData?['status']?['unit'] ?? widget.unit;
      selectedWorkID = widget.jobOrderID ?? 'N/A';

      final firestoreData = _getDataFromFirestore();
      equipmentImageUrl = firestoreData['imageUrl'];
      workOrderId = firestoreData['workOrderId'];
    });
  }

  Map<String, String?> _getDataFromFirestore() {
    if (widget.equipmentFromFirestore == null ||
        widget.equipmentFromFirestore!.isEmpty) {
      return {'imageUrl': null, 'workOrderId': null};
    }
    try {
      final targetName = widget.equipmentName.trim();
      dynamic matchedEquipment;
      for (var equipment in widget.equipmentFromFirestore!) {
        if (equipment is Map<String, dynamic>) {
          final name = equipment['name']?.toString().trim() ?? '';
          if (name == targetName) {
            matchedEquipment = equipment;
            break;
          }
        }
      }
      if (matchedEquipment != null &&
          matchedEquipment is Map<String, dynamic>) {
        return {
          'imageUrl': matchedEquipment['imageUrl']?.toString(),
          'workOrderId': matchedEquipment['work_id']?.toString(),
        };
      }
    } catch (e) {
      debugPrint('Error getting data from Firestore: $e');
    }
    return {'imageUrl': null, 'workOrderId': null};
  }

  String _getStatus(String? statusData) {
    switch (statusData?.toString()) {
      case '1':
        return 'Running';
      case '2':
        return 'Idle';
      case '3':
        return 'Stopped';
      default:
        return 'No Data';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return const Color(0xFF07F077);
      case 'idle':
        return const Color.fromARGB(255, 252, 248, 11);
      case 'stopped':
        return const Color.fromARGB(255, 255, 17, 0);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  Color _getMetricColor(String metric) {
    switch (metric.toLowerCase()) {
      case 'availability':
        return const Color(0xFF40CC97);
      case 'performance':
        return const Color(0xFFF13245);
      case 'quality':
        return const Color(0xFFD5CE07);
      case 'oee':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  Widget _buildMultiSegmentCircularIndicator() {
    return Builder(builder: (context) {
      final isLight = Theme.of(context).brightness == Brightness.light;
      final theme = FlutterFlowTheme.of(context);
      return Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 120),
            painter: MultiSegmentCircularPainter(
              availability: widget.availability,
              performance: widget.performance,
              quality: widget.quality,
              availabilityColor: _getMetricColor('availability'),
              performanceColor: _getMetricColor('performance'),
              qualityColor: _getMetricColor('quality'),
              backgroundColor: isLight ? theme.alternate : const Color(0xFF2A2A4A),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.oee > 0
                    ? '${(widget.oee * 100).toStringAsFixed(0)}%'
                    : '0%',
                style: TextStyle(
                  color: isLight ? theme.txtPrimary : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'OEE',
                style: TextStyle(
                  color: isLight ? theme.warning : Colors.yellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildLinearIndicator(
      String label, double percent, TextStyle textStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getMetricColor(label),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label.toUpperCase(),
            style: textStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: LinearPercentIndicator(
                percent: percent.clamp(0.0, 1.0),
                lineHeight: 10,
                animation: true,
                animateFromLastPercent: true,
                progressColor: _getMetricColor(label),
                backgroundColor: FlutterFlowTheme.of(context).accent4,
                padding: EdgeInsets.zero,
                barRadius: const Radius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                percent > 0
                    ? '${(percent * 100).toStringAsFixed(0)}%'
                    : '0%',
                textAlign: TextAlign.right,
                style: textStyle.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipmentImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (equipmentImageUrl != null && equipmentImageUrl!.isNotEmpty)
          ? Image.network(
              equipmentImageUrl!,
              width: double.infinity,
              height: 140,
              fit: BoxFit.fill,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 140,
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/equipment.png',
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.error)),
                );
              },
            )
          : Image.asset(
              'assets/images/equipment.png',
              width: double.infinity,
              height: 140,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.error)),
            ),
    );
  }

  double _safeWoPercent() {
    if (quantity <= 0) return 0.0;
    return (progress / quantity).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final todayActual =
        widget.equipmentPerformanceData?[widget.equipmentName]
            ?['Machine_Actual_Quantity'];
    final todayPlanned =
        widget.equipmentPerformanceData?[widget.equipmentName]
            ?['Planned_Production_Qty'];

    final textStyle = FlutterFlowTheme.of(context).bodyMedium.override(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          font: GoogleFonts.poppins(),
        );
    final statusColor = _getStatusColor(status);

    return CardWidget(
      topPadMultiplier: 1.2,
      builder: (context, sizing) => widget.isLoading || widget.isLoadingOEE
          ? const SizedBox(
              height: 365,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              // FIX D: Use MainAxisSize.min so the Column intrinsically sizes
              // to its children. This is safe whether CardWidget provides
              // bounded or unbounded height, and eliminates the need for any
              // Spacer() inside this column.
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row — equipment name, "Equipment Daily", status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.equipmentName,
                        style: textStyle.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Equipment Daily',
                        style: textStyle.copyWith(
                          fontSize: 18,
                          color: isLight ? FlutterFlowTheme.of(context).txtSecondary : Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 150,
                      height: 28,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.3),
                        border: Border.all(color: statusColor, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(
                            fontSize: 16,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Image + OEE + linear indicators row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildEquipmentImage(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: _buildMultiSegmentCircularIndicator(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLinearIndicator(
                              'Availability', widget.availability, textStyle),
                          const SizedBox(height: 6),
                          _buildLinearIndicator(
                              'Performance', widget.performance, textStyle),
                          const SizedBox(height: 6),
                          _buildLinearIndicator(
                              'Quality', widget.quality, textStyle),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Info rows
                _infoRow(context, 'Equipment Process:',
                    workOrderId ?? 'N/A', textStyle),
                _infoRow(context, 'Process ID:',
                    widget.processID.toString(), textStyle),
                _infoRow(context, 'Work Order:', selectedWorkID, textStyle),

                const SizedBox(height: 6),

                // Today output
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today Output Progress:',
                        style: textStyle.copyWith(fontSize: 15)),
                    Text(
                      todayActual?.toString() ?? 'N/A',
                      style: textStyle.copyWith(
                        fontSize: 15,
                        color: isLight ? FlutterFlowTheme.of(context).txtPrimary : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // WO progress bar
                // FIX E: Wrap the LinearPercentIndicator row in a SizedBox
                // with explicit height. LinearPercentIndicator requires a
                // bounded height from its parent; without it the widget can
                // also trigger "RenderBox not laid out" in unbounded Columns.
                SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('WO Progress:',
                          style: textStyle.copyWith(fontSize: 15)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              8, 0, 0, 0),
                          child: LinearPercentIndicator(
                            percent: _safeWoPercent(),
                            lineHeight: 18,
                            animation: true,
                            animateFromLastPercent: true,
                            progressColor:
                                const Color.fromARGB(255, 11, 200, 14),
                            backgroundColor:
                                FlutterFlowTheme.of(context).accent4,
                            center: Text(
                              quantity > 0
                                  ? '$progress / $quantity $unit'
                                  : '0%',
                              style: textStyle.copyWith(
                                color: FlutterFlowTheme.of(context).txtOnAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      TextStyle textStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle.copyWith(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textStyle.copyWith(fontSize: 15),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}