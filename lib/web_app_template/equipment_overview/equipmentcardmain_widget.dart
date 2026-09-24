import 'package:flutter/material.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../flutter_flow/helper/parse_double_value.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/card_widget/card_widget.dart';
export 'equipmentcardmain_model.dart';

class EquipmentcardmainWidget extends StatefulWidget {
  final String parent;
  final Map<String, dynamic> equipmentList;
  final Map<String, dynamic>? equipmentData;
  final String productionAreaName;
  final bool isLoading;
  final String selectedProductionAreaName;
  final List<dynamic>? equipmentFromFirestore;

  const EquipmentcardmainWidget({
    super.key,
    required this.parent,
    required this.equipmentList,
    required this.equipmentData,
    required this.productionAreaName,
    required this.isLoading,
    required this.selectedProductionAreaName,
    this.equipmentFromFirestore,
  });

  @override
  EquipmentcardmainWidgetState createState() => EquipmentcardmainWidgetState();
}

class EquipmentcardmainWidgetState extends State<EquipmentcardmainWidget> {
  String status = 'Unknown';
  int? progress;
  int? quantity;
  int? todayActualQty;
  int? todayPlannedQty;
  String unit = 'units';
  String? selectedWorkID;
  double? oee;
  String equipmentProcess = '1';
  String? processID;
  String? equipmentImageUrl;

  @override
  void initState() {
    super.initState();
    updateData();
  }

  void updateData() {
    if (widget.equipmentList.isEmpty || widget.equipmentList.keys.isEmpty) {
      setState(() {
        status = 'Unknown';
        progress = 0;
        quantity = 0;
        todayActualQty = 0;
        todayPlannedQty = 0;
        selectedWorkID = 'N/A';
        oee = 0.0;
        unit = 'units';
        equipmentProcess = '1';
        equipmentImageUrl = null;
      });
      return;
    }

    final equipment = widget.equipmentList.values.first;
    final equipmentId = widget.equipmentList.keys.first;
    final equipmentName = equipment['name']?.toString().trim() ?? '';

    selectedWorkID = equipment['JobOrderID'] ?? 'N/A';
    processID = equipment['processID']?.toString() ?? '0/0';
    unit = equipment['unit']?.toString() ?? 'units';

    final workIdFromFirestore = _getWorkIdFromFirestore(equipmentName);
    equipmentProcess =
        workIdFromFirestore ?? equipment['work_id']?.toString() ?? 'N/A';

    equipmentImageUrl = _getImageUrlFromFirestore(equipmentName);

    if (widget.equipmentData != null &&
        widget.equipmentData!.containsKey(equipmentId)) {
      final childData = widget.equipmentData![equipmentId];
      if (childData != null) {
        if (childData['machine_status'] != null) {
          final statusCode = int.tryParse(equipment['RunStatus'].toString());
          switch (statusCode) {
            case 1:
              status = 'Running';
              break;
            case 2:
              status = 'Idle';
              break;
            case 3:
              status = 'Stopped';
              break;
            default:
              status = 'Unknown';
          }
        }

        progress = int.tryParse(
                equipment['JobOrder_GrossQuantity']?.toString() ?? '0') ??
            0;
        quantity = int.tryParse(
                equipment['JobOrder_ExpectedQuantity']?.toString() ?? '0') ??
            0;
        todayActualQty = int.tryParse(
                equipment['Machine_Actual_Quantity']?.toString() ?? '0') ??
            0;
        todayPlannedQty = int.tryParse(
                equipment['Planned_Production_Qty']?.toString() ?? '0') ??
            0;

        final overallOEE = equipment['Overall_Machine_OEE'];
        if (overallOEE != null && overallOEE > 0) {
          oee = ParseDoubleValue.parseDoubleValue(overallOEE) / 100.0;
        } else {
          oee = double.tryParse(childData['oee']?.toString() ?? '');
        }
      }
    }

    setState(() {
      progress ??= 0;
      quantity ??= 0;
      todayActualQty ??= 0;
      todayPlannedQty ??= 0;
      oee ??= 0.0;
      if (oee! > 1.0) oee = 1.0;
      if (oee! < 0.0) oee = 0.0;
    });
  }

  String? _getWorkIdFromFirestore(String equipmentName) {
    if (widget.equipmentFromFirestore == null ||
        widget.equipmentFromFirestore!.isEmpty) return null;
    try {
      final targetName = equipmentName.trim();
      for (var equipment in widget.equipmentFromFirestore!) {
        if (equipment is Map<String, dynamic>) {
          final firestoreName = equipment['name']?.toString().trim() ?? '';
          if (firestoreName == targetName) {
            final workId = equipment['work_id']?.toString();
            if (workId != null && workId.isNotEmpty) return workId;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String? _getImageUrlFromFirestore(String equipmentName) {
    if (widget.equipmentFromFirestore == null ||
        widget.equipmentFromFirestore!.isEmpty) return null;
    try {
      final targetName = equipmentName.trim();
      for (var equipment in widget.equipmentFromFirestore!) {
        if (equipment is Map<String, dynamic>) {
          final firestoreName = equipment['name']?.toString().trim() ?? '';
          if (firestoreName == targetName) {
            final imageUrl = equipment['imageUrl']?.toString();
            if (imageUrl != null && imageUrl.isNotEmpty) return imageUrl;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return const Color(0xFF00FF6A);
      case 'stopped':
        return const Color(0xFFFF1515);
      case 'idle':
        return const Color(0xFFFBBC05);
      default:
        return const Color(0xFF607D8B);
    }
  }

  void refreshData() {
    setState(() => updateData());
  }

  // ═══════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final equipment = widget.equipmentList.isNotEmpty
        ? widget.equipmentList.values.first
        : {};
    final equipmentName = equipment['name']?.toString() ?? 'Unknown Equipment';
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () {
        final equipmentData = widget.equipmentList.values.first;
        context.pushNamed(
          'EquipmentDetails',
          queryParameters: {
            'productionAreaName':
                (equipmentData['productionArea']?.toString().isNotEmpty ??
                        false)
                    ? equipmentData['productionArea'].toString()
                    : widget.selectedProductionAreaName,
            'equipmentId': equipmentData['name'].toString(),
          },
        );
      },
      child: CardWidget(
        glowColor: statusColor,
        topPadMultiplier: 1.2,
        bottomPadMultiplier: 1.0,
        armLenMultiplier: 0.7,
        builder: (context, s) {
          if (widget.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: statusColor.withOpacity(0.6),
                strokeWidth: s.strokeW * 3,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Name + Status Badge ──
              _buildHeader(s, equipmentName, statusColor),
              SizedBox(height: s.pad * 0.3),

              // ── Accent divider ──
              Container(
                height: s.strokeW * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withOpacity(0.6),
                      statusColor.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
              SizedBox(height: s.pad * 0.5),

              // ── Equipment Image ──
              Expanded(
                flex: 28,
                child: _buildImage(context, s),
              ),
              SizedBox(height: s.pad * 0.4),

              // ── Info Rows ──
              Expanded(
                flex: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoRow(
                        context, s, 'Equipment Process', equipmentProcess),
                    _buildInfoRow(
                        context, s, 'Work Order', selectedWorkID ?? 'N/A'),
                    _buildInfoRow(context, s, 'Process ID', processID ?? 'N/A'),
                  ],
                ),
              ),
              SizedBox(height: s.pad * 0.3),

              // ── Progress Bars ──
              Expanded(
                flex: 28,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNeonBar(
                      context,
                      s,
                      label: 'Today Output',
                      percent: todayPlannedQty! > 0
                          ? (todayActualQty! / todayPlannedQty!).clamp(0.0, 1.0)
                          : 0.0,
                      value: '$todayActualQty $unit',
                      barColor: const Color(0xFF00E5FF),
                    ),
                    _buildNeonBar(
                      context,
                      s,
                      label: 'WO Progress',
                      percent: quantity! > 0
                          ? (progress! / quantity!).clamp(0.0, 1.0)
                          : 0.0,
                      value:
                          quantity! > 0 ? '$progress / $quantity $unit' : 'N/A',
                      barColor: const Color(0xFF00E676),
                    ),
                    _buildNeonBar(
                      context,
                      s,
                      label: 'OEE',
                      percent: oee!.clamp(0.0, 1.0),
                      value: oee! > 0
                          ? '${(oee! * 100).toStringAsFixed(0)}%'
                          : '0%',
                      barColor: _oeeColor(oee!),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Header Row ──
  Widget _buildHeader(CardSizing s, String name, Color statusColor) {
    return Builder(builder: (context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        // Accent bar
        Container(
          width: s.accentW,
          height: s.titleFs * 1.4,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(1),
            boxShadow: isLight ? null : [
              BoxShadow(
                  color: statusColor.withOpacity(0.7), blurRadius: s.pad * 0.4),
            ],
          ),
        ),
        SizedBox(width: s.pad * 0.4),
        // Equipment name
        Expanded(
          child: Builder(builder: (context) {
            final isLt = Theme.of(context).brightness == Brightness.light;
            return Text(
              name,
              style: GoogleFonts.poppins(
                color: isLt
                    ? FlutterFlowTheme.of(context).txtPrimary
                    : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: s.titleFs,
                shadows: isLt ? null : [
                  Shadow(color: statusColor.withOpacity(0.3), blurRadius: 6)
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ),
        SizedBox(width: s.pad * 0.3),
        // Status badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: s.pad * 0.6,
            vertical: s.pad * 0.2,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(s.pad * 0.3),
            border: Border.all(
                color: statusColor.withOpacity(0.6), width: s.strokeW * 2),
            boxShadow: isLight ? null : [
              BoxShadow(
                  color: statusColor.withOpacity(0.2), blurRadius: s.pad * 0.5),
            ],
          ),
          child: Text(
            status.toUpperCase(),
            style: GoogleFonts.poppins(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: s.bodyFs,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
    });
  }

  // ── Equipment Image ──
  Widget _buildImage(BuildContext context, CardSizing s) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(s.pad * 0.4),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: FlutterFlowTheme.of(context).cardStroke,
            width: s.strokeW,
          ),
          borderRadius: BorderRadius.circular(s.pad * 0.4),
        ),
        child: (equipmentImageUrl != null && equipmentImageUrl!.isNotEmpty)
            ? Image.network(
                equipmentImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _imagePlaceholder(context, s);
                },
                errorBuilder: (_, __, ___) => _assetImage(context, s),
              )
            : _assetImage(context, s),
      ),
    );
  }

  Widget _assetImage(BuildContext context, CardSizing s) {
    return Image.asset(
      'assets/images/equipment.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(Icons.precision_manufacturing_outlined,
            color: FlutterFlowTheme.of(context).primary, size: s.titleFs * 2),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context, CardSizing s) {
    return Container(
      color: FlutterFlowTheme.of(context).primaryBackground,
      child: Center(
        child: SizedBox(
          width: s.titleFs,
          height: s.titleFs,
          child: CircularProgressIndicator(
            strokeWidth: s.strokeW * 2,
            color: FlutterFlowTheme.of(context).secondary.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  // ── Info Row ──
  Widget _buildInfoRow(
      BuildContext context, CardSizing s, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: FlutterFlowTheme.of(context).txtSecondary,
            fontSize: s.labelFs,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: FlutterFlowTheme.of(context).txtPrimary,
              fontSize: s.labelFs,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Neon Progress Bar ──
  Widget _buildNeonBar(
    BuildContext context,
    CardSizing s, {
    required String label,
    required double percent,
    required String value,
    required Color barColor,
  }) {
    final barH = s.h * 0.035;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: s.bodyFs * 0.9,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: barColor,
                fontSize: s.bodyFs * 0.9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: barH * 0.3),
        // Bar
        Container(
          width: double.infinity,
          height: barH,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(barH * 0.5),
            border: Border.all(
              color: barColor.withOpacity(0.12),
              width: s.strokeW,
            ),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(barH * 0.5),
                color: barColor,
                boxShadow: isLight ? null : [
                  BoxShadow(
                    color: barColor.withOpacity(0.55),
                    blurRadius: barH * 1.5,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // OEE color — green if good, amber if medium, red if low
  Color _oeeColor(double oee) {
    if (oee >= 0.75) return const Color(0xFF00E676);
    if (oee >= 0.50) return const Color(0xFFFFC107);
    return const Color(0xFFEF5350);
  }
}
