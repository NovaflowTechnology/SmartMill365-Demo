import 'package:smartmachine365/web_app_template/kanban_dashboard/kanban_dashboard_widget.dart';
import 'package:smartmachine365/web_app_template/side_nav/side_nav_model.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class KanbanDashboard extends FlutterFlowModel<KanbanDashboardWidget> {
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
