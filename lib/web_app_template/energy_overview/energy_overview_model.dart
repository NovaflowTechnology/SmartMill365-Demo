
import 'package:smartmachine365/web_app_template/energy_overview/powerconsumptionenergydetails_model.dart';
import 'package:smartmachine365/flutter_flow/form_field_controller.dart';

import 'powerrankingcard_widget.dart';
import 'powerusagecard_widget.dart';
import 'powerdiagram_widget.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'energy_overview_widget.dart' show EnergyOverviewWidget;
import 'package:flutter/material.dart';

class EnergyOverviewModel extends FlutterFlowModel<EnergyOverviewWidget> {
  ///  State fields for stateful widgets in this page.
  // Model for powerconsumptionenergydetails component.
  late PowerconsumptionenergydetailsModel powerconsumptionenergydetailsModel;
  // Model for powerusagecard component.
  late PowerusagecardModel powerusagecardModel;
  // Model for powerrankingcard component.
  late PowerrankingcardModel powerrankingcardModel;

  late PowerdiagramModel powerdiagramModel;
  
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {
    powerconsumptionenergydetailsModel =
        createModel(context, () => PowerconsumptionenergydetailsModel());
    powerusagecardModel = createModel(context, () => PowerusagecardModel());
    powerrankingcardModel = createModel(context, () => PowerrankingcardModel());
    powerdiagramModel = createModel(context, () => PowerdiagramModel());
  }

  @override
  void dispose() {
    powerconsumptionenergydetailsModel.dispose();
    powerusagecardModel.dispose();
    powerrankingcardModel.dispose();
    powerdiagramModel.dispose();
  }
}
