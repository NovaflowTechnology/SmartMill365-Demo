import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'energy_system_settings_widget.dart' show EnergySystemSettingsWidget;
import 'package:flutter/material.dart';

class EnergySystemSettingsModel extends FlutterFlowModel<EnergySystemSettingsWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for sideNav component.
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
