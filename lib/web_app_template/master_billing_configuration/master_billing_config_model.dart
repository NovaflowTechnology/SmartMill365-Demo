import 'package:smartmachine365/web_app_template/master_billing_configuration/master_billing_config_widget.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'package:flutter/material.dart';

class MasterBillingConfigModel extends FlutterFlowModel<MasterBillingConfigWidget> {
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
