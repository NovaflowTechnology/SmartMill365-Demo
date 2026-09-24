import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'energy_comparison_widget.dart' show EnergyComparisonWidget;
import 'powerconsumptionenergydetailscard_widget.dart';
import 'package:flutter/material.dart';

class EnergyComparisonModel extends FlutterFlowModel<EnergyComparisonWidget> {
  ///  State fields for stateful widgets in this page.
  /// 
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  late PowerconsumptionenergydetailscardModel
      powerconsumptionenergydetailscardModel;

  @override
  void initState(BuildContext context) {
    powerconsumptionenergydetailscardModel =
        createModel(context, () => PowerconsumptionenergydetailscardModel());
  }

  @override
  void dispose() {
    powerconsumptionenergydetailscardModel.dispose();
  }
}
