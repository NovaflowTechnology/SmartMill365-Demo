import 'tnb_meter_dashboard_config.dart';

class TnbMeter {
  final String id;
  final String plantId;
  final String meterCode;
  final String meterLabel;
  final String tnbAccountNo;
  final String influxDbTag;
  final String solarDeviceId;
  final String tariffCategoryId;
  final String tariffType;
  final double contractMdKw;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final List<String> boundAreaIds;
  final bool isActive;
  final TnbMeterDashboardConfig dashboardConfig;

  const TnbMeter({
    required this.id,
    this.plantId = '',
    required this.meterCode,
    required this.meterLabel,
    this.tnbAccountNo = '',
    this.influxDbTag = '',
    this.solarDeviceId = '',
    this.tariffCategoryId = '',
    this.tariffType = '',
    this.contractMdKw = 0,
    required this.effectiveFrom,
    this.effectiveTo,
    this.boundAreaIds = const [],
    this.isActive = true,
    this.dashboardConfig = const TnbMeterDashboardConfig(distributionBuckets: TnbMeterDashboardConfig.defaultBuckets),
  });

  factory TnbMeter.fromJson(Map<String, dynamic> json) {
    return TnbMeter(
      id: json['id']?.toString() ?? '',
      plantId: json['plantId']?.toString() ?? json['factory_id']?.toString() ?? '',
      meterCode: json['meterCode']?.toString() ?? '',
      meterLabel: json['meterLabel']?.toString() ?? '',
      tnbAccountNo: json['tnbAccountNo']?.toString() ?? '',
      influxDbTag: json['influxDbTag']?.toString() ?? '',
      solarDeviceId: json['solarDeviceId']?.toString() ?? '',
      tariffCategoryId: json['tariffCategoryId']?.toString() ?? '',
      tariffType: json['tariffType']?.toString() ?? '',
      contractMdKw: (json['contractMdKw'] as num?)?.toDouble() ?? 0,
      effectiveFrom: json['effectiveFrom'] != null
          ? DateTime.tryParse(json['effectiveFrom'].toString()) ?? DateTime.now()
          : DateTime.now(),
      effectiveTo: json['effectiveTo'] != null && json['effectiveTo'].toString().isNotEmpty
          ? DateTime.tryParse(json['effectiveTo'].toString())
          : null,
      boundAreaIds: (json['boundAreaIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
      dashboardConfig: TnbMeterDashboardConfig.fromJson(json['dashboardConfig'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'plantId': plantId,
        'meterCode': meterCode,
        'meterLabel': meterLabel,
        'tnbAccountNo': tnbAccountNo,
        'influxDbTag': influxDbTag,
        'solarDeviceId': solarDeviceId,
        'tariffCategoryId': tariffCategoryId,
        'tariffType': tariffType,
        'contractMdKw': contractMdKw,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        if (effectiveTo != null) 'effectiveTo': effectiveTo!.toIso8601String(),
        'boundAreaIds': boundAreaIds,
        'isActive': isActive,
        'dashboardConfig': dashboardConfig.toJson(),
      };

  TnbMeter copyWith({
    String? id,
    String? plantId,
    String? meterCode,
    String? meterLabel,
    String? tnbAccountNo,
    String? influxDbTag,
    String? solarDeviceId,
    String? tariffCategoryId,
    String? tariffType,
    double? contractMdKw,
    DateTime? effectiveFrom,
    DateTime? Function()? effectiveTo,
    List<String>? boundAreaIds,
    bool? isActive,
    TnbMeterDashboardConfig? dashboardConfig,
  }) {
    return TnbMeter(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      meterCode: meterCode ?? this.meterCode,
      meterLabel: meterLabel ?? this.meterLabel,
      tnbAccountNo: tnbAccountNo ?? this.tnbAccountNo,
      influxDbTag: influxDbTag ?? this.influxDbTag,
      solarDeviceId: solarDeviceId ?? this.solarDeviceId,
      tariffCategoryId: tariffCategoryId ?? this.tariffCategoryId,
      tariffType: tariffType ?? this.tariffType,
      contractMdKw: contractMdKw ?? this.contractMdKw,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo != null ? effectiveTo() : this.effectiveTo,
      boundAreaIds: boundAreaIds ?? this.boundAreaIds,
      isActive: isActive ?? this.isActive,
      dashboardConfig: dashboardConfig ?? this.dashboardConfig,
    );
  }
}

class PlantGroup {
  final String plantId;
  final String plantName;
  final List<TnbMeter> meters;

  const PlantGroup({
    required this.plantId,
    required this.plantName,
    required this.meters,
  });

  int get meterCount => meters.length;
  double get totalContractKw => meters.fold(0.0, (s, m) => s + m.contractMdKw);
}
