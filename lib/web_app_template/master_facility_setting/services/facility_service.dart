import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/services/scope_resolver.dart';
import 'package:smartmachine365/flutter_flow/nav/nav.dart';
import '../models/facility_data.dart';
import 'package:smartmachine365/web_app_template/real_time_data_config/services/device_config_service.dart';
import 'package:smartmachine365/web_app_template/real_time_data_config/services/influx_discovery_service.dart';
import 'package:smartmachine365/web_app_template/real_time_data_config/models/discovery_models.dart';

// ─────────────────────────────────────────────
// EquipmentItem — from /equipment API
// ─────────────────────────────────────────────

class EquipmentItem {
  final String id;
  final String equipmentId;
  final String name;
  final String workId;
  final String factoryId;
  final String productionArea; // → Zone (matches /productionAreas)
  final String factory;        // → Site / Plant (matches /factory)
  final String productionLine; // → Line / Prod. Area (matches /productionLines)
  final String deviceType;     // → Device Type
  final bool enableEnergy;     // → Energy module toggle (Equipment Settings)
  final double targetKwhPerTonne; // → Target kWh / Tonne (Equipment Settings, energy module)

  const EquipmentItem({
    required this.id,
    required this.equipmentId,
    required this.name,
    required this.workId,
    required this.factoryId,
    required this.productionArea,
    this.factory = '',
    this.productionLine = '',
    this.deviceType = '',
    this.enableEnergy = false,
    this.targetKwhPerTonne = 0.0,
  });

  factory EquipmentItem.fromMap(Map<String, dynamic> map) {
    return EquipmentItem(
      id:             map['id']?.toString() ?? '',
      equipmentId:    map['equipment_id']?.toString() ?? '',
      name:           map['name']?.toString() ?? '',
      workId:         map['work_id']?.toString() ?? '',
      factoryId:      map['factory_id']?.toString() ?? '',
      productionArea: map['productionArea']?.toString() ?? '',
      factory:        (map['factory'] ?? map['factory_id'])?.toString() ?? '',
      productionLine: (map['productionLine'] ?? map['production_line'])?.toString() ?? '',
      deviceType:     (map['device_type'] ?? map['equipment_type'] ?? map['type'])?.toString() ?? '',
      enableEnergy:   map['enableEnergy'] == true || map['enableEnergy']?.toString() == 'true',
      targetKwhPerTonne: double.tryParse(map['targetKwhPerTonne']?.toString() ?? '') ?? 0.0,
    );
  }

  /// Dropdown label: "PE120 (m19)"
  String get displayLabel =>
      equipmentId.isNotEmpty ? '$name ($equipmentId)' : name;
}

// ─────────────────────────────────────────────
// FacilityService
// ─────────────────────────────────────────────

class FacilityService {
  // Facilities are stored in the client's Firestore via ui7 (dataApiBaseSafe)
  // x-client-id header is automatically included via AppConfig.headers
  static String get baseUrl  => '${AppConfig.dataApiBaseSafe}/facilities';
  static String get _apiBase => AppConfig.dataApiBaseSafe;

  // ── Caches (same pattern as AddEquipmentDialog) ───────────────────────────
  static List<EquipmentItem>?       _equipmentCache;
  static List<Map<String, dynamic>>? _productionAreaCache;
  static List<Map<String, dynamic>>? _factoryCache;
  static List<Map<String, dynamic>>? _deviceTypeCache;
  static List<Map<String, dynamic>>? _productionLineCache;
  static int _docCounter = 0;


  // ═════════════════════════════════════════════════════════════════════════
  // DROPDOWN DATA — reuse same endpoints as AddEquipmentDialog
  // ═════════════════════════════════════════════════════════════════════════

  /// GET /equipment — same as AddEquipmentDialog uses for equipment list
  static Future<List<EquipmentItem>> getEquipments({
    bool forceRefresh = false,
  }) async {
    if (_equipmentCache != null && !forceRefresh) return _equipmentCache!;
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/equipment'),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _equipmentCache = data.map((e) => EquipmentItem.fromMap(e)).toList();
        return _equipmentCache!;
      }
      throw Exception('Failed to load equipment: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching equipment: $e');
    }
  }

  /// GET /productionAreas — same as AddEquipmentDialog.fetchProductionArea()
  /// Returns list of {id, name}
  /// [bypassScope] returns the complete master regardless of who is signed in.
  /// Only [ScopeResolver] and the screen that grants access use it: the resolver
  /// needs every plant to map ids to names, and an admin has to be able to grant
  /// a plant they cannot themselves open.
  static Future<List<Map<String, dynamic>>> getProductionAreas({
    bool forceRefresh = false,
    bool bypassScope = false,
  }) async {
    if (_productionAreaCache != null && !forceRefresh) {
      return bypassScope
          ? _productionAreaCache!
          : await _scopeAreas(_productionAreaCache!);
    }
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/productionAreas'),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _productionAreaCache = [
          {'id': '0', 'name': 'Not Assigned'},
          ...data.map((e) => Map<String, dynamic>.from(e)),
        ];
        return bypassScope
            ? _productionAreaCache!
            : await _scopeAreas(_productionAreaCache!);
      }
      throw Exception('Failed to load production areas: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching production areas: $e');
    }
  }

  /// GET /factory — same as AddEquipmentDialog.fetchFactory()
  /// Returns list of {id, name}
  /// See [getProductionAreas] for what [bypassScope] is for.
  static Future<List<Map<String, dynamic>>> getFactories({
    bool forceRefresh = false,
    bool bypassScope = false,
  }) async {
    if (_factoryCache != null && !forceRefresh) {
      return bypassScope ? _factoryCache! : await _scopePlants(_factoryCache!);
    }
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/factory'),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _factoryCache = [
          {'id': '0', 'name': 'Not Assigned'},
          ...data.map((e) => Map<String, dynamic>.from(e)),
        ];
        return bypassScope ? _factoryCache! : await _scopePlants(_factoryCache!);
      }
      throw Exception('Failed to load factories: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching factories: $e');
    }
  }

  /// GET /deviceTypes — returns list of {id, name}
  static Future<List<Map<String, dynamic>>> getDeviceTypes({
    bool forceRefresh = false,
  }) async {
    if (_deviceTypeCache != null && !forceRefresh) return _deviceTypeCache!;
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/deviceTypes'),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _deviceTypeCache = data.map((e) => Map<String, dynamic>.from(e)).toList();
        return _deviceTypeCache!;
      }
      throw Exception('Failed to load device types: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching device types: $e');
    }
  }

  /// GET /productionLines — same as ProductionLineSettingWidget
  /// Returns list of {id, name, productionArea, description}
  static Future<List<Map<String, dynamic>>> getProductionLines({
    bool forceRefresh = false,
  }) async {
    if (_productionLineCache != null && !forceRefresh) return _productionLineCache!;
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/productionLines'),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _productionLineCache = [
          {'id': '0', 'name': 'Not Assigned'},
          ...data.map((e) => Map<String, dynamic>.from(e)),
        ];
        return _productionLineCache!;
      }
      throw Exception('Failed to load production lines: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching production lines: $e');
    }
  }

  static List<FacilityData>?        _facilitiesCache;
  static DateTime?                  _facilitiesCacheTime;
  static const Duration             _facilitiesCacheTtl = Duration(minutes: 2);

  /// Clear all dropdown and facility caches
  static void clearDropdownCaches() {
    _equipmentCache       = null;
    _productionAreaCache  = null;
    _factoryCache         = null;
    _deviceTypeCache      = null;
    _productionLineCache  = null;
    clearFacilitiesCache();
  }

  static void clearFacilitiesCache() {
    _facilitiesCache     = null;
    _facilitiesCacheTime = null;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FACILITIES CRUD — cached
  // ═════════════════════════════════════════════════════════════════════════

  /// Narrows a facility list to what the signed-in user is allowed to see.
  ///
  /// This sits on [getFacilities] on purpose. Nearly thirty call sites across
  /// the dashboards load their devices through it, and a scope rule applied in
  /// thirty places is a rule that will disagree in one of them. Filtering once,
  /// here, means every module inherits the same answer.
  ///
  /// A user with no scope granted is unrestricted, so every account that
  /// predates this feature — and every Super Admin — sees exactly what it saw
  /// before. Only an account that has actually been given a scope is narrowed.
  ///
  /// The join is by name, because equipment records their plant and production
  /// area as free text rather than as ids. A record whose plant is blank stays
  /// visible: those are incomplete rows, and hiding them would look like data
  /// loss. The gap is real and belongs to the API, which still serves
  /// everything to anyone who asks — this limits what the app shows, not what
  /// the server will give.
  static Future<List<FacilityData>> _applyScope(
      List<FacilityData> facilities) async {
    final scope = AppStateNotifier.instance.dataScope;
    if (scope.isUnrestricted) return facilities;

    // Needed to turn the granted ids into the names the equipment carries.
    // Cached after the first call, so this costs nothing on later loads.
    try {
      await ScopeResolver.load();
    } catch (_) {
      // Without the masters the ids cannot be mapped to names. Returning the
      // full list would widen access, so return nothing and let the module
      // show its usual empty state.
      return const [];
    }

    return facilities
        .where((f) => ScopeResolver.allowsFacilityNames(
              scope,
              plantName: f.plant,
              areaName: f.zone,
            ))
        .toList();
  }

  /// Narrows the plant master to the plants this user may see.
  ///
  /// Sits here for the same reason [_applyScope] does: every screen with a
  /// Plant dropdown builds it from this one call, so filtering once keeps them
  /// all telling the same story. The "Not Assigned" placeholder is always kept
  /// — it is how a screen says "no plant", not a plant anyone is granted.
  static Future<List<Map<String, dynamic>>> _scopePlants(
      List<Map<String, dynamic>> plants) async {
    final scope = AppStateNotifier.instance.dataScope;
    if (scope.isUnrestricted) return plants;
    return plants
        .where((p) =>
            p['id']?.toString() == '0' ||
            scope.allowsPlant(p['id']?.toString() ?? ''))
        .toList();
  }

  /// Narrows the production-area master the same way.
  static Future<List<Map<String, dynamic>>> _scopeAreas(
      List<Map<String, dynamic>> areas) async {
    final scope = AppStateNotifier.instance.dataScope;
    if (scope.isUnrestricted) return areas;
    try {
      await ScopeResolver.load();
    } catch (_) {
      return const [];
    }
    return areas.where((a) {
      final id = a['id']?.toString() ?? '';
      if (id == '0') return true;
      return scope.allowsArea(id,
          parentPlantId: ScopeResolver.parentPlantOf(id));
    }).toList();
  }

  /// The meter ids this user may query, or null when they may query anything.
  ///
  /// For screens that talk to the telemetry endpoints directly instead of
  /// going through the facility list. Those endpoints answer for any device id
  /// they are given, so a screen that builds its own query has to narrow it
  /// here or it will read meters the user is not entitled to.
  static Future<Set<String>?> allowedDeviceIds() async {
    if (AppStateNotifier.instance.dataScope.isUnrestricted) return null;
    try {
      final facilities = await getFacilities();
      return facilities
          .map((f) => f.meterId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      // Unknown is treated as "nothing", so a failure narrows rather than opens.
      return <String>{};
    }
  }

  static Future<List<FacilityData>> getFacilities({bool forceRefresh = false}) async {
    if (!AppConfig.hasActiveClient) return [];
    if (!forceRefresh &&
        _facilitiesCache != null &&
        _facilitiesCacheTime != null &&
        DateTime.now().difference(_facilitiesCacheTime!) < _facilitiesCacheTtl) {
      return _applyScope(_facilitiesCache!);
    }
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // The cache keeps the unfiltered list so a scope change takes effect
        // without a refetch, and so the filter is never applied twice.
        _facilitiesCache = data
            .map((item) => FacilityData.fromMap(item['id'] ?? '', item))
            .toList();
        _facilitiesCacheTime = DateTime.now();
        return _applyScope(_facilitiesCache!);
      }
      throw Exception('Failed to load facilities: ${response.body}');
    } catch (e) {
      if (_facilitiesCache != null) return _applyScope(_facilitiesCache!);
      throw Exception('Error fetching facilities: $e');
    }
  }

  static Future<FacilityData?> getFacilityById(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _facilitiesCache != null &&
        _facilitiesCacheTime != null &&
        DateTime.now().difference(_facilitiesCacheTime!) < _facilitiesCacheTtl) {
      final match = _facilitiesCache!.where((f) => f.id == id || f.meterId == id).firstOrNull;
      if (match != null) return match;
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FacilityData.fromMap(data['id'] ?? id, data);
      } else if (response.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to load facility: ${response.body}');
    } catch (e) {
      if (_facilitiesCache != null) {
        final match = _facilitiesCache!.where((f) => f.id == id || f.meterId == id).firstOrNull;
        if (match != null) return match;
      }
      throw Exception('Error fetching facility: $e');
    }
  }

  static Future<bool> addFacility(FacilityData facility) async {
    try {
      final docId = '${DateTime.now().microsecondsSinceEpoch}_${_docCounter++}';
      final payload = facility.toMap();
      payload['id'] = docId;
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: AppConfig.headers,
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        clearFacilitiesCache();
        return true;
      }
      throw Exception('Failed to add facility: ${response.body}');
    } catch (e) {
      throw Exception('Error adding facility: $e');
    }
  }

  static Future<bool> updateFacility(String id, FacilityData facility) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: AppConfig.headers,
        body: json.encode(facility.toMap()),
      );
      if (response.statusCode == 200) {
        clearFacilitiesCache();
        return true;
      }
      throw Exception('Failed to update facility: ${response.body}');
    } catch (e) {
      throw Exception('Error updating facility: $e');
    }
  }

  static Future<bool> patchFacility(String id, Map<String, dynamic> fields) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: AppConfig.headers,
        body: json.encode(fields),
      );
      if (response.statusCode == 200) {
        clearFacilitiesCache();
        return true;
      }
      throw Exception('Failed to patch facility: ${response.body}');
    } catch (e) {
      throw Exception('Error patching facility: $e');
    }
  }

  static Future<bool> deleteFacility(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: AppConfig.headers,
      );
      if (response.statusCode == 200 || response.statusCode == 404) {
        clearFacilitiesCache();
        return true;
      }
      throw Exception('Failed to delete facility: ${response.body}');
    } catch (e) {
      throw Exception('Error deleting facility: $e');
    }
  }

  static Future<int> deleteAllFacilities() async {
    final facilities = await getFacilities();
    int deleted = 0;
    for (final item in facilities) {
      final id = item.id?.trim() ?? '';
      if (id.isEmpty) continue;
      final ok = await deleteFacility(id);
      if (ok) deleted++;
    }
    return deleted;
  }

  static Future<Map<String, int>> deleteAllFacilitiesSummary() async {
    final facilities = await getFacilities();
    int deleted = 0;
    int failed = 0;
    const batchSize = 12;

    for (int i = 0; i < facilities.length; i += batchSize) {
      final batch = facilities.skip(i).take(batchSize).toList();
      final results = await Future.wait(batch.map((item) async {
        final id = item.id?.trim() ?? '';
        if (id.isEmpty) return false;
        try {
          return await deleteFacility(id);
        } catch (_) {
          return false;
        }
      }));
      for (final ok in results) {
        if (ok) {
          deleted++;
        } else {
          failed++;
        }
      }
    }

    return {'deleted': deleted, 'failed': failed};
  }

  static Future<Map<String, int>> seedFacilitiesFromEquipmentsTemplate() async {
    final equipments = await getEquipments(forceRefresh: true);
    final existing = await getFacilities();
    final factoryMap = await getFactories(forceRefresh: true);
    final areaMap = await getProductionAreas(forceRefresh: true);

    final factoryNameById = <String, String>{
      for (final item in factoryMap)
        item['id']?.toString() ?? '': item['name']?.toString() ?? '',
    };
    final areaNameById = <String, String>{
      for (final item in areaMap)
        item['id']?.toString() ?? '': item['name']?.toString() ?? '',
    };

    int deleted = 0;
    int failedDelete = 0;
    if (existing.isNotEmpty) {
      final summary = await deleteAllFacilitiesSummary();
      deleted = summary['deleted'] ?? 0;
      failedDelete = summary['failed'] ?? 0;
    }

    int created = 0;
    int failedCreate = 0;
    const batchSize = 10;

    for (int i = 0; i < equipments.length; i += batchSize) {
      final batch = equipments.skip(i).take(batchSize).toList();
      final results = await Future.wait(batch.map((equipment) async {
        final equipmentLabel = equipment.displayLabel.trim();
        final meterId = equipment.equipmentId.trim();
        final meterName = equipment.name.trim().isNotEmpty
            ? equipment.name.trim()
            : equipmentLabel;

        final factoryName = factoryNameById[equipment.factoryId]?.trim() ?? '';
        final productionAreaName =
            areaNameById[equipment.productionArea]?.trim() ?? '';

        final facility = FacilityData(
          plant: productionAreaName.isNotEmpty ? productionAreaName : 'Main Plant',
          factory: factoryName.isNotEmpty ? factoryName : 'Factory Undefined',
          zone: productionAreaName.isNotEmpty ? productionAreaName : 'Zone Undefined',
          productionArea:
              productionAreaName.isNotEmpty ? productionAreaName : 'Area Undefined',
          equipmentType:
              equipment.workId.trim().isNotEmpty ? equipment.workId.trim() : 'General',
          equipmentNameId:
              equipmentLabel.isNotEmpty ? equipmentLabel : equipment.id,
          meterName: meterName,
          meterId: meterId,
          gatewayId: '',
          status: 'Active',
          gridType: 'Grid',
          maintenanceDate: '',
          lastMaintenanceDate: '',
          nextMaintenanceDate: '',
          registrationDate: '',
        );
        try {
          return await addFacility(facility);
        } catch (_) {
          return false;
        }
      }));
      for (final ok in results) {
        if (ok) {
          created++;
        } else {
          failedCreate++;
        }
      }
    }

    return {
      'deleted': deleted,
      'failed_delete': failedDelete,
      'created': created,
      'failed_create': failedCreate,
    };
  }

  /// Sync master facility from already-fetched discovery data.
  /// Pass [discoveredDevices] and [overrides] from the discovery page to avoid
  /// a duplicate InfluxDB fetch. If [discoveredDevices] is empty (InfluxDB had
  /// no data), the sync is skipped and existing master facility records are preserved.
  static Future<void> syncDiscoveredDevices({
    List<DiscoveredDevice>? discoveredDevices,
    Map<String, Map<String, dynamic>>? overrides,
  }) async {
    final List<DiscoveredDevice> discoveredList;
    final Map<String, Map<String, dynamic>> effectiveOverrides;

    if (discoveredDevices != null && overrides != null) {
      discoveredList     = discoveredDevices;
      effectiveOverrides = overrides;
    } else {
      // Fallback: fetch fresh when called without pre-fetched data
      final influxService = InfluxDiscoveryService();
      final configService = DeviceConfigService();
      final results = await Future.wait([
        influxService.discoverAllDevices(start: '-30d'),
        configService.loadOverrides(),
      ]);
      discoveredList     = results[0] as List<DiscoveredDevice>;
      effectiveOverrides = results[1] as Map<String, Map<String, dynamic>>;
    }

    // If InfluxDB returned nothing, preserve all existing master facility data
    if (discoveredList.isEmpty) return;

    final overridesData = effectiveOverrides;

    // 2. Identify "Visible" devices (discovered + overrides, excluding hidden)
    final visibleDevices = <String, Map<String, dynamic>>{};
    for (final device in discoveredList) {
      final id = device.deviceId;
      final ov = overridesData[id] ?? {};
      final isHidden = ov['isHidden'] as bool? ?? false;
      if (isHidden) continue;

      // A device approved before the approveDevice() fix may still have its
      // override doc's displayName stuck at the raw discovered name (rather
      // than a real custom rename). Treat that as "no override" too, so a
      // manually-typed Master Facility Setting display name doesn't get
      // reverted by this stale, never-actually-renamed value.
      final ovDisplayName = ov['displayName'] as String?;
      final hasNameOverride = ovDisplayName?.isNotEmpty == true && ovDisplayName != device.displayName;
      visibleDevices[id] = {
        'status':      'Active',
        'displayName': hasNameOverride ? ov['displayName'] as String : device.displayName,
        'hasNameOverride': hasNameOverride,
        // MySQL enrichment — empty when MySQL not configured (safe fallback)
        'siteId':      device.siteId,
        'machineId':   device.machineId,
        'machineName': device.machineName,
        'lineId':      device.lineId,
        'lineName':    device.lineName,
        'zoneId':      device.zoneId,
        'parentId':    device.parentId,
        'parentName':  device.parentName,
        // Pre-populate org fields only when MySQL data is available
        'siteName':    device.plantName,
        'zoneName':    device.zoneName,
      };
    }

    // 3. Fetch all existing records. Master Facilities is the permanent asset
    // registry (SSOT) — Discovery only adds/updates, it never deletes. Any
    // record whose device wasn't seen this cycle is kept and just marked
    // Offline below, instead of being removed.
    final existingFacilities = await getFacilities();
    final nowIso = DateTime.now().toIso8601String();

    final offlineOps = <Future>[];
    final grouped = <String, List<FacilityData>>{};
    for (final f in existingFacilities) {
      if (!visibleDevices.containsKey(f.meterId)) {
        if (f.id != null && f.onlineStatus != 'Offline') {
          offlineOps.add(patchFacility(f.id!, {'onlineStatus': 'Offline'}));
        }
      } else {
        grouped.putIfAbsent(f.meterId, () => []).add(f);
      }
    }
    // Duplicate Firestore docs sharing the same meterId are a bookkeeping
    // error (not an "undetected device"), so those are still cleaned up.
    final deleteOps = <Future>[];
    for (final group in grouped.values) {
      if (group.length <= 1) continue;
      group.sort((a, b) => (b.id ?? '').compareTo(a.id ?? ''));
      for (final dup in group.skip(1)) {
        if (dup.id != null) deleteOps.add(deleteFacility(dup.id!));
      }
    }
    if (offlineOps.isNotEmpty) await Future.wait(offlineOps);
    if (deleteOps.isNotEmpty) await Future.wait(deleteOps);

    // 4. Add or Update remaining facilities (fresh fetch after cleanup).
    final facilityByMeterId = {for (final f in await getFacilities()) f.meterId: f};
    
    for (final entry in visibleDevices.entries) {
      final meterId = entry.key;
      final data    = entry.value;
      final existing = facilityByMeterId[meterId];

      if (existing != null) {
        // Patch display name and MySQL enrichment fields only.
        // Status and org fields (plant/factory/zone/productionArea) are left alone
        // for existing records — they're user-editable in Master Facility Setting
        // and re-discovering devices must not revert any manual change made there.
        final patches = <String, dynamic>{
          'onlineStatus': 'Online',
          'lastSeen': nowIso,
        };
        // Only overwrite the display name when Device Discovery has an explicit
        // rename override — otherwise preserve whatever was manually typed in
        // Master Facility Setting's table (it would get reverted to the raw
        // InfluxDB device name on every re-discover without this guard).
        final hasNameOverride = data['hasNameOverride'] as bool;
        if (hasNameOverride && existing.meterName != data['displayName']) {
          patches['meterName'] = data['displayName'];
        }
        // Always sync raw MySQL fields (auto-sourced, not manually entered)
        if ((data['siteId']      as String).isNotEmpty) patches['siteId']      = data['siteId'];
        if ((data['machineId']   as String).isNotEmpty) patches['machineId']   = data['machineId'];
        if ((data['machineName'] as String).isNotEmpty) patches['machineName'] = data['machineName'];
        if ((data['lineId']      as String).isNotEmpty) patches['lineId']      = data['lineId'];
        if ((data['lineName']    as String).isNotEmpty) patches['lineName']    = data['lineName'];
        if ((data['zoneId']      as String).isNotEmpty) patches['zoneId']      = data['zoneId'];
        if ((data['zoneName']    as String).isNotEmpty) patches['zoneName']    = data['zoneName'];
        if ((data['parentId']    as String).isNotEmpty) patches['parentId']    = data['parentId'];
        if ((data['parentName']  as String).isNotEmpty) patches['parentName']  = data['parentName'];
        // Fill org fields from MySQL when still at default '-' (not yet manually set)
        final siteName    = data['siteName']    as String;
        final machineName = data['machineName'] as String;
        final zoneNameVal = data['zoneName']    as String;
        final lineName    = data['lineName']    as String;
        if (siteName.isNotEmpty    && (existing.plant          == '-' || existing.plant.isEmpty))          patches['plant']          = siteName;
        if (machineName.isNotEmpty && (existing.factory        == '-' || existing.factory.isEmpty))        patches['factory']        = machineName;
        if (zoneNameVal.isNotEmpty && (existing.zone           == '-' || existing.zone.isEmpty))           patches['zone']           = zoneNameVal;
        if (lineName.isNotEmpty    && (existing.productionArea == '-' || existing.productionArea.isEmpty)) patches['productionArea'] = lineName;

        if (patches.isNotEmpty && existing.id != null) {
          try { await patchFacility(existing.id!, patches); } catch (_) {}
        }
      } else {
        // New record — pre-populate org fields from MySQL if available,
        // otherwise leave as '-' for manual entry.
        final siteName   = (data['siteName']  as String).isNotEmpty ? data['siteName']  as String : '-';
        final zoneName   = (data['zoneName']  as String).isNotEmpty ? data['zoneName']  as String : '-';
        final lineName   = (data['lineName']  as String).isNotEmpty ? data['lineName']  as String : '-';
        final machineName = (data['machineName'] as String).isNotEmpty ? data['machineName'] as String : '-';

        final facility = FacilityData(
          meterName:           data['displayName'] as String,
          meterId:             meterId,
          gatewayId:           '-',
          plant:               siteName,
          factory:             machineName,
          zone:                zoneName,
          productionArea:      lineName,
          equipmentType:       '-',
          equipmentNameId:     '-',
          status:              data['status'] as String,
          gridType:            '-',
          maintenanceDate:     '',
          lastMaintenanceDate: '',
          nextMaintenanceDate: '',
          registrationDate:    '',
          siteId:      data['siteId']      as String,
          machineId:   data['machineId']   as String,
          machineName: data['machineName'] as String,
          lineId:      data['lineId']      as String,
          lineName:    data['lineName']    as String,
          zoneId:      data['zoneId']      as String,
          zoneName:    data['zoneName']    as String,
          parentId:    data['parentId']    as String,
          parentName:  data['parentName']  as String,
          onlineStatus: 'Online',
          lastSeen:     nowIso,
        );
        try { await addFacility(facility); } catch (_) {}
      }
    }
  }
}