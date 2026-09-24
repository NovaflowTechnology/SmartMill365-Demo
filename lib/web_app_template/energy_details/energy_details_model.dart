import 'package:smartmachine365/web_app_template/energy_details/equipmentcard_model.dart';

import 'energydetailscurrentcard_widget.dart';
import 'energydetailsenergycard_widget.dart';
import 'energydetailspowercard_widget.dart';
import 'energydetailsvoltagecard_widget.dart';
import 'powerconsumptionenergydetailscard_widget.dart';
import 'powerusagecardenergydetails_widget.dart';
import 'realtimepowercard_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'energy_details_widget.dart' show EnergyDetailsWidget;
import 'package:flutter/material.dart';

class EnergyDetailsModel extends FlutterFlowModel<EnergyDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Model for energydetailscurrentcard component.
  late EnergydetailscurrentcardModel energydetailscurrentcardModel;
  // Model for energydetailsvoltagecard component.
  late EnergydetailsvoltagecardModel energydetailsvoltagecardModel;
  // Model for energydetailspowercard component.
  late EnergydetailspowercardModel energydetailspowercardModel;
  // Model for energydetailsenergycard component.
  late EnergydetailsenergycardModel energydetailsenergycardModel;
  // Model for realtimepowercard component.
  late RealtimepowercardModel realtimepowercardModel;
  // Model for powerusagecardenergydetails component.
  late PowerusagecardenergydetailsModel powerusagecardenergydetailsModel;
  // Model for powerconsumptionenergydetailscard component.
  late PowerconsumptionenergydetailscardModel powerconsumptionenergydetailscardModel;
  late EquipmentCardModel equipmentCardModel;

  @override
  void initState(BuildContext context) {
    energydetailscurrentcardModel = createModel(context, () => EnergydetailscurrentcardModel());
    energydetailsvoltagecardModel = createModel(context, () => EnergydetailsvoltagecardModel());
    energydetailspowercardModel = createModel(context, () => EnergydetailspowercardModel());
    energydetailsenergycardModel = createModel(context, () => EnergydetailsenergycardModel());
    realtimepowercardModel = createModel(context, () => RealtimepowercardModel());
    powerusagecardenergydetailsModel = createModel(context, () => PowerusagecardenergydetailsModel());
    powerconsumptionenergydetailscardModel = createModel(context, () => PowerconsumptionenergydetailscardModel());
    equipmentCardModel = createModel(context, () => EquipmentCardModel());
  }

  @override
  void dispose() {
    energydetailscurrentcardModel.dispose();
    energydetailsvoltagecardModel.dispose();
    energydetailspowercardModel.dispose();
    energydetailsenergycardModel.dispose();
    realtimepowercardModel.dispose();
    powerusagecardenergydetailsModel.dispose();
    powerconsumptionenergydetailscardModel.dispose();
  }
}