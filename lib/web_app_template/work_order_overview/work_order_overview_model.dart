import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'work_order_overview_widget.dart' show WorkOrderOverviewWidget;
import 'package:flutter/material.dart';

class WorkOrderOverviewModel extends FlutterFlowModel<WorkOrderOverviewWidget> {
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
