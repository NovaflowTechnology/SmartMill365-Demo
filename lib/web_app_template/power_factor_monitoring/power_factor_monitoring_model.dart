import 'package:smartmachine365/web_app_template/energy_overview/powerrankingcard_model.dart';
import 'package:smartmachine365/web_app_template/power_factor_monitoring/power_factor_monitoring_widget.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'package:flutter/material.dart';

class PowerFactorMonitoringModel extends FlutterFlowModel<PowerFactorMonitoringWidget> {
  // Model for sideNav component.
  late SideNavModel sideNavModel;
  late PowerrankingcardModel powerrankingcardModel;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    powerrankingcardModel = createModel(context, () => PowerrankingcardModel());
  }

  @override
  void dispose() {
    powerrankingcardModel.dispose();
    sideNavModel.dispose();
  }
}
