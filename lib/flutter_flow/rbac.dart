// ─────────────────────────────────────────────────────────────────────────────
// AppRoles — Central RBAC utility for SMARTFACTORY365
// ─────────────────────────────────────────────────────────────────────────────

class AppRoles {
  // ── Role name constants (built-in) ────────────────────────────────────────
  static const String superAdmin = 'Super Admin';
  static const String admin = 'Admin';
  static const String manager = 'Manager';
  static const String engineer = 'Engineer';
  static const String operator_ = 'Operator';
  static const String viewer = 'Viewer';

  /// All built-in role names.
  static const List<String> builtInRoles = [
    superAdmin,
    admin,
    manager,
    engineer,
    operator_,
    viewer,
  ];

  // ── Module key constants (broad categories — legacy) ──────────────────────
  static const String kModuleDashboards = 'dashboards';
  static const String kModuleAlarms = 'alarms';
  static const String kModuleDeviceSetup = 'device_setup';
  static const String kModuleTariffConfig = 'tariff_config';
  static const String kModuleViewTariffs = 'view_tariffs';
  static const String kModuleUserMgmt = 'user_management';
  static const String kModuleAuditLogs = 'audit_logs';
  static const String kModuleSettings = 'settings';
  static const String kModuleReports = 'reports';

  // ── Module key constants (granular — per sidebar item) ────────────────────
  // Equipment Monitoring
  static const String kModuleEquipmentOverview = 'equipment_overview';
  static const String kModuleEquipmentDetails = 'equipment_details';
  static const String kModuleProductionLineKpi = 'production_line_kpi';
  static const String kModuleMachineKpi = 'machine_kpi';

  // Energy Monitoring
  static const String kModuleEnergyOverview = 'energy_overview';
  static const String kModuleEnergyComparison = 'energy_comparison';
  static const String kModuleDeviceEnergyComparison = 'device_energy_comparison';
  static const String kModuleEnergyDetails = 'energy_details';
  static const String kModuleCarbonEmission = 'carbon_emission';
  static const String kModulePfMonitoring = 'pf_monitoring';

  // Standalone
  static const String kModuleMaxDemand = 'max_demand_monitoring';
  static const String kModuleMdPrediction = 'md_prediction';
  static const String kSankeyEnergyFlow = 'sankey_energy_flow';
  static const String kModuleKwhTone = 'kwh_tone';
  static const String kModuleSecComparison = 'sec_comparison_insight';
  static const String kModuleProductionOutputLog = 'production_output_log';
  static const String kModuleTnbBilling = 'tnb_billing';
  static const String kModuleSolarSettlement = 'solar_settlement';
  static const String kModuleKanbanDashboard = 'kanban_dashboard';

  // Utility Monitoring
  static const String kModuleAirCompressorMonitoring = 'air_compressor_monitoring';

  // Work Order
  static const String kModuleWorkOrderOverview = 'work_order_overview';
  static const String kModuleWorkOrderReport = 'work_order_report';
  static const String kModuleProductionCalendar = 'production_calendar';

  // Production Task
  static const String kModuleProductionTask = 'production_task';

  // Settings sub-pages (granular — each sidebar item assignable individually)
  static const String kModuleMasterFacilitySetting = 'master_facility_setting';
  static const String kModuleEquipmentSettings = 'equipment_settings';
  static const String kModuleProductSettings = 'product_settings';
  static const String kModuleAlarmSettings = 'alarm_settings';
  static const String kModuleEnergySystemSettings = 'energy_system_settings';
  static const String kModuleKanbanDashboardSettings = 'kanban_dashboard_settings';
  static const String kModuleMasterBillingConfig = 'master_billing_config';
  static const String kModuleEnergySankeyFlowSetting = 'energy_sankey_flow_setting';
  static const String kModuleCarbonDashboardConfig = 'carbon_dashboard_config_setting';
  static const String kModuleAirCompressorDashboardConfig = 'air_compressor_dashboard_config_setting';

  // General Factory Setting sub-pages
  static const String kModuleGfsPlant = 'gfs_plant';
  static const String kModuleGfsProductionArea = 'gfs_production_area';
  static const String kModuleGfsProductionLine = 'gfs_production_line';
  static const String kModuleGfsEquipment = 'gfs_equipment';
  static const String kModuleGfsProcess = 'gfs_process';
  static const String kModuleGfsProduct = 'gfs_product';
  static const String kModuleGfsProductProcessRouting = 'gfs_product_process_routing';
  static const String kModuleGfsInstrumentDevices = 'gfs_instrument_devices';
  static const String kModuleGfsParameterSetting = 'gfs_parameter_setting';
  static const String kModuleGfsAlarm = 'gfs_alarm';
  static const String kModuleGfsShift = 'gfs_shift';
  static const String kModuleGfsShiftCalendar = 'gfs_shift_calendar';
  static const String kModuleGfsDowntimeCalendar = 'gfs_downtime_calendar';
  static const String kModuleGfsAbnormalReason = 'gfs_abnormal_reason';
  static const String kModuleGfsDeviceType = 'gfs_device_type';
  static const String kModuleGfsEquipmentCategory = 'gfs_equipment_category';
  static const String kModuleGfsTnbMeter = 'gfs_tnb_meter';

  // Real-Time Data Configurator
  static const String kModuleDeviceDiscovery = 'device_discovery';
  static const String kModuleDeviceLiveInsight = 'device_live_insight';

  static const String kModuleEmissionFactorMgmt = 'emission_factor_mgmt';

  // System — Super Admin only
  static const String kModuleIntegrationConfig = 'integration_config';

  // Data modules
  static const String kModuleEquipStatusData = 'equipment_status_data';
  static const String kModuleEquipDataLogger = 'equipment_data_logger';
  static const String kModuleEquipAlarmData = 'equipment_alarm_data';
  static const String kModuleOeeData = 'oee_data';
  static const String kModuleEnergyDataLogger1 = 'energy_data_logger_1';
  static const String kModuleEnergyDataLogger2 = 'energy_data_logger_2';
  static const String kModuleEnergyVsWorkOrder = 'energy_vs_work_order';
  static const String kModuleEquipEnergyData = 'equipment_energy_data';


  // ── Human-readable labels for module toggles UI ───────────────────────────
  static const Map<String, String> moduleLabels = {
    kModuleEquipmentOverview: 'Equipment Overview',
    kModuleEquipmentDetails: 'Equipment Details',
    kModuleProductionLineKpi: 'Production Line KPI',
    kModuleMachineKpi: 'Machine KPI',
    kModuleEnergyOverview: 'Energy Overview',
    kModuleEnergyComparison: 'Energy Historical Data',
    kModuleDeviceEnergyComparison: 'Device Energy Comparison',
    kModuleEnergyDetails: 'Energy Details',
    kModuleCarbonEmission: 'Carbon Emission',
    kModuleEmissionFactorMgmt: 'Emission Factor Management',
    kModulePfMonitoring: 'PF Monitoring',
    kModuleMaxDemand: 'Max Demand Monitoring',
    kModuleMdPrediction: 'MD Prediction',
    kModuleKwhTone: 'kWh / Tonne',
    kModuleSecComparison: 'SEC Comparison Insight',
    kModuleProductionOutputLog: 'Production Output Data Log',
    kModuleTnbBilling: 'TNB Billing Simulator',
    kModuleSolarSettlement: 'Solar Settlement',
    kModuleKanbanDashboard: 'Kanban Dashboard',
    kModuleAirCompressorMonitoring: 'Air Compressor Monitoring',
    kModuleWorkOrderOverview: 'Work Order Overview',
    kModuleWorkOrderReport: 'Work Order Report',
    kModuleProductionCalendar: 'Production Calendar',
    kModuleProductionTask: 'Production Task',
    kModuleEquipStatusData: 'Equipment Status Data',
    kModuleEquipDataLogger: 'Equipment Data Logger',
    kModuleEquipAlarmData: 'Equipment Alarm Data',
    kModuleOeeData: 'OEE Data',
    kModuleEnergyDataLogger1: 'Energy Data Logger',
    kModuleEnergyDataLogger2: 'Solar Generation Data',
    kModuleEnergyVsWorkOrder: 'Energy vs Work Order',
    kModuleEquipEnergyData: 'Equipment Energy Data',
    kModuleReports: 'Reports',
    kModuleDeviceSetup: 'Device Settings',
    kModuleSettings: 'Settings',
    kModuleMasterFacilitySetting: 'Master Facility Setting',
    kModuleEquipmentSettings: 'Equipment Settings',
    kModuleProductSettings: 'Product Settings',
    kModuleAlarmSettings: 'Alarm Settings',
    kModuleEnergySystemSettings: 'Energy System Settings',
    kModuleKanbanDashboardSettings: 'Kanban Dashboard Settings',
    kModuleMasterBillingConfig: 'Master Billing Config',
    kModuleEnergySankeyFlowSetting: 'Energy Sankey Flow Setting',
    kModuleCarbonDashboardConfig: 'Carbon Dashboard Config',
    kModuleAirCompressorDashboardConfig: 'Air Compressor Dashboard Setting',
    kModuleUserMgmt: 'Manage Users & Groups',
    kModuleTariffConfig: 'Tariff Category Setup',
    kModuleGfsPlant: 'Plant',
    kModuleGfsProductionArea: 'Production Area',
    kModuleGfsProductionLine: 'Production Line',
    kModuleGfsEquipment: 'Equipment',
    kModuleGfsProcess: 'Process',
    kModuleGfsProduct: 'Product',
    kModuleGfsProductProcessRouting: 'Product Process Routing',
    kModuleGfsInstrumentDevices: 'Instrument Devices',
    kModuleGfsParameterSetting: 'Parameter Setting',
    kModuleGfsAlarm: 'Alarm',
    kModuleGfsShift: 'Shift',
    kModuleGfsShiftCalendar: 'Shift Calendar',
    kModuleGfsDowntimeCalendar: 'Downtime Calendar',
    kModuleGfsAbnormalReason: 'Abnormal Reason Setting',
    kModuleGfsDeviceType: 'Device Type Setting',
    kModuleGfsEquipmentCategory: 'Equipment Category',
    kModuleGfsTnbMeter: 'TNB Meter',
    kModuleDeviceDiscovery: 'Device Discovery',
    kModuleDeviceLiveInsight: 'Device Live Data Insight',
  };

  // ── Grouped modules for the edit dialog UI ────────────────────────────────
  static const Map<String, List<String>> moduleGroups = {
    'Equipment Monitoring': [
      kModuleEquipmentOverview,
      kModuleEquipmentDetails,
      kModuleProductionLineKpi,
      kModuleMachineKpi,
    ],
    'Energy Monitoring': [
      kModuleEnergyOverview,
      kModuleDeviceEnergyComparison,
      kModuleEnergyComparison,
      kModuleEnergyDetails,
      kModuleCarbonEmission,
      kModuleAirCompressorMonitoring,
      kModuleEmissionFactorMgmt,
      kModulePfMonitoring,
    ],
    'Standalone Modules': [
      kModuleMaxDemand,
      kModuleMdPrediction,
      kModuleKwhTone,
      kModuleSecComparison,
      kModuleProductionOutputLog,
      kModuleTnbBilling,
      kModuleSolarSettlement,
      kModuleKanbanDashboard,
    ],
    'Utility Monitoring': [
      kModuleAirCompressorMonitoring,
    ],
    'Work Order': [
      kModuleWorkOrderOverview,
      kModuleWorkOrderReport,
      kModuleProductionCalendar,
    ],
    'Production': [
      kModuleProductionTask,
    ],
    'Data Modules': [
      kModuleEquipStatusData,
      kModuleEquipDataLogger,
      kModuleEquipAlarmData,
      kModuleOeeData,
      kModuleEnergyDataLogger1,
      kModuleEnergyDataLogger2,
      kModuleEnergyVsWorkOrder,
      kModuleEquipEnergyData,
    ],
    'Admin & Settings': [
      kModuleReports,
      kModuleDeviceSetup,
      kModuleDeviceDiscovery,
      kModuleDeviceLiveInsight,
      kModuleMasterFacilitySetting,
      kModuleEquipmentSettings,
      kModuleProductSettings,
      kModuleAlarmSettings,
      kModuleUserMgmt,
      kModuleEnergySystemSettings,
      kModuleKanbanDashboardSettings,
      kModuleMasterBillingConfig,
      kModuleTariffConfig,
      kModuleEnergySankeyFlowSetting,
      kModuleCarbonDashboardConfig,
      kModuleAirCompressorDashboardConfig,
    ],
    'General Factory Setting': [
      kModuleGfsPlant,
      kModuleGfsProductionArea,
      kModuleGfsProductionLine,
      kModuleGfsEquipment,
      kModuleGfsProcess,
      kModuleGfsProduct,
      kModuleGfsProductProcessRouting,
      kModuleGfsInstrumentDevices,
      kModuleGfsParameterSetting,
      kModuleGfsAlarm,
      kModuleGfsShift,
      kModuleGfsShiftCalendar,
      kModuleGfsDowntimeCalendar,
      kModuleGfsAbnormalReason,
      kModuleGfsDeviceType,
      kModuleGfsEquipmentCategory,
      kModuleGfsTnbMeter,
    ],
  };

  /// All granular module keys (flat list).
  static List<String> get allModuleKeys => moduleGroups.values.expand((v) => v).toList();

  // ── Emission Factor Management — specific action keys ────────────────────
  static const String kEmfAddFactor     = 'add_factor';
  static const String kEmfActivate      = 'activate_factor';
  static const String kEmfEditDraft     = 'edit_draft';
  static const String kEmfEditActive    = 'edit_active';
  static const String kEmfEditLocked    = 'edit_locked';
  static const String kEmfDeleteDraft   = 'delete_draft';
  static const String kEmfDeleteActive  = 'delete_active';
  static const String kEmfDeleteLocked  = 'delete_locked';
  static const String kEmfViewAuditLog  = 'view_audit_log';

  // ── Per-module available actions ──────────────────────────────────────────
  static const Map<String, List<String>> moduleActions = {
    kModuleEquipmentOverview:        ['view', 'export'],
    kModuleEquipmentDetails:         ['view', 'export'],
    kModuleProductionLineKpi:        ['view', 'export'],
    kModuleMachineKpi:               ['view', 'export'],
    kModuleEnergyOverview:           ['view', 'export'],
    kModuleEnergyComparison:         ['view', 'export'],
    kModuleEnergyDetails:            ['view', 'export'],
    kModuleCarbonEmission:           ['view', 'export'],
    kModuleEmissionFactorMgmt: [
      kEmfAddFactor, kEmfActivate,
      kEmfEditDraft, kEmfEditActive, kEmfEditLocked,
      kEmfDeleteDraft, kEmfDeleteActive, kEmfDeleteLocked,
      kEmfViewAuditLog,
    ],
    kModulePfMonitoring:             ['view', 'export'],
    kModuleMaxDemand:                ['view', 'export'],
    kModuleMdPrediction:             ['view'],
    kSankeyEnergyFlow:               ['view'],
    kModuleKwhTone:                  ['view', 'export'],
    kModuleSecComparison:            ['view', 'export'],
    kModuleProductionOutputLog:      ['view', 'export'],
    kModuleTnbBilling:               ['view'],
    kModuleSolarSettlement:          ['view'],
    kModuleKanbanDashboard:          ['view', 'add', 'edit', 'delete'],
    kModuleAirCompressorMonitoring:  ['view'],
    kModuleWorkOrderOverview:        ['view', 'add', 'edit', 'delete'],
    kModuleWorkOrderReport:          ['view', 'export'],
    kModuleProductionCalendar:       ['view', 'add', 'edit', 'delete'],
    kModuleProductionTask:           ['view', 'add', 'edit', 'delete'],
    kModuleEquipStatusData:          ['view', 'export'],
    kModuleEquipDataLogger:          ['view', 'export'],
    kModuleEquipAlarmData:           ['view', 'export'],
    kModuleOeeData:                  ['view', 'export'],
    kModuleEnergyDataLogger1:        ['view', 'export'],
    kModuleEnergyDataLogger2:        ['view', 'export'],
    kModuleEnergyVsWorkOrder:        ['view', 'export'],
    kModuleEquipEnergyData:          ['view', 'export'],
    kModuleReports:                  ['view', 'export'],
    kModuleDeviceSetup:              ['view', 'add', 'edit', 'delete'],
    kModuleDeviceDiscovery:          ['view'],
    kModuleDeviceLiveInsight:        ['view'],
    kModuleUserMgmt:                 ['view', 'add', 'edit', 'delete'],
    kModuleTariffConfig:             ['view', 'add', 'edit', 'delete'],
    kModuleMasterFacilitySetting:    ['view', 'edit'],
    kModuleEquipmentSettings:        ['view', 'add', 'edit', 'delete'],
    kModuleProductSettings:          ['view', 'add', 'edit', 'delete'],
    kModuleAlarmSettings:            ['view', 'add', 'edit', 'delete'],
    kModuleEnergySystemSettings:     ['view', 'edit'],
    kModuleKanbanDashboardSettings:  ['view', 'edit'],
    kModuleMasterBillingConfig:      ['view', 'edit'],
    kModuleEnergySankeyFlowSetting:  ['view', 'edit'],
    kModuleCarbonDashboardConfig:    ['view', 'edit'],
    kModuleAirCompressorDashboardConfig: ['view', 'edit'],
    kModuleGfsPlant:                 ['view', 'add', 'edit', 'delete'],
    kModuleGfsProductionArea:        ['view', 'add', 'edit', 'delete'],
    kModuleGfsProductionLine:        ['view', 'add', 'edit', 'delete'],
    kModuleGfsEquipment:             ['view', 'add', 'edit', 'delete'],
    kModuleGfsProcess:               ['view', 'add', 'edit', 'delete'],
    kModuleGfsProduct:               ['view', 'add', 'edit', 'delete'],
    kModuleGfsProductProcessRouting: ['view', 'add', 'edit', 'delete'],
    kModuleGfsInstrumentDevices:     ['view', 'add', 'edit', 'delete'],
    kModuleGfsParameterSetting:      ['view', 'edit'],
    kModuleGfsAlarm:                 ['view', 'add', 'edit', 'delete'],
    kModuleGfsShift:                 ['view', 'add', 'edit', 'delete'],
    kModuleGfsShiftCalendar:         ['view', 'add', 'edit', 'delete'],
    kModuleGfsDowntimeCalendar:      ['view', 'add', 'edit', 'delete'],
    kModuleGfsAbnormalReason:        ['view', 'add', 'edit', 'delete'],
    kModuleGfsDeviceType:            ['view', 'add', 'edit', 'delete'],
    kModuleGfsEquipmentCategory:     ['view', 'add', 'edit', 'delete'],
  };

  // ── Human-readable action labels ──────────────────────────────────────────
  static const Map<String, String> actionLabels = {
    'view':             'View',
    'add':              'Add',
    'edit':             'Edit',
    'delete':           'Delete',
    'export':           'Export',
    'activate':         'Activate',
    // Emission Factor specific
    kEmfAddFactor:      'Add New Factor',
    kEmfActivate:       'Activate Factor',
    kEmfEditDraft:      'Edit Draft',
    kEmfEditActive:     'Edit Active (Restate)',
    kEmfEditLocked:     'Edit Locked (Restate)',
    kEmfDeleteDraft:    'Delete Draft',
    kEmfDeleteActive:   'Delete Active',
    kEmfDeleteLocked:   'Delete Locked',
    kEmfViewAuditLog:   'View Audit Log',
  };

  /// Returns the action permission key for storage: e.g. `emission_factor_mgmt.add`
  static String actionKey(String moduleKey, String action) => '$moduleKey.$action';

  /// Returns the module key from an action key, e.g. `emission_factor_mgmt.add` → `emission_factor_mgmt`
  static String? moduleFromActionKey(String key) {
    final dot = key.indexOf('.');
    return dot == -1 ? null : key.substring(0, dot);
  }

  /// Default action keys for a module when first enabled (all actions the module supports).
  static List<String> defaultActionsFor(String moduleKey) {
    return (moduleActions[moduleKey] ?? ['view'])
        .map((a) => actionKey(moduleKey, a))
        .toList();
  }

  /// Given a flat list of accessible keys (module keys + action keys),
  /// check if user can perform [action] on [moduleKey].
  static bool canPerformActionFromList(List<String> keys, String moduleKey, String action) {
    return keys.contains(actionKey(moduleKey, action));
  }

  /// Check if the currently signed-in user (via dynamic modules) can perform
  /// [action] on [moduleKey]. Super Admin always returns true.
  static bool canAction(String role, String moduleKey, String action) {
    if (normalizeRole(role) == superAdmin) return true;
    if (!_hasDynamicModules) return false;
    return _dynamicModules.contains(actionKey(moduleKey, action));
  }

  // ── Permission matrix (broad categories — used as fallback) ───────────────
  static const Map<String, Set<String>> _permissions = {
    superAdmin: {
      kModuleDashboards,
      kModuleAlarms,
      kModuleDeviceSetup,
      kModuleTariffConfig,
      kModuleViewTariffs,
      kModuleUserMgmt,
      kModuleAuditLogs,
      kModuleSettings,
      kModuleReports,
    },
    admin: {
      kModuleDashboards,
      kModuleAlarms,
      kModuleDeviceSetup,
      kModuleTariffConfig,
      kModuleViewTariffs,
      kModuleUserMgmt,
      kModuleAuditLogs,
      kModuleSettings,
      kModuleReports,
    },
    manager: {
      kModuleDashboards,
      kModuleAlarms,
      kModuleDeviceSetup,
      kModuleTariffConfig,
      kModuleViewTariffs,
      kModuleUserMgmt,
      kModuleAuditLogs,
      kModuleReports,
    },
    engineer: {
      kModuleDashboards,
      kModuleAlarms,
      kModuleDeviceSetup,
      kModuleViewTariffs,
    },
    operator_: {
      kModuleDashboards,
      kModuleAlarms,
    },
    viewer: {
      kModuleDashboards,
    },
  };

  // ── Granular default modules per role ──────────────────────────────────────
  static const Map<String, Set<String>> _granularDefaults = {
    superAdmin: {
      kModuleEquipmentOverview,
      kModuleEquipmentDetails,
      kModuleProductionLineKpi,
      kModuleMachineKpi,
      kModuleEnergyOverview,
      kModuleEnergyComparison,
      kModuleEnergyDetails,
      kModuleCarbonEmission,
      kModuleAirCompressorMonitoring,
      kModuleEmissionFactorMgmt,
      kModulePfMonitoring,
      kModuleMaxDemand,
      kModuleMdPrediction,
      kModuleKwhTone,
      kModuleSecComparison,
      kModuleProductionOutputLog,
      kModuleTnbBilling,
      kModuleKanbanDashboard,
      kModuleWorkOrderOverview,
      kModuleWorkOrderReport,
      kModuleProductionCalendar,
      kModuleProductionTask,
      kModuleEquipStatusData,
      kModuleEquipDataLogger,
      kModuleEquipAlarmData,
      kModuleOeeData,
      kModuleEnergyDataLogger1,
      kModuleEnergyDataLogger2,
      kModuleEnergyVsWorkOrder,
      kModuleEquipEnergyData,
      kModuleReports,
      kModuleDeviceSetup,
      kModuleDeviceDiscovery,
      kModuleDeviceLiveInsight,
      kModuleSettings,
      kModuleUserMgmt,
      kModuleTariffConfig,
      kModuleGfsPlant,
      kModuleGfsProductionArea,
      kModuleGfsProductionLine,
      kModuleGfsEquipment,
      kModuleGfsProcess,
      kModuleGfsProduct,
      kModuleGfsProductProcessRouting,
      kModuleGfsInstrumentDevices,
      kModuleGfsParameterSetting,
      kModuleGfsAlarm,
      kModuleGfsShift,
      kModuleGfsShiftCalendar,
      kModuleGfsDowntimeCalendar,
      kModuleGfsAbnormalReason,
      kModuleGfsDeviceType,
      kModuleGfsEquipmentCategory,
    },
    admin: {
      kModuleEquipmentOverview,
      kModuleEquipmentDetails,
      kModuleProductionLineKpi,
      kModuleMachineKpi,
      kModuleEnergyOverview,
      kModuleEnergyComparison,
      kModuleEnergyDetails,
      kModuleCarbonEmission,
      kModuleAirCompressorMonitoring,
      kModuleEmissionFactorMgmt,
      kModulePfMonitoring,
      kModuleMaxDemand,
      kModuleMdPrediction,
      kModuleKwhTone,
      kModuleSecComparison,
      kModuleProductionOutputLog,
      kModuleTnbBilling,
      kModuleKanbanDashboard,
      kModuleWorkOrderOverview,
      kModuleWorkOrderReport,
      kModuleProductionCalendar,
      kModuleProductionTask,
      kModuleEquipStatusData,
      kModuleEquipDataLogger,
      kModuleEquipAlarmData,
      kModuleOeeData,
      kModuleEnergyDataLogger1,
      kModuleEnergyDataLogger2,
      kModuleEnergyVsWorkOrder,
      kModuleEquipEnergyData,
      kModuleReports,
      kModuleDeviceSetup,
      kModuleDeviceDiscovery,
      kModuleDeviceLiveInsight,
      kModuleSettings,
      kModuleUserMgmt,
      kModuleTariffConfig,
      kModuleGfsPlant,
      kModuleGfsProductionArea,
      kModuleGfsProductionLine,
      kModuleGfsEquipment,
      kModuleGfsProcess,
      kModuleGfsProduct,
      kModuleGfsProductProcessRouting,
      kModuleGfsInstrumentDevices,
      kModuleGfsParameterSetting,
      kModuleGfsAlarm,
      kModuleGfsShift,
      kModuleGfsShiftCalendar,
      kModuleGfsDowntimeCalendar,
      kModuleGfsAbnormalReason,
      kModuleGfsDeviceType,
      kModuleGfsEquipmentCategory,
    },
    manager: {
      kModuleEquipmentOverview,
      kModuleEquipmentDetails,
      kModuleProductionLineKpi,
      kModuleMachineKpi,
      kModuleEnergyOverview,
      kModuleEnergyComparison,
      kModuleEnergyDetails,
      kModuleCarbonEmission,
      kModuleAirCompressorMonitoring,
      kModulePfMonitoring,
      kModuleMaxDemand,
      kModuleMdPrediction,
      kModuleKwhTone,
      kModuleSecComparison,
      kModuleProductionOutputLog,
      kModuleTnbBilling,
      kModuleKanbanDashboard,
      kModuleWorkOrderOverview,
      kModuleWorkOrderReport,
      kModuleProductionCalendar,
      kModuleProductionTask,
      kModuleEquipStatusData,
      kModuleEquipDataLogger,
      kModuleEquipAlarmData,
      kModuleOeeData,
      kModuleEnergyDataLogger1,
      kModuleEnergyDataLogger2,
      kModuleEnergyVsWorkOrder,
      kModuleEquipEnergyData,
      kModuleReports,
      kModuleSettings,
      kModuleUserMgmt,
      kModuleTariffConfig,
    },
    engineer: {
      kModuleEquipmentOverview,
      kModuleEquipmentDetails,
      kModuleProductionLineKpi,
      kModuleMachineKpi,
      kModuleEnergyOverview,
      kModuleEnergyComparison,
      kModuleEnergyDetails,
      kModuleCarbonEmission,
      kModuleAirCompressorMonitoring,
      kModulePfMonitoring,
      kModuleMaxDemand,
      kModuleMdPrediction,
      kModuleKwhTone,
      kModuleSecComparison,
      kModuleProductionOutputLog,
      kModuleEquipStatusData,
      kModuleEquipDataLogger,
      kModuleEquipAlarmData,
      kModuleOeeData,
      kModuleEnergyDataLogger1,
      kModuleEnergyDataLogger2,
      kModuleEnergyVsWorkOrder,
      kModuleEquipEnergyData,
    },
    operator_: {
      kModuleEquipmentOverview,
      kModuleEquipmentDetails,
      kModuleEnergyOverview,
      kModuleEnergyDetails,
    },
    viewer: {
      kModuleEquipmentOverview,
      kModuleEnergyOverview,
    },
  };

  // ── Read-only modules per role ─────────────────────────────────────────────
  static const Map<String, Set<String>> _readOnly = {
    operator_: {kModuleDashboards, kModuleAlarms},
    engineer: {kModuleViewTariffs},
    viewer: {kModuleDashboards},
  };

  // ── Dynamic permissions (loaded from Firestore roles collection) ──────────
  static bool _hasDynamicModules = false;
  static List<String> _dynamicModules = [];
  static List<String> _dynamicSubModules = [];

  static void setDynamicModules(List<String> modules, List<String> subModules) {
    _hasDynamicModules = true;
    _dynamicModules = modules;
    _dynamicSubModules = subModules;
  }

  /// Whether dynamic modules have been explicitly loaded from Firestore.
  static bool get hasDynamicModules => _hasDynamicModules;

  static void clearDynamicModules() {
    _hasDynamicModules = false;
    _dynamicModules = [];
    _dynamicSubModules = [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Custom Roles — loaded from Firestore `custom_roles` collection
  // ═══════════════════════════════════════════════════════════════════════════

  /// Each custom role: { name, modules, subModules, canManageUsers, createdBy }
  static List<Map<String, dynamic>> _customRoles = [];

  /// Register custom roles loaded from Firestore.
  static void setCustomRoles(List<Map<String, dynamic>> roles) {
    _customRoles = roles;
  }

  /// Get all custom role definitions.
  static List<Map<String, dynamic>> get customRoles => List.unmodifiable(_customRoles);

  /// Get all custom role names.
  static List<String> get customRoleNames => _customRoles.map((r) => r['name'] as String).toList();

  /// Check if a role name is a custom role.
  static bool isCustomRole(String role) => _customRoles.any((r) => r['name'] == role);

  /// Get a custom role definition by name (or null).
  static Map<String, dynamic>? getCustomRole(String name) {
    try {
      return _customRoles.firstWhere((r) => r['name'] == name);
    } catch (_) {
      return null;
    }
  }

  /// Get all role names (built-in + custom).
  static List<String> get allRoleNames => [...builtInRoles, ...customRoleNames];

  // ── API ────────────────────────────────────────────────────────────────────

  /// Whether [role] has any access (view or edit) to [module].
  /// When dynamic modules are loaded (even if empty), strictly uses them.
  /// Only falls back to role defaults before dynamic modules are loaded.
  static bool canAccess(String? role, String module) {
    if (role == null || role.isEmpty) return false;
    final normalized = normalizeRole(role);
    // Super Admin always has full access to everything
    if (normalized == superAdmin) return true;

    // Roles no longer restrict access by themselves — every non-Super-Admin
    // user must be explicitly assigned modules by an admin. The assignment
    // is delivered via dynamic modules (loaded from roles/{uid} in Firestore)
    // or, for custom roles, via the role definition itself.
    if (_hasDynamicModules) return _dynamicModules.contains(module);

    // Custom roles still ship their own module list.
    final custom = getCustomRole(normalized);
    if (custom != null) {
      final modules = (custom['modules'] as List<dynamic>?)?.cast<String>() ?? [];
      return modules.contains(module);
    }

    // No assignment loaded yet → no access. The admin must assign first.
    return false;
  }

  static String normalizeRole(String role) {
    if (_permissions.containsKey(role)) return role;
    // Check if it's a known custom role name (exact match)
    if (isCustomRole(role)) return role;
    final check = role.trim().toLowerCase();
    if (check == 'super admin' || check == 'superadmin') return superAdmin;
    if (check == 'admin') return admin;
    if (check == 'manager') return manager;
    if (check == 'engineer') return engineer;
    if (check == 'operator') return operator_;
    if (check == 'viewer') return viewer;
    return role;
  }

  /// Whether [role] has EDIT (not just read-only) access to [module].
  static bool canEdit(String role, String module) {
    if (!canAccess(role, module)) return false;
    if (_hasDynamicModules) {
      return !(_dynamicSubModules.contains('readonly_$module'));
    }
    final custom = getCustomRole(normalizeRole(role));
    if (custom != null) {
      final sub = (custom['subModules'] as List<dynamic>?)?.cast<String>() ?? [];
      return !(sub.contains('readonly_$module'));
    }
    return !(_readOnly[normalizeRole(role)]?.contains(module) ?? false);
  }

  static bool canManageAdmins(String role) => normalizeRole(role) == superAdmin;

  static bool canRegisterUsers(String role) {
    final n = normalizeRole(role);
    if (n == superAdmin || n == admin || n == manager) return true;
    // Custom roles can also register users if enabled
    final custom = getCustomRole(n);
    if (custom != null) return custom['canManageUsers'] == true;
    return false;
  }

  /// Default accessible modules for a role (broad + granular combined).
  static List<String> defaultModules(String role) {
    final n = normalizeRole(role);
    // Check custom roles first
    final custom = getCustomRole(n);
    if (custom != null) {
      return (custom['modules'] as List<dynamic>?)?.cast<String>() ?? [];
    }
    final broad = _permissions[n]?.toList() ?? [];
    final granular = _granularDefaults[n]?.toList() ?? [];
    return {...broad, ...granular}.toList();
  }

  /// Default granular modules only (for the toggle UI).
  static List<String> defaultGranularModules(String role) {
    final n = normalizeRole(role);
    final custom = getCustomRole(n);
    if (custom != null) {
      // Custom roles store granular modules directly
      return (custom['modules'] as List<dynamic>?)?.cast<String>().where((m) => allModuleKeys.contains(m)).toList() ?? [];
    }
    return _granularDefaults[n]?.toList() ?? [];
  }

  static List<String> defaultSubModules(String role) {
    final n = normalizeRole(role);
    final custom = getCustomRole(n);
    if (custom != null) {
      return (custom['subModules'] as List<dynamic>?)?.cast<String>() ?? [];
    }
    return _readOnly[n]?.map((m) => 'readonly_$m').toList() ?? [];
  }

  /// All roles the current [role] is allowed to assign to other users.
  /// Includes both built-in and custom roles.
  static List<String> assignableRoles(String role) {
    final n = normalizeRole(role);
    List<String> base;
    switch (n) {
      case superAdmin:
        base = [superAdmin, admin, manager, engineer, operator_, viewer];
        break;
      case admin:
        base = [manager, engineer, operator_, viewer];
        break;
      case manager:
        base = [engineer, operator_, viewer];
        break;
      default:
        base = [];
    }
    // Super Admin and Admin can also assign custom roles
    if (n == superAdmin || n == admin) {
      base.addAll(customRoleNames);
    }
    return base;
  }

  static List<String> permissionLabels(String role) {
    final n = normalizeRole(role);
    final custom = getCustomRole(n);
    if (custom != null) {
      final modules = (custom['modules'] as List<dynamic>?)?.cast<String>() ?? [];
      if (modules.isEmpty) return ['No permissions assigned'];
      // Show first few module labels
      final labels = modules.take(4).map((m) => moduleLabels[m] ?? m).toList();
      if (modules.length > 4) labels.add('+${modules.length - 4} more');
      return labels;
    }
    switch (n) {
      case superAdmin:
        return ['Full System Access', 'All Modules', 'User Management', 'System Config'];
      case admin:
        return ['All Modules', 'User Management', 'Edit Rights'];
      case manager:
        return ['Dashboards', 'Alarms', 'Device Setup', 'Tariff Config', 'User Management', 'Audit Logs'];
      case engineer:
        return ['Dashboards', 'Alarm Limits', 'Device Setup', 'View Tariffs'];
      case operator_:
        return ['Read-only Dashboards', 'View Alarms'];
      default:
        return [];
    }
  }
}
