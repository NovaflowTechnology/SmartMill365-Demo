import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'mc_wo_qty_data_logger_widget.dart' show McWoQtyDataLoggerWidget;
import 'package:flutter/material.dart';

class McWoQtyDataLoggerModel extends FlutterFlowModel<McWoQtyDataLoggerWidget> {
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
