import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smartmachine365/web_app_template/master_facility_setting/services/facility_service.dart';

part 'facility_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FacilityCubit
//
// Single source of truth for both Create and Update dialogs.
// Widgets call methods here — they never manage dropdown/selection state.
//
// Flow:
//   loadDropdowns()  → FacilityDropdownsLoading → FacilityDropdownsLoaded
//   selectX()        → emits updated FacilityDropdownsLoaded via copyWith
//   submitCreate()   → FacilitySubmitting → FacilitySubmitSuccess / Error
//   submitUpdate()   → FacilitySubmitting → FacilitySubmitSuccess / Error
// ─────────────────────────────────────────────────────────────────────────────

class FacilityCubit extends Cubit<FacilityState> {
  FacilityCubit() : super(const FacilityInitial());

  // ── Load all dropdown data ────────────────────────────────────────────────
  /// Pass [initialData] for the Update dialog to pre-match existing values.
  Future<void> loadDropdowns({Map<String, dynamic>? initialData}) async {
    emit(const FacilityDropdownsLoading());
    try {
      final results = await Future.wait([
        FacilityService.getFacilities(),
        FacilityService.getEquipments(),
        FacilityService.getDeviceTypes(),
        FacilityService.getFactories(),
        FacilityService.getProductionAreas(),
        FacilityService.getProductionLines(),
      ]);

      final facilities         = results[0] as List<dynamic>;
      final equipments         = results[1] as List<EquipmentItem>;
      final deviceTypes        = results[2] as List<Map<String, dynamic>>;
      final factoryList        = results[3] as List<Map<String, dynamic>>;
      final productionAreaList = results[4] as List<Map<String, dynamic>>;
      final productionLineList = results[5] as List<Map<String, dynamic>>;

      // Dropdown sources:
      //   factories       → /factory          (Site / Plant)        — General Factory Setting
      //   zones           → /productionAreas   (Zone)                — General Factory Setting
      //   productionLines → /productionLines   (Line / Prod. Area)   — General Factory Setting
      //   productionAreas → MySQL machineName  (Machine / Factory)   — from facilities
      // The facility stores names and pre-fill matches by name, so name is used
      // as the dropdown id too.
      List<Map<String, dynamic>> byName(List<Map<String, dynamic>> src) {
        final seen = <String>{};
        final out = <Map<String, dynamic>>[];
        for (final e in src) {
          final n = (e['name']?.toString() ?? '').trim();
          if (n.isEmpty || n == '-' || n == 'Not Assigned') continue;
          if (seen.add(n)) out.add({'id': n, 'name': n});
        }
        out.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        return out;
      }

      final factories       = byName(factoryList);        // Site / Plant
      final zones           = byName(productionAreaList);  // Zone
      final productionLines  = byName(productionLineList); // Line / Prod. Area

      // Machine / Factory ← MySQL machineName (readable machine names)
      final seenMachines = <String>{};
      final productionAreas = <Map<String, dynamic>>[];
      for (final f in facilities) {
        final m = (f.machineName?.toString() ?? '').trim();
        if (m.isNotEmpty && m != '-' && seenMachines.add(m)) productionAreas.add({'id': m, 'name': m});
      }
      productionAreas.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      // Defaults
      String?        matchedFactoryId;
      String?        matchedFactoryName;
      String?        matchedAreaId;
      String?        matchedAreaName;
      String?        matchedPlantId;
      String?        matchedPlantName;
      String?        matchedLineId;
      String?        matchedLineName;
      EquipmentItem? matchedEquipment;
      String         equipmentType       = '';
      String?        matchedDeviceType;
      String         status              = 'Active';
      String         impactCategory      = 'PRODUCTION';
      DateTime?      maintenanceDate;
      DateTime?      lastMaintenanceDate;
      DateTime?      nextMaintenanceDate;
      DateTime?      registrationDate;

      // Pre-fill for Update dialog
      if (initialData != null) {
        final d = initialData;
        status              = d['status']         ?? 'Active';
        impactCategory      = d['impactCategory'] ?? 'PRODUCTION';
        equipmentType       = d['equipmentType']  ?? '';

        // Match device type by name
        final existingDevType = d['equipmentType']?.toString() ?? '';
        if (existingDevType.isNotEmpty) {
          for (final dt in deviceTypes) {
            if (dt['name']?.toString() == existingDevType) {
              matchedDeviceType = existingDevType;
              break;
            }
          }
        }
        maintenanceDate     = _parseDate(d['maintenanceDate']);
        lastMaintenanceDate = _parseDate(d['lastMaintenanceDate']);
        nextMaintenanceDate = _parseDate(d['nextMaintenanceDate']);
        registrationDate    = _parseDate(d['registrationDate']);

        // Exact match first, then a prefix match in either direction
        // (case-insensitive) as a fallback — saved facility data often has
        // near-miss naming vs. the dropdown source lists (e.g. "Cast 15-1"
        // vs "Cast 15"). If the primary list has no match at all, also try
        // the other list (zones vs productionLines), since some legacy
        // records have those two raw fields swapped.
        Map<String, String?>? fuzzyFind(List<Map<String, dynamic>> list, String value) {
          final v = value.trim();
          if (v.isEmpty) return null;
          final vLower = v.toLowerCase();
          for (final e in list) {
            final name = e['name']?.toString() ?? '';
            if (name == v) return {'id': e['id']?.toString(), 'name': name};
          }
          for (final e in list) {
            final name = e['name']?.toString() ?? '';
            if (name.isEmpty) continue;
            final nameLower = name.toLowerCase();
            if (nameLower.startsWith(vLower) || vLower.startsWith(nameLower)) {
              return {'id': e['id']?.toString(), 'name': name};
            }
          }
          return null;
        }

        // Match plant → factories list → selectedPlantId/Name. If nothing
        // matches at all, fall back to the raw saved value directly — the
        // saved data is the source of truth, never leave it blank when it
        // has something (the dropdown gets the value injected below).
        final existingPlant = d['plant']?.toString().trim() ?? '';
        final plantMatch = fuzzyFind(factories, existingPlant);
        matchedPlantId   = plantMatch?['id']   ?? (existingPlant.isNotEmpty ? existingPlant : null);
        matchedPlantName = plantMatch?['name'] ?? (existingPlant.isNotEmpty ? existingPlant : null);

        // Match machine/factory → productionAreas list → selectedFactoryId/Name
        final existingMachine = d['factory']?.toString().trim() ?? '';
        final machineMatch = fuzzyFind(productionAreas, existingMachine);
        matchedFactoryId   = machineMatch?['id']   ?? (existingMachine.isNotEmpty ? existingMachine : null);
        matchedFactoryName = machineMatch?['name'] ?? (existingMachine.isNotEmpty ? existingMachine : null);

        // Match zone → zones list (fallback: productionLines, in case the
        // raw zone/productionArea fields are swapped on this record).
        final existingZone = d['zone']?.toString().trim() ?? '';
        final zoneMatch = fuzzyFind(zones, existingZone) ?? fuzzyFind(productionLines, existingZone);
        matchedAreaId   = zoneMatch?['id']   ?? (existingZone.isNotEmpty ? existingZone : null);
        matchedAreaName = zoneMatch?['name'] ?? (existingZone.isNotEmpty ? existingZone : null);

        // Match line/prod.area → productionLines list (fallback: zones).
        final existingLine = d['productionArea']?.toString().trim() ?? '';
        final lineMatch = fuzzyFind(productionLines, existingLine) ?? fuzzyFind(zones, existingLine);
        matchedLineId   = lineMatch?['id']   ?? (existingLine.isNotEmpty ? existingLine : null);
        matchedLineName = lineMatch?['name'] ?? (existingLine.isNotEmpty ? existingLine : null);

        // Ensure the dropdown lists actually contain whatever raw value we
        // just fell back to, so the field can display/keep it selected.
        void ensure(List<Map<String, dynamic>> list, String? value) {
          if (value == null || value.isEmpty) return;
          if (list.any((e) => (e['name']?.toString() ?? '') == value)) return;
          list.add({'id': value, 'name': value});
        }
        ensure(factories, matchedPlantName);
        ensure(productionAreas, matchedFactoryName);
        ensure(zones, matchedAreaName);
        ensure(productionLines, matchedLineName);

        // Match equipment
        final existingEquip = d['equipmentNameId']?.toString() ?? '';
        if (existingEquip.isNotEmpty) {
          try {
            matchedEquipment = equipments.firstWhere(
              (e) => e.displayLabel == existingEquip || e.name == existingEquip,
            );
            equipmentType = matchedEquipment.workId;
          } catch (_) {}
        }
      }

      emit(FacilityDropdownsLoaded(
        equipments:                  equipments,
        factories:                   factories,
        productionAreas:             productionAreas,
        zones:                       zones,
        productionLines:             productionLines,
        deviceTypes:                 deviceTypes,
        selectedFactoryId:           matchedFactoryId,
        selectedFactoryName:         matchedFactoryName,
        selectedProductionAreaId:    matchedAreaId,
        selectedProductionAreaName:  matchedAreaName,
        selectedPlantId:             matchedPlantId,
        selectedPlantName:           matchedPlantName,
        selectedProductionLineId:    matchedLineId,
        selectedProductionLineName:  matchedLineName,
        selectedEquipment:           matchedEquipment,
        equipmentType:               equipmentType,
        selectedDeviceType:          matchedDeviceType,
        status:                      status,
        impactCategory:              impactCategory,
        maintenanceDate:             maintenanceDate,
        lastMaintenanceDate:         lastMaintenanceDate,
        nextMaintenanceDate:         nextMaintenanceDate,
        registrationDate:            registrationDate,
      ));
    } catch (e) {
      emit(FacilityDropdownsError(e.toString()));
    }
  }

  // ── Selections ────────────────────────────────────────────────────────────

  void selectFactory(String? id, String? name) {
    final s = _loaded; if (s == null) return;
    emit(s.copyWith(
      selectedFactoryId:   id,
      selectedFactoryName: name,
    ));
  }

  void selectProductionArea(
    String? id,
    String? name, {
    void Function(String name)? onPlantAutoFill,
  }) {
    final s = _loaded; if (s == null) return;
    if (onPlantAutoFill != null && name != null && name != 'Not Assigned') {
      onPlantAutoFill(name);
    }
    emit(s.copyWith(
      selectedProductionAreaId:   id,
      selectedProductionAreaName: name,
    ));
  }

  /// Select Plant — linked from General Factory Setting / Plant (/factory API)
  void selectPlant(String? id, String? name) {
    final s = _loaded; if (s == null) return;
    emit(s.copyWith(
      selectedPlantId:   id,
      selectedPlantName: name,
    ));
  }

  /// Select Production Line — linked from General Factory Setting / Production Line (/productionLines API)
  void selectProductionLine(String? id, String? name) {
    final s = _loaded; if (s == null) return;
    emit(s.copyWith(
      selectedProductionLineId:   id,
      selectedProductionLineName: name,
    ));
  }

  /// Selecting an equipment (via the Equipment Name picker or the Equipment ID
  /// dropdown) auto-syncs Site/Plant, Machine/Factory, Zone, Line and Device
  /// Type directly from that equipment's own record in Equipment Settings —
  /// no matching against a separate list required. If the equipment's raw
  /// value isn't already one of the dropdown's options, it's added so the
  /// field can display/keep it selected (fields stay editable afterwards).
  void selectEquipment(EquipmentItem? item) {
    final s = _loaded; if (s == null) return;
    if (item == null) {
      emit(s.copyWith(clearEquipment: true, equipmentType: ''));
      return;
    }

    List<Map<String, dynamic>> withValue(List<Map<String, dynamic>> list, String value) {
      final v = value.trim();
      if (v.isEmpty) return list;
      if (list.any((e) => (e['name']?.toString() ?? '') == v)) return list;
      return [...list, {'id': v, 'name': v}];
    }

    final plant   = item.factory.trim();
    final machine = item.name.trim();
    final zone    = item.productionArea.trim();
    final line    = item.productionLine.trim();
    final dtype   = item.deviceType.trim();

    emit(s.copyWith(
      factories:                  withValue(s.factories, plant),
      productionAreas:            withValue(s.productionAreas, machine),
      zones:                      withValue(s.zones, zone),
      productionLines:            withValue(s.productionLines, line),
      deviceTypes:                withValue(s.deviceTypes, dtype),
      selectedEquipment:          item,
      equipmentType:              item.workId,
      selectedPlantId:            plant.isNotEmpty ? plant : s.selectedPlantId,
      selectedPlantName:          plant.isNotEmpty ? plant : s.selectedPlantName,
      selectedFactoryId:          machine.isNotEmpty ? machine : s.selectedFactoryId,
      selectedFactoryName:        machine.isNotEmpty ? machine : s.selectedFactoryName,
      selectedProductionAreaId:   zone.isNotEmpty ? zone : s.selectedProductionAreaId,
      selectedProductionAreaName: zone.isNotEmpty ? zone : s.selectedProductionAreaName,
      selectedProductionLineId:   line.isNotEmpty ? line : s.selectedProductionLineId,
      selectedProductionLineName: line.isNotEmpty ? line : s.selectedProductionLineName,
      selectedDeviceType:         dtype.isNotEmpty ? dtype : s.selectedDeviceType,
    ));
  }

  /// Select an equipment by its equipment_id (the new Equipment ID dropdown).
  /// Delegates to [selectEquipment] so the same auto-sync runs.
  void selectEquipmentById(String? equipmentId) {
    final s = _loaded; if (s == null) return;
    if (equipmentId == null || equipmentId.isEmpty) { selectEquipment(null); return; }
    EquipmentItem? found;
    for (final e in s.equipments) {
      if (e.equipmentId == equipmentId) { found = e; break; }
    }
    selectEquipment(found);
  }

  void selectDeviceType(String? name) {
    final s = _loaded; if (s == null) return;
    emit(s.copyWith(selectedDeviceType: name));
  }

  void setStatus(String status) {
    final s = _loaded; if (s == null) return;
    emit(s.copyWith(status: status));
  }

  void setImpactCategory(String category) {
    final s = _loaded; if (s == null) return;
    emit(s.copyWith(impactCategory: category));
  }

  void setDate(String field, DateTime date) {
    final s = _loaded; if (s == null) return;
    emit(s.copyWith(
      maintenanceDate:     field == 'maintenance'     ? date : s.maintenanceDate,
      lastMaintenanceDate: field == 'lastMaintenance' ? date : s.lastMaintenanceDate,
      nextMaintenanceDate: field == 'nextMaintenance' ? date : s.nextMaintenanceDate,
      registrationDate:    field == 'registration'    ? date : s.registrationDate,
    ));
  }

  // ── Submit — Create ───────────────────────────────────────────────────────
  Future<void> submitCreate({
    required String meterName,
    required String meterId,
    required String gatewayId,
    required String gridType,
    required Future<void> Function(Map<String, dynamic>) onCreated,
  }) async {
    final s = _loaded; if (s == null) return;
    emit(const FacilitySubmitting());
    try {
      await onCreated({
        'plant':               s.selectedPlantName            ?? '',
        'factory':             s.selectedFactoryName          ?? '',
        'zone':                s.selectedProductionAreaName   ?? '',
        'productionArea':      s.selectedProductionLineName   ?? '',
        'equipmentType':       s.selectedDeviceType ?? s.equipmentType,
        'equipmentNameId':     s.selectedEquipment?.displayLabel ?? '',
        'meterName':           meterName,
        'meterId':             meterId,
        'gatewayId':           gatewayId,
        'gridType':            gridType,
        'status':              s.status,
        'impactCategory':      s.impactCategory,
        'maintenanceDate':     _formatDate(s.maintenanceDate),
        'lastMaintenanceDate': _formatDate(s.lastMaintenanceDate),
        'nextMaintenanceDate': _formatDate(s.nextMaintenanceDate),
        'registrationDate':    _formatDate(s.registrationDate),
      });
      emit(const FacilitySubmitSuccess());
    } catch (e) {
      emit(FacilitySubmitError(e.toString()));
    }
  }

  // ── Submit — Update ───────────────────────────────────────────────────────
  Future<void> submitUpdate({
    required String meterName,
    required String meterId,
    required String gatewayId,
    required String gridType,
    required Map<String, dynamic> initialData,
    required Future<void> Function() onUpdated,
  }) async {
    final s = _loaded; if (s == null) return;
    emit(const FacilitySubmitting());
    try {
      initialData
        ..['plant']               = s.selectedPlantName            ?? ''
        ..['factory']             = s.selectedFactoryName          ?? ''
        ..['zone']                = s.selectedProductionAreaName   ?? ''
        ..['productionArea']      = s.selectedProductionLineName   ?? ''
        ..['equipmentType']       = s.selectedDeviceType ?? s.equipmentType
        ..['equipmentNameId']     = s.selectedEquipment?.displayLabel ?? ''
        ..['meterName']           = meterName
        ..['meterId']             = meterId
        ..['gatewayId']           = gatewayId
        ..['gridType']            = gridType
        ..['status']              = s.status
        ..['impactCategory']      = s.impactCategory
        ..['maintenanceDate']     = _formatDate(s.maintenanceDate)
        ..['lastMaintenanceDate'] = _formatDate(s.lastMaintenanceDate)
        ..['nextMaintenanceDate'] = _formatDate(s.nextMaintenanceDate)
        ..['registrationDate']    = _formatDate(s.registrationDate);

      await onUpdated();
      emit(const FacilitySubmitSuccess());
    } catch (e) {
      emit(FacilitySubmitError(e.toString()));
    }
  }

  // ── Retry after error ─────────────────────────────────────────────────────
  Future<void> retry({Map<String, dynamic>? initialData}) async {
    await loadDropdowns(initialData: initialData);
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  FacilityDropdownsLoaded? get _loaded =>
      state is FacilityDropdownsLoaded ? state as FacilityDropdownsLoaded : null;

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final p = raw.split('/');
      if (p.length != 3) return null;
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return null;
    }
  }
}