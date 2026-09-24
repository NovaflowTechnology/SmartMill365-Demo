import 'package:smartmachine365/web_app_template/equipment_overview/equipmentcardmain_model.dart';
import 'package:smartmachine365/web_app_template/equipment_overview/statusbaroverview_model.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/web_app_template/side_nav/side_nav_widget.dart';
import 'equipment_overview_widget.dart' show EquipmentOverviewWidget;
import 'package:flutter/material.dart';

class EquipmentOverviewModel extends FlutterFlowModel<EquipmentOverviewWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for sideNav component.
  late SideNavModel sideNavModel;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
    // State field(s) for Sort DropDown widget.
  FormFieldController<String>? sortDropDownValueController;
  // Model for statusbaroverview component.
  late StatusbaroverviewModel statusbaroverviewModel;
  
  // List to manage multiple equipment card models dynamically.
  late List<EquipmentcardmainModel> equipmentCardModels;

  @override
  void initState(BuildContext context) {
    // Initialize the sideNav and status bar models
    sideNavModel = createModel(context, () => SideNavModel());
    statusbaroverviewModel = createModel(context, () => StatusbaroverviewModel());

    // Initialize the list of equipment card models (6 instances for now)
    equipmentCardModels = List.generate(
      6,
      (index) => createModel(context, () => EquipmentcardmainModel()),
    );
  }

  /// Helper method to retrieve a specific equipment card model by index
  EquipmentcardmainModel getEquipmentCardMainModel(int index) {
    if (index >= 0 && index < equipmentCardModels.length) {
      return equipmentCardModels[index];
    }
    // Default to first model if the index is out of bounds
    return equipmentCardModels.first;
  }

  @override
  void dispose() {
    sideNavModel.dispose();
    statusbaroverviewModel.dispose();
    // Dispose all equipment card models
    for (final model in equipmentCardModels) {
      model.dispose();
    }
  }
}
