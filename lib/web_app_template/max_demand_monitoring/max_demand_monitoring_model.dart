import 'package:flutter/material.dart';
import 'package:smartmachine365/flutter_flow/flutter_flow_model.dart';
import 'package:smartmachine365/flutter_flow/form_field_controller.dart';
import 'package:smartmachine365/web_app_template/max_demand_monitoring/max_demand_monitoring.dart';
import 'package:smartmachine365/web_app_template/side_nav/side_nav_model.dart';

class MaxDemandMonitoringModel extends FlutterFlowModel<MaxDemandMonitoring> {
  ///  State fields for stateful widgets in this page.

  // Model for sideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
  }

  @override
  void dispose() {
    sideNavModel.dispose();
  }
}
