import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discovery_models.dart';
import '../services/influx_discovery_service.dart';
import '../services/device_config_service.dart';
import '../../../auth/firebase_auth/auth_util.dart';
import '../../master_facility_setting/services/facility_service.dart';

String get _prefsKey => 'discovery_state_v1_$currentUserUid';

enum DiscoveryStatus { idle, loading, loaded, error }

class DiscoveryState {
  final List<DiscoveredDevice> devices;
  final DiscoveryStatus status;
  final String? error;
  final Set<String> expandedIds;
  final bool showHidden;
  final bool isRefreshing;
  final bool isRestoring;
  final Set<String> reconnectingIds;
  final List<String> deviceTypes;
  final bool isFromCache;
  final DateTime? lastFetchedAt;

  const DiscoveryState({
    this.devices = const [],
    this.status = DiscoveryStatus.idle,
    this.error,
    this.expandedIds = const {},
    this.showHidden = false,
    this.isRefreshing = false,
    this.isRestoring = false,
    this.reconnectingIds = const {},
    this.deviceTypes = const [],
    this.isFromCache = false,
    this.lastFetchedAt,
  });

  DiscoveryState copyWith({
    List<DiscoveredDevice>? devices,
    DiscoveryStatus? status,
    String? error,
    Set<String>? expandedIds,
    bool? showHidden,
    bool? isRefreshing,
    bool? isRestoring,
    Set<String>? reconnectingIds,
    List<String>? deviceTypes,
    bool? isFromCache,
    DateTime? lastFetchedAt,
  }) =>
      DiscoveryState(
        devices: devices ?? this.devices,
        status: status ?? this.status,
        error: error ?? this.error,
        expandedIds: expandedIds ?? this.expandedIds,
        showHidden: showHidden ?? this.showHidden,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isRestoring: isRestoring ?? this.isRestoring,
        reconnectingIds: reconnectingIds ?? this.reconnectingIds,
        deviceTypes: deviceTypes ?? this.deviceTypes,
        isFromCache: isFromCache ?? this.isFromCache,
        lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      );
}

class DiscoveryCubit extends Cubit<DiscoveryState> {
  final InfluxDiscoveryService _influx;
  final DeviceConfigService _config;
  Timer? _autoTimer;

  DiscoveryCubit({InfluxDiscoveryService? influx, DeviceConfigService? config})
      : _influx = influx ?? InfluxDiscoveryService(),
        _config = config ?? DeviceConfigService(),
        super(const DiscoveryState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadDeviceTypes();
    await discoverAll();
  }

  Future<void> _loadDeviceTypes() async {
    try {
      final list = await FacilityService.getDeviceTypes();
      final names = list
          .map((e) => e['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) emit(state.copyWith(deviceTypes: names));
    } catch (_) {}
  }

  /// Call this when the auth user changes (login/logout/switch).
  /// Stops any running timers, resets to idle, then loads the new user's cache.
  Future<void> onUserChanged() async {
    _autoTimer?.cancel();
    emit(const DiscoveryState());
    await restorePersistedState();
  }

  Future<void> restorePersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;

      final decoded = json.decode(raw);

      List<dynamic> deviceList;
      List<String> deviceTypes = [];

      if (decoded is Map) {
        deviceList = decoded['devices'] as List<dynamic>? ?? [];
        deviceTypes = List<String>.from(decoded['deviceTypes'] as List? ?? []);
      } else {
        // legacy format: plain list
        deviceList = decoded as List<dynamic>;
      }

      final devices = deviceList
          .map((e) => DiscoveredDevice.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (devices.isNotEmpty) {
        emit(state.copyWith(
          devices: devices,
          status: DiscoveryStatus.loaded,
          isFromCache: true,
        ));
      }
    } catch (_) {}
  }

  List<String> _extractTypes(List<DiscoveredDevice> devices) {
    final types = devices
        .map((d) => d.deviceType ?? '')
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return types;
  }

  Future<void> _persist(List<DiscoveredDevice> devices, {List<String>? deviceTypes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final types = deviceTypes ?? state.deviceTypes;
      await prefs.setString(
          _prefsKey,
          json.encode({
            'devices': devices.map((d) => d.toMap()).toList(),
            'deviceTypes': types,
          }));
    } catch (_) {}
  }



  Future<void> initLoad() async {
    emit(state.copyWith(status: DiscoveryStatus.loading));
    try {
      final overrides = await _config.loadOverrides();

      final List<DiscoveredDevice> savedDevices = [];
      for (final entry in overrides.entries) {
        final deviceId = entry.key;
        final ov = entry.value;
        final isHidden = ov['isHidden'] as bool? ?? false;

        if (isHidden && !state.showHidden) continue;

        savedDevices.add(DiscoveredDevice(
          deviceId: deviceId,
          deviceName: ov['deviceName'] as String? ?? deviceId,
          displayName: ov['displayName'] as String? ?? deviceId,
          deviceType: ov['deviceType'] as String? ?? '',
          tags: [],
          plantId: ov['plantId'] as String? ?? '',
          zoneId: ov['zoneId'] as String? ?? '',
          plantName: ov['plantName'] as String? ?? '',
          zoneName: ov['zoneName'] as String? ?? '',
          isApproved: ov['isApproved'] as bool? ?? false,
          isHidden: false,
        ));
      }

      emit(state.copyWith(
        devices: savedDevices,
        status: DiscoveryStatus.loaded,
      ));
      _persist(savedDevices);
    } catch (e) {
      emit(state.copyWith(status: DiscoveryStatus.error, error: e.toString()));
    }
  }

  Future<void> discoverAll() async {
    emit(state.copyWith(status: DiscoveryStatus.loading));
    try {
      final results = await Future.wait([
        _influx.discoverAllDevices(),
        _config.loadOverrides(),
      ]);

      final discovered = results[0] as List<DiscoveredDevice>;
      final overrides = results[1] as Map<String, Map<String, dynamic>>;

      // Build a map of live devices from InfluxDB
      final liveIds = {for (final d in discovered) d.deviceId: d};

      // Merge: live devices + approved-but-offline devices from Firestore
      final merged = <DiscoveredDevice>[];

      // 1. All live devices (apply overrides)
      for (final d in discovered) {
        final ov = overrides[d.deviceId] ?? {};
        final isHidden = ov['isHidden'] as bool? ?? false;
        if (isHidden && !state.showHidden) continue;
        merged.add(DiscoveredDevice(
          deviceId:    d.deviceId,
          deviceName:  d.deviceName,
          displayName: ov['displayName'] as String? ?? d.displayName,
          deviceType:  (ov['deviceType'] as String?)?.isNotEmpty == true ? ov['deviceType'] as String : d.deviceType,
          tags:        d.tags,
          plantId:     ov['plantId']   as String? ?? d.plantId,
          zoneId:      ov['zoneId']    as String? ?? d.zoneId,
          plantName:   ov['plantName'] as String? ?? d.plantName,
          zoneName:    ov['zoneName']  as String? ?? d.zoneName,
          isApproved:  ov['isApproved'] as bool? ?? d.isApproved,
          isHidden:    false,
          siteId:      ov['siteId']      as String? ?? d.siteId,
          machineId:   ov['machineId']   as String? ?? d.machineId,
          machineName: ov['machineName'] as String? ?? d.machineName,
          lineId:      ov['lineId']      as String? ?? d.lineId,
          lineName:    ov['lineName']    as String? ?? d.lineName,
          parentId:    ov['parentId']    as String? ?? d.parentId,
          parentName:  ov['parentName']  as String? ?? d.parentName,
        ));
      }

      // Only InfluxDB live devices are shown — no offline Firestore-only devices.

      emit(state.copyWith(
        devices:      merged,
        status:       DiscoveryStatus.loaded,
        isFromCache:  false,
        lastFetchedAt: DateTime.now(),
      ));
      _persist(merged);
      _syncToMasterFacility(merged, overrides);
    } catch (e) {
      emit(state.copyWith(status: DiscoveryStatus.error, error: e.toString()));
    }
  }

  Future<void> toggleShowHidden() async {
    emit(state.copyWith(showHidden: !state.showHidden));
    await discoverAll();
  }

  Future<void> restoreAll() async {
    emit(state.copyWith(isRestoring: true));
    try {
      await _config.restoreAllDevices();
      await discoverAll();
    } finally {
      emit(state.copyWith(isRestoring: false));
    }
  }

  /// Lightweight re-poll — keeps existing table visible, shows subtle refresh indicator.
  Future<void> refreshNow() async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final results = await Future.wait([
        _influx.discoverAllDevices(start: '-12h'),
        _config.loadOverrides(),
      ]);
      final discovered = results[0] as List<DiscoveredDevice>;
      final overrides = results[1] as Map<String, Map<String, dynamic>>;
      final merged = discovered.map((d) {
        final ov = overrides[d.deviceId] ?? {};
        final isHidden = ov['isHidden'] as bool? ?? false;
        if (isHidden && !state.showHidden) return null;
        return DiscoveredDevice(
          deviceId: d.deviceId, deviceName: d.deviceName,
          displayName: ov['displayName'] as String? ?? d.displayName,
          deviceType: (ov['deviceType'] as String?)?.isNotEmpty == true ? ov['deviceType'] as String : d.deviceType,
          tags: d.tags, plantId: ov['plantId'] as String? ?? d.plantId,
          zoneId: ov['zoneId'] as String? ?? d.zoneId,
          plantName: ov['plantName'] as String? ?? d.plantName,
          zoneName: ov['zoneName'] as String? ?? d.zoneName,
          isApproved: ov['isApproved'] as bool? ?? d.isApproved,
          isHidden: false,
          siteId:      ov['siteId']      as String? ?? d.siteId,
          machineId:   ov['machineId']   as String? ?? d.machineId,
          machineName: ov['machineName'] as String? ?? d.machineName,
          lineId:      ov['lineId']      as String? ?? d.lineId,
          lineName:    ov['lineName']    as String? ?? d.lineName,
          parentId:    ov['parentId']    as String? ?? d.parentId,
          parentName:  ov['parentName']  as String? ?? d.parentName,
        );
      }).whereType<DiscoveredDevice>().toList();
      emit(state.copyWith(
        devices: merged,
        status: DiscoveryStatus.loaded,
        isRefreshing: false,
        isFromCache: false,
        lastFetchedAt: DateTime.now(),
      ));
      _persist(merged);
      _syncToMasterFacility(merged, overrides);
    } catch (_) {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  /// Force re-fetch a single device from InfluxDB and mark it Active if successful.
  Future<void> reconnectDevice(String deviceId) async {
    final ids = Set<String>.from(state.reconnectingIds)..add(deviceId);
    emit(state.copyWith(reconnectingIds: ids));
    try {
      final refreshed = await _influx.refreshSingleDevice(deviceId);
      if (refreshed != null) {
        await _config.approveDevice(deviceId, refreshed);
        final updated = state.devices.map((d) {
          if (d.deviceId != deviceId) return d;
          return DiscoveredDevice(
            deviceId: d.deviceId, deviceName: d.deviceName,
            displayName: d.displayName, deviceType: d.deviceType,
            tags: refreshed.tags,
            plantId: d.plantId, zoneId: d.zoneId,
            plantName: d.plantName, zoneName: d.zoneName,
            isApproved: true, isHidden: false,
            siteId: d.siteId, machineId: d.machineId, machineName: d.machineName,
            lineId: d.lineId, lineName: d.lineName,
            parentId: d.parentId, parentName: d.parentName,
          );
        }).toList();
        emit(state.copyWith(
          devices: updated,
          reconnectingIds: Set<String>.from(state.reconnectingIds)..remove(deviceId),
        ));
        _persist(updated);
      } else {
        emit(state.copyWith(
          reconnectingIds: Set<String>.from(state.reconnectingIds)..remove(deviceId),
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        reconnectingIds: Set<String>.from(state.reconnectingIds)..remove(deviceId),
      ));
    }
  }

  void _syncToMasterFacility(
    List<DiscoveredDevice> devices,
    Map<String, Map<String, dynamic>> overrides,
  ) {
    FacilityService.syncDiscoveredDevices(
      discoveredDevices: devices,
      overrides: overrides,
    ).catchError((_) {});
  }

  void startAutoDiscover() {
    _autoTimer?.cancel();
    discoverAll();
    _autoTimer = Timer.periodic(const Duration(minutes: 1), (_) => discoverAll());
  }

  void stopAutoDiscover() => _autoTimer?.cancel();

  void toggleExpand(String deviceId) {
    final ids = Set<String>.from(state.expandedIds);
    ids.contains(deviceId) ? ids.remove(deviceId) : ids.add(deviceId);
    emit(state.copyWith(expandedIds: ids));
  }

  Future<void> approve(String deviceId) async {
    final device = state.devices.firstWhere((d) => d.deviceId == deviceId);
    await _config.approveDevice(deviceId, device);
    final updated = state.devices.map((d) {
      if (d.deviceId != deviceId) return d;
      return DiscoveredDevice(
        deviceId: d.deviceId, deviceName: d.deviceName, displayName: d.displayName,
        deviceType: d.deviceType,
        tags: d.tags, plantId: d.plantId, zoneId: d.zoneId,
        plantName: d.plantName, zoneName: d.zoneName,
        isApproved: true, isHidden: false,
        siteId: d.siteId, machineId: d.machineId, machineName: d.machineName,
        lineId: d.lineId, lineName: d.lineName,
        parentId: d.parentId, parentName: d.parentName,
      );
    }).toList();
    emit(state.copyWith(devices: updated));
    _persist(updated);
  }

  Future<void> hide(String deviceId) async {
    await _config.hideDevice(deviceId);
    final updated = state.devices.where((d) => d.deviceId != deviceId).toList();
    emit(state.copyWith(devices: updated));
    _persist(updated);
  }

  Future<void> rename(String deviceId, String displayName) async {
    await _config.renameDevice(deviceId, displayName);
    final updated = state.devices.map((d) {
      if (d.deviceId != deviceId) return d;
      return DiscoveredDevice(
        deviceId: d.deviceId, deviceName: d.deviceName, displayName: displayName,
        deviceType: d.deviceType,
        tags: d.tags, plantId: d.plantId, zoneId: d.zoneId,
        plantName: d.plantName, zoneName: d.zoneName,
        isApproved: d.isApproved, isHidden: d.isHidden,
        siteId: d.siteId, machineId: d.machineId, machineName: d.machineName,
        lineId: d.lineId, lineName: d.lineName,
        parentId: d.parentId, parentName: d.parentName,
      );
    }).toList();
    emit(state.copyWith(devices: updated));
    _persist(updated);
  }

  Future<void> changeDeviceType(String deviceId, String deviceType) async {
    await _config.changeDeviceType(deviceId, deviceType);
    final updated = state.devices.map((d) {
      if (d.deviceId != deviceId) return d;
      return DiscoveredDevice(
        deviceId: d.deviceId, deviceName: d.deviceName, displayName: d.displayName,
        deviceType: deviceType,
        tags: d.tags, plantId: d.plantId, zoneId: d.zoneId,
        plantName: d.plantName, zoneName: d.zoneName,
        isApproved: d.isApproved, isHidden: d.isHidden,
        siteId: d.siteId, machineId: d.machineId, machineName: d.machineName,
        lineId: d.lineId, lineName: d.lineName,
        parentId: d.parentId, parentName: d.parentName,
      );
    }).toList();
    emit(state.copyWith(devices: updated));
    _persist(updated);
  }

  /// Updates tagName/unit for a specific field on a device (in-memory only, no Firestore).
  void updateTagMeta(String deviceId, String fieldName,
      {required String tagName, required String unit}) {
    final updated = state.devices.map((d) {
      if (d.deviceId != deviceId) return d;
      final tags = d.tags.map((t) {
        if (t.fieldName != fieldName) return t;
        return InfluxTag(
          measurement: t.measurement, fieldName: t.fieldName,
          tagName: tagName, unit: unit,
          lastValue: t.lastValue, lastUpdate: t.lastUpdate,
        );
      }).toList();
      return DiscoveredDevice(
        deviceId: d.deviceId, deviceName: d.deviceName,
        displayName: d.displayName, deviceType: d.deviceType, tags: tags,
        plantId: d.plantId, zoneId: d.zoneId,
        plantName: d.plantName, zoneName: d.zoneName,
        isApproved: d.isApproved, isHidden: d.isHidden,
        siteId: d.siteId, machineId: d.machineId, machineName: d.machineName,
        lineId: d.lineId, lineName: d.lineName,
        parentId: d.parentId, parentName: d.parentName,
      );
    }).toList();
    emit(state.copyWith(devices: updated));
    _persist(updated);
  }

  Future<void> updateMapping(String deviceId,
      {required String plantId, required String plantName,
       required String zoneId, required String zoneName}) async {
    await _config.updateMapping(deviceId,
        plantId: plantId, plantName: plantName, zoneId: zoneId, zoneName: zoneName);
    await discoverAll();
  }

  @override
  Future<void> close() {
    _autoTimer?.cancel();
    return super.close();
  }
}
