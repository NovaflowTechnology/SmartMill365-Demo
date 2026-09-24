import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'energy_data_logger_widget.dart' show EnergyDataLoggerWidget;
import 'package:flutter/material.dart';

class EnergyDataLoggerModel extends FlutterFlowModel<EnergyDataLoggerWidget> {
  late SideNavModel sideNavModel;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
  }
}
