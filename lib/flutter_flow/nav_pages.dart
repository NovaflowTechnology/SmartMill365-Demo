import 'rbac.dart';

/// Maps route names from [kNavigablePages] to their GoRouter paths.
const Map<String, String> kNavPagePaths = {
  'EquipmentOverview':         '/equipmentOverview',
  'EquipmentDetails':          '/equipmentDetails',
  'ProductionLineKPI':         '/productionLineKPI',
  'MachineKPI':                '/machineKPI',
  'EnergyOverview':            '/energyOverview',
  'EnergyComparison':          '/EnergyComparison',
  'DeviceEnergyComparison':    '/DeviceEnergyComparison',
  'EnergyDetails':             '/energyDetails',
  'CarbonEmission':            '/carbonEmission',
  'PowerFactorMonitoring':     '/powerFactorMonitoring',
  'MaxDemandMonitoring':       '/maxDemandMonitoring',
  'MdPrediction':              '/mdPrediction',
  'SankeyEnergyFlow':          '/sankeyEnergyFlow',
  'kwhTone':                   '/kwhTone',
  'SecComparisonInsight':      '/secComparisonInsight',
  'ProductionOutputLog':       '/productionOutputLog',
  'TnbE3BillSimulator':        '/tnbE3BillSimulator',
  'SolarSettlement':           '/solarSettlement',
  'KanbanDashboard':           '/KanbanDashboard',
  'AirCompressorMonitoring':   '/airCompressorMonitoring',
  'WorkOrderOverview':         '/WorkOrderOverview',
  'WorkOrderReport':           '/WorkOrderReport',
  'ProductionCalendar':        '/ProductionCalendar',
  'ProductionTaskWorkStation': '/ProductionTaskWorkStation',
  'EquipmentStatusData':       '/EquipmentStatusData',
  'EquipmentDataLogger':       '/EquipmentDataLogger',
  'EquipmentAlarmData':        '/EquipmentAlarmData',
  'OEEData':                   '/OEEData',
  'EnergyDataLogger':          '/EnergyDataLogger',
  'EnergyDataLogger2':         '/EnergyDataLogger2',
  'EnergyVsWorkOrder':         '/EnergyVsWorkOrder',
  'EquipmentEnergyData':       '/EquipmentEnergyData',
  'ManageUserGroups':          '/manageUserGroups',
  'EnergySystemSettings':      '/EnergySystemSettings',
  'MasterBillingConfig':       '/MasterBillingConfig',
  'TariffCategorySetup':       '/TariffCategorySetup',
  'EnergySankeyFlowSetting':   '/EnergySankeyFlowSetting',
  'EmissionFactorManagement':  '/emissionFactorManagement',
  'CarbonDashboardConfigSetting': '/carbonDashboardConfigSetting',
  'AirCompressorDashboardConfigSetting': '/airCompressorDashboardConfigSetting',
  'DeviceDiscovery':           '/deviceDiscovery',
  'DeviceLiveInsight':         '/deviceLiveInsight',
  'GfsTnbMeter':               '/GfsTnbMeter',
};

/// Represents a navigable page in the sidebar.
typedef NavPageEntry = ({
  String label,
  String routeName,
  String? module,
});

/// All sidebar-navigable pages with their module requirements.
/// Super Admin always has access to all pages (checked in [resolveHomePage]).
const List<NavPageEntry> kNavigablePages = [
  // Equipment Monitoring
  (label: 'Equipment Overview', routeName: 'EquipmentOverview', module: AppRoles.kModuleEquipmentOverview),
  (label: 'Equipment Details', routeName: 'EquipmentDetails', module: AppRoles.kModuleEquipmentDetails),
  (label: 'Production Line KPI', routeName: 'ProductionLineKPI', module: AppRoles.kModuleProductionLineKpi),
  (label: 'Machine KPI', routeName: 'MachineKPI', module: AppRoles.kModuleMachineKpi),
  // Energy Monitoring
  (label: 'Energy Overview', routeName: 'EnergyOverview', module: AppRoles.kModuleEnergyOverview),
  (label: 'Device Energy Comparison', routeName: 'DeviceEnergyComparison', module: AppRoles.kModuleDeviceEnergyComparison),
  (label: 'Energy Historical Data', routeName: 'EnergyComparison', module: AppRoles.kModuleEnergyComparison),
  (label: 'Energy Details', routeName: 'EnergyDetails', module: AppRoles.kModuleEnergyDetails),
  (label: 'Carbon Emission', routeName: 'CarbonEmission', module: AppRoles.kModuleCarbonEmission),
  (label: 'PF Monitoring', routeName: 'PowerFactorMonitoring', module: AppRoles.kModulePfMonitoring),
  // Standalone
  (label: 'Max Demand Monitoring', routeName: 'MaxDemandMonitoring', module: AppRoles.kModuleMaxDemand),
  (label: 'MD Prediction', routeName: 'MdPrediction', module: AppRoles.kModuleMdPrediction),
  (label: 'Sankey Energy Flow', routeName: 'SankeyEnergyFlow', module: AppRoles.kSankeyEnergyFlow),
  // kWh / Tonne
  (label: 'kWh per Tonne', routeName: 'kwhTone', module: AppRoles.kModuleKwhTone),
  (label: 'SEC Comparison Insight', routeName: 'SecComparisonInsight', module: AppRoles.kModuleSecComparison),
  (label: 'Production Output Data Log', routeName: 'ProductionOutputLog', module: AppRoles.kModuleProductionOutputLog),
  (label: 'TNB Billing Engine Simulator', routeName: 'TnbE3BillSimulator', module: AppRoles.kModuleTnbBilling),
  (label: 'Solar Settlement', routeName: 'SolarSettlement', module: AppRoles.kModuleSolarSettlement),
  (label: 'Kanban Dashboard', routeName: 'KanbanDashboard', module: AppRoles.kModuleKanbanDashboard),
  // Utility Monitoring
  (label: 'Air Compressor Monitoring', routeName: 'AirCompressorMonitoring', module: AppRoles.kModuleAirCompressorMonitoring),
  // Work Order
  (label: 'Work Order Overview', routeName: 'WorkOrderOverview', module: AppRoles.kModuleWorkOrderOverview),
  (label: 'Work Order Report', routeName: 'WorkOrderReport', module: AppRoles.kModuleWorkOrderReport),
  (label: 'Production Calendar', routeName: 'ProductionCalendar', module: AppRoles.kModuleProductionCalendar),
  (label: 'Production Task Work Station', routeName: 'ProductionTaskWorkStation', module: AppRoles.kModuleProductionTask),
  // More Data
  (label: 'Equipment Status Data', routeName: 'EquipmentStatusData', module: AppRoles.kModuleEquipStatusData),
  (label: 'Equipment Data Logger', routeName: 'EquipmentDataLogger', module: AppRoles.kModuleEquipDataLogger),
  (label: 'Equipment Alarm Data', routeName: 'EquipmentAlarmData', module: AppRoles.kModuleEquipAlarmData),
  (label: 'OEE Data', routeName: 'OEEData', module: AppRoles.kModuleOeeData),
  (label: 'Energy Data Logger', routeName: 'EnergyDataLogger', module: AppRoles.kModuleEnergyDataLogger1),
  (label: 'Solar Generation Data', routeName: 'EnergyDataLogger2', module: AppRoles.kModuleEnergyDataLogger2),
  (label: 'Energy vs Work Order', routeName: 'EnergyVsWorkOrder', module: AppRoles.kModuleEnergyVsWorkOrder),
  (label: 'Equipment Energy Data', routeName: 'EquipmentEnergyData', module: AppRoles.kModuleEquipEnergyData),
  // Settings
  (label: 'Manage Users & Groups', routeName: 'ManageUserGroups', module: AppRoles.kModuleUserMgmt),
  (label: 'Energy System Settings', routeName: 'EnergySystemSettings', module: AppRoles.kModuleEnergySystemSettings),
  (label: 'Master Billing Config', routeName: 'MasterBillingConfig', module: AppRoles.kModuleMasterBillingConfig),
  (label: 'Tariff Category Setup', routeName: 'TariffCategorySetup', module: AppRoles.kModuleTariffConfig),
  (label: 'Energy Sankey Flow Setting', routeName: 'EnergySankeyFlowSetting', module: AppRoles.kModuleEnergySankeyFlowSetting),
  (label: 'Emission Factor Management', routeName: 'EmissionFactorManagement', module: AppRoles.kModuleEmissionFactorMgmt),
  (label: 'Carbon Dashboard Config', routeName: 'CarbonDashboardConfigSetting', module: AppRoles.kModuleCarbonDashboardConfig),
  (label: 'Air Compressor Dashboard Setting', routeName: 'AirCompressorDashboardConfigSetting', module: AppRoles.kModuleAirCompressorDashboardConfig),
  (label: 'Device Discovery', routeName: 'DeviceDiscovery', module: AppRoles.kModuleDeviceDiscovery),
  (label: 'Device Live Data Insight', routeName: 'DeviceLiveInsight', module: AppRoles.kModuleDeviceLiveInsight),
];

/// Returns the route name the user should land on.
///
/// Priority: [savedPage] (if accessible) → first accessible page → 'EquipmentOverview'.
/// [role] is checked to grant Super Admin unrestricted access.
String resolveHomePage(
  String? savedPage,
  List<String> accessibleModules,
  String role,
) {
  final isSA = AppRoles.normalizeRole(role) == AppRoles.superAdmin;

  bool canAccess(NavPageEntry page) {
    if (isSA) return true;
    if (page.module == null) return true;
    return accessibleModules.contains(page.module);
  }

  if (savedPage != null && savedPage.isNotEmpty) {
    final preferred = kNavigablePages.where((p) => p.routeName == savedPage).firstOrNull;
    if (preferred != null && canAccess(preferred)) return preferred.routeName;
  }

  final first = kNavigablePages.where(canAccess).firstOrNull;
  if (first != null) return first.routeName;

  return 'EquipmentOverview';
}
