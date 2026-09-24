// lib/web_app_template/master_facility_setting/models/facility_data.dart

class FacilityData {
  final String? id;
  final String plant;
  final String factory;
  final String zone;
  final String productionArea;
  final String equipmentType;
  final String equipmentNameId;
  final String meterName;
  final String meterId;
  final String gatewayId;
  final String status;
  final String gridType;
  final String maintenanceDate;
  final String lastMaintenanceDate;
  final String nextMaintenanceDate;
  final String registrationDate;
  final String registrationTime;
  final String impactCategory;
  // MySQL enrichment fields — auto-populated from Device Discovery, never overwrite manual org fields
  final String siteId;
  final String machineId;
  final String machineName;
  final String lineId;
  final String lineName;
  final String zoneId;
  final String zoneName;
  final String parentId;
  final String parentName;
  // Discovery-driven connectivity fields — separate from the manual `status`
  // (Active/Maintenance/etc.) field. Device Discovery is allowed to update
  // these on every scan, including marking a device Offline when it's no
  // longer detected, without ever touching the manual status or org fields.
  final String onlineStatus;
  final String lastSeen;
  // Per-equipment energy target — sourced from Equipment Settings (energy
  // module form field "Target kWh / Tonne"), not the fleet-wide manual
  // threshold set in the kWh/Tonne page's Thresholds dialog.
  final double targetKwhPerTonne;
  // Analytics inclusion flags — toggled via checkboxes in Master Facility
  // Setting's table, independently control whether this device feeds each
  // downstream module. Defaults mirror the module's typical coverage: most
  // devices feed PF/Carbon out of the box, MD ranking is opt-in per device.
  final bool includePfAnalytics;
  final bool includeMdRanking;
  final bool includeCarbonCalc;

  const FacilityData({
    this.id,
    required this.plant,
    required this.factory,
    required this.zone,
    required this.productionArea,
    required this.equipmentType,
    required this.equipmentNameId,
    required this.meterName,
    required this.meterId,
    required this.gatewayId,
    required this.status,
    required this.gridType,
    required this.maintenanceDate,
    required this.lastMaintenanceDate,
    required this.nextMaintenanceDate,
    required this.registrationDate,
    this.registrationTime = '',
    this.impactCategory = 'PRODUCTION',
    this.siteId = '',
    this.machineId = '',
    this.machineName = '',
    this.lineId = '',
    this.lineName = '',
    this.zoneId = '',
    this.zoneName = '',
    this.parentId = '',
    this.parentName = '',
    this.onlineStatus = '',
    this.lastSeen = '',
    this.targetKwhPerTonne = 0.0,
    this.includePfAnalytics = true,
    this.includeMdRanking = false,
    this.includeCarbonCalc = true,
  });

  static bool _parseBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  factory FacilityData.fromMap(String id, Map<String, dynamic> map) {
    return FacilityData(
      id: id,
      plant: map['plant'] ?? '',
      factory: map['factory'] ?? '',
      zone: map['zone'] ?? '',
      productionArea: map['productionArea'] ?? '',
      equipmentType: map['equipmentType'] ?? '',
      equipmentNameId: map['equipmentNameId'] ?? '',
      meterName: map['meterName'] ?? '',
      meterId: map['meterId'] ?? '',
      gatewayId: map['gatewayId'] ?? '',
      status: map['status'] ?? '',
      gridType: map['gridType'] ?? '',
      maintenanceDate: map['maintenanceDate'] ?? '',
      lastMaintenanceDate: map['lastMaintenanceDate'] ?? '',
      nextMaintenanceDate: map['nextMaintenanceDate'] ?? '',
      registrationDate: map['registrationDate'] ?? '',
      registrationTime: map['registrationTime'] ?? '',
      impactCategory: map['impactCategory'] ?? 'PRODUCTION',
      siteId: map['siteId'] ?? '',
      machineId: map['machineId'] ?? '',
      machineName: map['machineName'] ?? '',
      lineId: map['lineId'] ?? '',
      lineName: map['lineName'] ?? '',
      zoneId: map['zoneId'] ?? '',
      zoneName: map['zoneName'] ?? '',
      parentId: map['parentId'] ?? '',
      parentName: map['parentName'] ?? '',
      onlineStatus: map['onlineStatus'] ?? '',
      lastSeen: map['lastSeen'] ?? '',
      includePfAnalytics: _parseBool(map['includePfAnalytics'], true),
      includeMdRanking: _parseBool(map['includeMdRanking'], false),
      includeCarbonCalc: _parseBool(map['includeCarbonCalc'], true),
    );
  }

  FacilityData copyWith({
    double? targetKwhPerTonne,
    bool? includePfAnalytics,
    bool? includeMdRanking,
    bool? includeCarbonCalc,
  }) => FacilityData(
        id: id,
        plant: plant,
        factory: factory,
        zone: zone,
        productionArea: productionArea,
        equipmentType: equipmentType,
        equipmentNameId: equipmentNameId,
        meterName: meterName,
        meterId: meterId,
        gatewayId: gatewayId,
        status: status,
        gridType: gridType,
        maintenanceDate: maintenanceDate,
        lastMaintenanceDate: lastMaintenanceDate,
        nextMaintenanceDate: nextMaintenanceDate,
        registrationDate: registrationDate,
        registrationTime: registrationTime,
        impactCategory: impactCategory,
        siteId: siteId,
        machineId: machineId,
        machineName: machineName,
        lineId: lineId,
        lineName: lineName,
        zoneId: zoneId,
        zoneName: zoneName,
        parentId: parentId,
        parentName: parentName,
        onlineStatus: onlineStatus,
        lastSeen: lastSeen,
        targetKwhPerTonne: targetKwhPerTonne ?? this.targetKwhPerTonne,
        includePfAnalytics: includePfAnalytics ?? this.includePfAnalytics,
        includeMdRanking: includeMdRanking ?? this.includeMdRanking,
        includeCarbonCalc: includeCarbonCalc ?? this.includeCarbonCalc,
      );

  Map<String, dynamic> toMap() {
    return {
      'plant': plant,
      'factory': factory,
      'zone': zone,
      'productionArea': productionArea,
      'equipmentType': equipmentType,
      'equipmentNameId': equipmentNameId,
      'meterName': meterName,
      'meterId': meterId,
      'gatewayId': gatewayId,
      'status': status,
      'gridType': gridType,
      'maintenanceDate': maintenanceDate,
      'lastMaintenanceDate': lastMaintenanceDate,
      'nextMaintenanceDate': nextMaintenanceDate,
      'registrationDate': registrationDate,
      'registrationTime': registrationTime,
      'impactCategory': impactCategory,
      'siteId': siteId,
      'machineId': machineId,
      'machineName': machineName,
      'lineId': lineId,
      'lineName': lineName,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'parentId': parentId,
      'parentName': parentName,
      'onlineStatus': onlineStatus,
      'lastSeen': lastSeen,
      'includePfAnalytics': includePfAnalytics,
      'includeMdRanking': includeMdRanking,
      'includeCarbonCalc': includeCarbonCalc,
    };
  }
}