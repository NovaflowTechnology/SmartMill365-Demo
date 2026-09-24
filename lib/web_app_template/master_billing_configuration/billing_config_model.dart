// billing_config_model.dart

enum VoltageCategory { lv, mv, hv }

class TariffConfig {
  // Grid Infrastructure
  final String mdCapacityCharge;
  final String mdCapacityUnit;
  final String mdNetworkCharge;
  final String mdNetworkUnit;
  final String retailCharge;

  // Variable Energy
  final String baseEnergyRate;
  final String currentAFA;
  final String minMonthlyCharge;

  // PF Surcharge
  final String targetThreshold;
  final String tier1Rate;
  final String tier2Trigger;
  final String tier2Rate;

  // Statutory Levies
  final String kwtbb;
  final String sst;

  // Metadata
  final String cycleEffectiveDate;

  const TariffConfig({
    required this.mdCapacityCharge,
    required this.mdCapacityUnit,
    required this.mdNetworkCharge,
    required this.mdNetworkUnit,
    required this.retailCharge,
    required this.baseEnergyRate,
    required this.currentAFA,
    required this.minMonthlyCharge,
    required this.targetThreshold,
    required this.tier1Rate,
    required this.tier2Trigger,
    required this.tier2Rate,
    required this.kwtbb,
    required this.sst,
    required this.cycleEffectiveDate,
  });
}

const tariffDefaults = <VoltageCategory, TariffConfig>{
  VoltageCategory.lv: TariffConfig(
    mdCapacityCharge: '0,0883',
    mdCapacityUnit: 'sen/kWh',
    mdNetworkCharge: '0,1482',
    mdNetworkUnit: 'sen/kWh',
    retailCharge: '20',
    baseEnergyRate: '0,2703',
    currentAFA: '0,05',
    minMonthlyCharge: '3',
    targetThreshold: '0,85',
    tier1Rate: '1,5',
    tier2Trigger: '0,75',
    tier2Rate: '3',
    kwtbb: '1,6',
    sst: '8',
    cycleEffectiveDate: '01/01/2026',
  ),
  VoltageCategory.mv: TariffConfig(
    mdCapacityCharge: '29,43',
    mdCapacityUnit: 'RM/kW',
    mdNetworkCharge: '59,84',
    mdNetworkUnit: 'RM/kW',
    retailCharge: '200',
    baseEnergyRate: '0,2983',
    currentAFA: '0,05',
    minMonthlyCharge: '600',
    targetThreshold: '0,85',
    tier1Rate: '1,5',
    tier2Trigger: '0,75',
    tier2Rate: '3',
    kwtbb: '1,6',
    sst: '8',
    cycleEffectiveDate: '01/01/2026',
  ),
  VoltageCategory.hv: TariffConfig(
    mdCapacityCharge: '22,10',
    mdCapacityUnit: 'RM/kW',
    mdNetworkCharge: '45,60',
    mdNetworkUnit: 'RM/kW',
    retailCharge: '500',
    baseEnergyRate: '0,2650',
    currentAFA: '0,05',
    minMonthlyCharge: '1500',
    targetThreshold: '0,85',
    tier1Rate: '1,5',
    tier2Trigger: '0,75',
    tier2Rate: '3',
    kwtbb: '1,6',
    sst: '8',
    cycleEffectiveDate: '01/01/2026',
  ),
};

extension VoltageCategoryLabel on VoltageCategory {
  String get label {
    switch (this) {
      case VoltageCategory.lv: return 'Low Voltage (LV)';
      case VoltageCategory.mv: return 'Medium Voltage (MV)';
      case VoltageCategory.hv: return 'High Voltage (HV)';
    }
  }
}