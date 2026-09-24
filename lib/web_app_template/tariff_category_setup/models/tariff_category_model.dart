import 'package:smartmachine365/web_app_template/tariff_category_setup/widgets/tariff_category_widget.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'package:flutter/material.dart';

class TariffCategoryModel extends FlutterFlowModel<TariffCategoryWidget> {
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
