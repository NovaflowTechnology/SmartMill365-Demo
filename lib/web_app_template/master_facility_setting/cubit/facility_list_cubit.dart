import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smartmachine365/flutter_flow/rbac.dart';
import 'package:smartmachine365/services/app_config.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/models/facility_data.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';

part 'facility_list_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FacilityListCubit
//
// Owns ALL logic for MasterFacilitySettingWidget:
//   - Loading / reloading facility list
//   - Filter state (plant, status)
//   - Column toggle (details / dates)
//   - CRUD callbacks (add, update, delete)
//
// Widget only calls methods and reads state — zero setState.
// ─────────────────────────────────────────────────────────────────────────────

class FacilityListCubit extends Cubit<FacilityListState> {
  final String userRole;
  final String factoryId;

  FacilityListCubit({this.userRole = '', this.factoryId = ''})
      : super(const FacilityListInitial());
  bool _isBulkProcessing = false;

  // ── Load / reload ─────────────────────────────────────────────────────────
  Future<void> loadFacilities() async {
    // Keep existing filters/toggles if already loaded
    final prev = state is FacilityListLoaded ? state as FacilityListLoaded : null;
    emit(const FacilityListLoading());
    try {
      final isSuperAdmin =
          AppRoles.normalizeRole(userRole) == AppRoles.superAdmin;

      // Resolve factoryId → factory name for non-super admin filtering
      String? allowedFactoryName;
      if (!isSuperAdmin && factoryId.isNotEmpty) {
        try {
          final factories = await FacilityService.getFactories();
          final match = factories.firstWhere(
            (f) => f['id']?.toString() == factoryId,
            orElse: () => {},
          );
          allowedFactoryName = match['name']?.toString();
        } catch (_) {}
      }

      final list = await FacilityService.getFacilities();
      final cId   = AppConfig.clientId;
      final cName = AppConfig.clientName;
      var rows = list.map((f) => {
        'id':                  f.id                  ?? '',
        'plant':               f.plant,
        'factory':             f.factory,
        'zone':                f.zone,
        'productionArea':      f.productionArea,
        'equipmentType':       f.equipmentType,
        'equipmentNameId':     f.equipmentNameId,
        'meterName':           f.meterName,
        'meterId':             f.meterId,
        'gatewayId':           f.gatewayId,
        'status':              f.status,
        'gridType':            f.gridType,
        'maintenanceDate':     f.maintenanceDate,
        'lastMaintenanceDate': f.lastMaintenanceDate,
        'nextMaintenanceDate': f.nextMaintenanceDate,
        'registrationDate':    f.registrationDate,
        'siteId':              f.siteId,
        'machineId':           f.machineId,
        'machineName':         f.machineName,
        'lineId':              f.lineId,
        'lineName':            f.lineName,
        'zoneId':              f.zoneId,
        'zoneName':            f.zoneName,
        'parentId':            f.parentId,
        'parentName':          f.parentName,
        'clientName':          cName,
        'clientId':            cId,
        'includePfAnalytics':  f.includePfAnalytics,
        'includeMdRanking':    f.includeMdRanking,
        'includeCarbonCalc':   f.includeCarbonCalc,
      }).toList();

      if (!isSuperAdmin && allowedFactoryName != null && allowedFactoryName.isNotEmpty) {
        rows = rows
            .where((r) => r['factory']?.toString() == allowedFactoryName)
            .toList();
      }

      emit(FacilityListLoaded(
        allRows:         rows,
        plantFilter:     prev?.plantFilter     ?? 'All',
        zoneFilter:      prev?.zoneFilter      ?? 'All',
        lineFilter:      prev?.lineFilter      ?? 'All',
        equipmentFilter: prev?.equipmentFilter ?? 'All',
        statusFilter:    prev?.statusFilter    ?? 'All',
        showDates:       prev?.showDates        ?? false,
        showMysql:       prev?.showMysql        ?? false,
      ));

      // On first load only: sync enrichment from InfluxDB + MySQL, then reload once
      if (prev == null) {
        FacilityService.syncDiscoveredDevices().catchError((_) {}).then((_) {
          if (!isClosed) _reloadAfterSync();
        });
      }
    } catch (e) {
      emit(FacilityListError(e.toString()));
    }
  }

  Future<void> _reloadAfterSync() async {
    final prev = state is FacilityListLoaded ? state as FacilityListLoaded : null;
    try {
      final list = await FacilityService.getFacilities();
      final cId   = AppConfig.clientId;
      final cName = AppConfig.clientName;
      final rows = list.map((f) => {
        'id':                  f.id                  ?? '',
        'plant':               f.plant,
        'factory':             f.factory,
        'zone':                f.zone,
        'productionArea':      f.productionArea,
        'equipmentType':       f.equipmentType,
        'equipmentNameId':     f.equipmentNameId,
        'meterName':           f.meterName,
        'meterId':             f.meterId,
        'gatewayId':           f.gatewayId,
        'status':              f.status,
        'gridType':            f.gridType,
        'maintenanceDate':     f.maintenanceDate,
        'lastMaintenanceDate': f.lastMaintenanceDate,
        'nextMaintenanceDate': f.nextMaintenanceDate,
        'registrationDate':    f.registrationDate,
        'siteId':              f.siteId,
        'machineId':           f.machineId,
        'machineName':         f.machineName,
        'lineId':              f.lineId,
        'lineName':            f.lineName,
        'zoneId':              f.zoneId,
        'zoneName':            f.zoneName,
        'parentId':            f.parentId,
        'parentName':          f.parentName,
        'clientName':          cName,
        'clientId':            cId,
        'includePfAnalytics':  f.includePfAnalytics,
        'includeMdRanking':    f.includeMdRanking,
        'includeCarbonCalc':   f.includeCarbonCalc,
      }).toList();
      if (!isClosed) {
        emit(FacilityListLoaded(
          allRows:         rows,
          plantFilter:     prev?.plantFilter     ?? 'All',
          zoneFilter:      prev?.zoneFilter      ?? 'All',
          lineFilter:      prev?.lineFilter      ?? 'All',
          equipmentFilter: prev?.equipmentFilter ?? 'All',
          statusFilter:    prev?.statusFilter    ?? 'All',
          showDates:       prev?.showDates        ?? false,
          showMysql:       prev?.showMysql        ?? false,
        ));
      }
    } catch (_) {}
  }

  // ── Filter ────────────────────────────────────────────────────────────────
  // Cascade: changing a parent filter resets any child selections that are no
  // longer valid under the new parent (matches Energy Details behaviour).
  void setPlantFilter(String value) {
    final s = _requireLoaded();
    if (s == null) return;
    var next = s.copyWith(plantFilter: value);
    if (!next.zoneOptions.contains(next.zoneFilter)) next = next.copyWith(zoneFilter: 'All');
    if (!next.lineOptions.contains(next.lineFilter)) next = next.copyWith(lineFilter: 'All');
    if (!next.equipmentOptions.contains(next.equipmentFilter)) next = next.copyWith(equipmentFilter: 'All');
    emit(next);
  }

  void setZoneFilter(String value) {
    final s = _requireLoaded();
    if (s == null) return;
    var next = s.copyWith(zoneFilter: value);
    if (!next.lineOptions.contains(next.lineFilter)) next = next.copyWith(lineFilter: 'All');
    if (!next.equipmentOptions.contains(next.equipmentFilter)) next = next.copyWith(equipmentFilter: 'All');
    emit(next);
  }

  void setLineFilter(String value) {
    final s = _requireLoaded();
    if (s == null) return;
    var next = s.copyWith(lineFilter: value);
    if (!next.equipmentOptions.contains(next.equipmentFilter)) next = next.copyWith(equipmentFilter: 'All');
    emit(next);
  }

  void setEquipmentFilter(String value) {
    final s = _requireLoaded();
    if (s == null) return;
    emit(s.copyWith(equipmentFilter: value));
  }

  void setStatusFilter(String value) {
    final s = _requireLoaded();
    if (s == null) return;
    emit(s.copyWith(statusFilter: value));
  }

  // ── Column toggle ─────────────────────────────────────────────────────────
  void showDetails() {
    final s = _requireLoaded();
    if (s == null) return;
    emit(s.copyWith(showDates: false, showMysql: false));
  }

  void showDates() {
    final s = _requireLoaded();
    if (s == null) return;
    emit(s.copyWith(showDates: true, showMysql: false));
  }

  void showMysqlView() {
    final s = _requireLoaded();
    if (s == null) return;
    emit(s.copyWith(showMysql: true, showDates: false));
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> addFacility(Map<String, dynamic> data) async {
    // 3B: Reject duplicates before writing to the backend.
    final meterId = data['meterId']?.toString().trim() ?? '';
    final loaded = _requireLoaded();
    if (meterId.isNotEmpty && loaded != null) {
      final exists = loaded.allRows
          .any((r) => r['meterId']?.toString().trim() == meterId);
      if (exists) {
        emit(const FacilityListActionError(
            'Duplicate Device ID: this meter is already registered.'));
        return;
      }
    }
    try {
      await FacilityService.addFacility(FacilityData.fromMap('', data));
      emit(const FacilityListSuccess('Facility added successfully!'));
      await loadFacilities();
    } catch (e) {
      emit(FacilityListActionError('Failed to add facility: $e'));
      await loadFacilities();
      rethrow;
    }
  }

  Future<void> updateFacility(String id, Map<String, dynamic> row) async {
    try {
      await FacilityService.updateFacility(id, FacilityData.fromMap(id, row));
      emit(const FacilityListSuccess('Facility updated successfully!'));
      await loadFacilities();
    } catch (e) {
      emit(FacilityListActionError('Failed to update facility: $e'));
      await loadFacilities();
      rethrow;
    }
  }

  Future<void> deleteFacility(String id) async {
    try {
      await FacilityService.deleteFacility(id);
      emit(const FacilityListSuccess('Facility deleted successfully!'));
      await loadFacilities();
    } catch (e) {
      emit(FacilityListActionError('Failed to delete facility: $e'));
      await loadFacilities();
    }
  }

  Future<void> seedTemplateFromEquipments() async {
    if (_isBulkProcessing) {
      emit(const FacilityListActionError(
          'Template build is already running. Please wait until it finishes.'));
      return;
    }
    final loaded = _requireLoaded();
    if (loaded != null && loaded.allRows.isNotEmpty) {
      emit(const FacilityListActionError(
          'Template data already exists. Please run Remove All Equipment before building again.'));
      return;
    }
    _isBulkProcessing = true;
    try {
      final result = await FacilityService.seedFacilitiesFromEquipmentsTemplate();
      final created = result['created'] ?? 0;
      final deleted = result['deleted'] ?? 0;
      final failedDelete = result['failed_delete'] ?? 0;
      final failedCreate = result['failed_create'] ?? 0;
      emit(FacilityListSuccess(
          'Template completed: $deleted old rows removed, '
          '$created new rows created, '
          '$failedDelete failed to delete, $failedCreate failed to create.'));
      await loadFacilities();
    } catch (e) {
      emit(FacilityListActionError('Failed to build template: $e'));
      await loadFacilities();
    } finally {
      _isBulkProcessing = false;
    }
  }

  Future<void> removeAllFacilities() async {
    if (_isBulkProcessing) {
      emit(const FacilityListActionError(
          'A bulk process is already running. Please wait.'));
      return;
    }
    _isBulkProcessing = true;
    try {
      final result = await FacilityService.deleteAllFacilitiesSummary();
      final deleted = result['deleted'] ?? 0;
      final failed = result['failed'] ?? 0;
      emit(FacilityListSuccess(
          'Remove all completed: $deleted equipment rows removed, '
          '$failed rows failed to remove.'));
      await loadFacilities();
    } catch (e) {
      emit(FacilityListActionError('Failed to remove all facilities: $e'));
      await loadFacilities();
    } finally {
      _isBulkProcessing = false;
    }
  }

  // ── Inline patch — device type from table dropdown ────────────────────────
  Future<void> patchDeviceType(String id, String deviceType) async {
    final s = _requireLoaded();
    if (s == null) return;
    // Optimistic update in state
    final updatedRows = s.allRows.map((r) {
      if (r['id']?.toString() == id) {
        return {...r, 'equipmentType': deviceType};
      }
      return r;
    }).toList();
    emit(s.copyWith(allRows: updatedRows));
    try {
      await FacilityService.patchFacility(id, {'equipmentType': deviceType});
    } catch (_) {
      // Revert on failure
      emit(s);
      emit(const FacilityListActionError('Failed to update device type.'));
    }
  }

  Future<void> patchField(String id, String field, String value) async {
    final s = _requireLoaded();
    if (s == null) return;
    final updatedRows = s.allRows.map((r) {
      if (r['id']?.toString() == id) return {...r, field: value};
      return r;
    }).toList();
    emit(s.copyWith(allRows: updatedRows));
    try {
      await FacilityService.patchFacility(id, {field: value});
    } catch (_) {
      emit(s);
      emit(const FacilityListActionError('Failed to update field.'));
    }
  }

  // ── Inline patch — analytics inclusion checkboxes (PF / MD / Carbon) ──────
  Future<void> patchInclusionFlag(String id, String field, bool value) async {
    final s = _requireLoaded();
    if (s == null) return;
    final updatedRows = s.allRows.map((r) {
      if (r['id']?.toString() == id) return {...r, field: value};
      return r;
    }).toList();
    emit(s.copyWith(allRows: updatedRows));
    try {
      await FacilityService.patchFacility(id, {field: value});
    } catch (_) {
      // Revert on failure
      emit(s);
      emit(const FacilityListActionError('Failed to update inclusion flag.'));
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  FacilityListLoaded? _requireLoaded() =>
      state is FacilityListLoaded ? state as FacilityListLoaded : null;
}