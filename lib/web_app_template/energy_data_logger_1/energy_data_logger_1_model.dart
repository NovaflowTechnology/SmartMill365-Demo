import 'package:smartmachine365/flutter_flow/form_field_controller.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'energy_data_logger_1_widget.dart' show EnergyDataLogger1Widget;
import 'package:flutter/material.dart';

class EnergyDataLogger1Model extends FlutterFlowModel<EnergyDataLogger1Widget> {
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
