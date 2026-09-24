import 'package:smartmachine365/flutter_flow/form_field_controller.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'equipment_alarm_data_widget.dart' show EquipmentAlarmDataWidget;
import 'package:flutter/material.dart';

class EquipmentAlarmDataModel
    extends FlutterFlowModel<EquipmentAlarmDataWidget> {
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
