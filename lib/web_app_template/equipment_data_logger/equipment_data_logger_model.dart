import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'equipment_data_logger_widget.dart' show EquipmentDataLoggerWidget;
import 'package:flutter/material.dart';

class OeeDataModel extends FlutterFlowModel<EquipmentDataLoggerWidget> {
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
