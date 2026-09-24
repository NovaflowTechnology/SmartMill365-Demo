/// The master lists a settlement is configured against.
///
/// Read-only copies of what General Factory Setting, TNB Meter Setting, Tariff
/// Category Setup and Master Facilities already hold. This module never writes
/// to any of them — a block, a meter or a tariff is created where it belongs,
/// and the settlement only points at it.
library;

import 'package:smartmachine365/web_app_template/general_factory_setting/tnb_meter/tnb_meter_models.dart';

class PlantRef {
  const PlantRef({required this.id, required this.name});

  final String id;
  final String name;
}

/// A meter registered in Master Facilities.
class DeviceRef {
  const DeviceRef({
    required this.id,
    this.name = '',
    this.plant = '',
    this.zone = '',
    this.type = '',
  });

  final String id;
  final String name;
  final String plant;
  final String zone;
  final String type;

  bool get isSolar => type.toLowerCase().contains('solar');

  String get label => name.isEmpty || name == id ? id : '$id · $name';
}

/// TNB rates for one tariff category and where they were found.
class TnbRates {
  const TnbRates({
    this.peak = 0,
    this.offPeak = 0,
    this.source = TnbRateSource.none,
  });

  final double peak;
  final double offPeak;
  final TnbRateSource source;

  bool get isKnown => peak > 0 || offPeak > 0;
}

enum TnbRateSource {
  /// The category's own billing config carries the rates.
  category,

  /// The category has none, so the shared electricity tariff Master Billing
  /// deploys — the same value Master Billing shows for every category — is used.
  electricityTariff,

  none,
}

class SettlementMasters {
  const SettlementMasters({
    this.plants = const [],
    this.meters = const [],
    this.categoryNames = const {},
    this.devices = const [],
  });

  final List<PlantRef> plants;
  final List<TnbMeter> meters;

  /// Tariff category id → name as written in Tariff Category Setup.
  final Map<String, String> categoryNames;
  final List<DeviceRef> devices;

  bool get isEmpty => plants.isEmpty && meters.isEmpty;

  PlantRef? plant(String id) {
    for (final p in plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  String plantName(String id) => plant(id)?.name ?? id;

  DeviceRef? device(String id) {
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }
}
