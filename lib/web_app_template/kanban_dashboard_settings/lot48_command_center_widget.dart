import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard/models/pecc_live_data.dart';
import 'package:smartmachine365/web_app_template/kanban_dashboard_settings/lot_command_center_widget.dart';

/// Lot 48 Energy Command Center — single-block center hub layout with TNB grid tower,
/// hero KPIs, plant health sidebar, 3D flow map, and bottom charts.
class Lot48CommandCenterWidget extends StatelessWidget {
  final String lotName;
  final String orgName;
  final String orgSubLabel;
  final String logoUrl;
  final String bgImageUrl;
  final PeccLiveData? liveData;
  final Map<String, String> widgetLabels;
  final Map<String, (double, double)> widgetPositions;
  final int dataTick;

  const Lot48CommandCenterWidget({
    super.key,
    required this.lotName,
    this.orgName = '',
    this.orgSubLabel = '',
    this.logoUrl = '',
    this.bgImageUrl = '',
    this.liveData,
    this.widgetLabels = const {},
    this.widgetPositions = const {},
    this.dataTick = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LotCommandCenterWidget(
      lotName: lotName,
      orgName: orgName,
      orgSubLabel: orgSubLabel,
      logoUrl: logoUrl,
      bgImageUrl: bgImageUrl,
      liveData: liveData,
      widgetLabels: widgetLabels,
      widgetPositions: widgetPositions,
      dataTick: dataTick,
    );
  }
}
