import '/flutter_flow/flutter_flow_util.dart';
import 'side_nav_widget.dart' show SideNavWidget;
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class SideNavModel extends FlutterFlowModel<SideNavWidget> {
  // Static so expanded state survives widget rebuilds caused by navigation
  static final expandableController1  = ExpandableController(); // Equipment Monitoring
  static final expandableController2  = ExpandableController(); // Energy Monitoring
  static final expandableController3  = ExpandableController(); // Work Order Mgmt
  static final expandableController4  = ExpandableController(); // Settings
  static final expandableController5  = ExpandableController(); // Equipment Data
  static final expandableController6  = ExpandableController(); // Energy Data
  static final expandableController8  = ExpandableController(); // Production Task Overview
  static final expandableController9  = ExpandableController(); // General Factory Setting
  static final expandableControllerS1 = ExpandableController(); // Settings > User & Access
  static final expandableControllerS2 = ExpandableController(); // Settings > Energy & Billing
  static final expandableControllerS3 = ExpandableController(); // Settings > Data
  static final expandableControllerKwh    = ExpandableController(); // kWh / Tonne section
  static final expandableControllerTnbBilling = ExpandableController(); // TNB Billing Engine Simulator section
  static final expandableControllerKanban = ExpandableController(); // Settings > Kanban Dashboard
  static final expandableControllerKanbanView = ExpandableController(); // Kanban Dashboard views (top)
  static final expandableControllerSystem = ExpandableController(); // System (SA Only)
  static final expandableControllerReports = ExpandableController(); // Reports section
  static final expandableControllerUtility = ExpandableController(); // Utility Monitoring
  static final expandableControllerUtilitySettings = ExpandableController(); // Settings > Utility Monitoring
  static final navScrollController    = ScrollController();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
