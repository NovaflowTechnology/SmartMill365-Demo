import 'package:smartmachine365/web_app_template/equipment_details/equipment_details_widget.dart';
import 'package:smartmachine365/web_app_template/equipment_details/equipmentcardmaindetails_model.dart';
import 'package:smartmachine365/web_app_template/side_nav/side_nav_model.dart';
import 'alarmlistcardproduction_model.dart';
import 'equipmentcardmaindetails_model.dart';
import 'runtimeoeecard_model.dart';
import 'stationkpicard_model.dart';
import 'workordercard_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';

class EquipmentDetailsModel extends FlutterFlowModel<EquipmentDetailsWidget> {
  /// State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // Model for sideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for EquipmentDropDown widget.
  String? equipmentDropDownValue;
  FormFieldController<String>? equipmentDropDownValueController;
  // Model for equipmentcardmaindetails component.
  late EquipmentcardmaindetailsModel equipmentcardmaindetailsModel;
  // Model for STATIONKPICARD component.
  late StationkpicardModel stationkpicardModel;
  // Model for runtimeoeecard component.
  late RuntimeoeecardModel runtimeoeecardModel;
  // Model for alarmlistcardproduction component.
  late AlarmlistcardproductionModel alarmlistcardproductionModel;
  // Model for workordercard component.
  late WorkordercardModel workordercardModel;

  @override
  void initState(BuildContext context) {
    sideNavModel = createModel(context, () => SideNavModel());
    equipmentcardmaindetailsModel =
        createModel(context, () => EquipmentcardmaindetailsModel());
    stationkpicardModel = createModel(context, () => StationkpicardModel());
    runtimeoeecardModel = createModel(context, () => RuntimeoeecardModel());
    alarmlistcardproductionModel =
        createModel(context, () => AlarmlistcardproductionModel());
    workordercardModel = createModel(context, () => WorkordercardModel());
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    sideNavModel.dispose();
    dropDownValueController?.dispose();
    equipmentDropDownValueController?.dispose();
    equipmentcardmaindetailsModel.dispose();
    stationkpicardModel.dispose();
    runtimeoeecardModel.dispose();
    alarmlistcardproductionModel.dispose();
    workordercardModel.dispose();
  }
}