import 'package:flutter/material.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_model.dart';
import 'package:smartmachine365/web_app_template/sankey_energy_flow/sankey_energy_flow.dart';
import 'package:smartmachine365/web_app_template/side_nav/side_nav_model.dart';

class SankeyEnergyFlowModel extends FlutterFlowModel<SankeyEnergyFlow> {
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
