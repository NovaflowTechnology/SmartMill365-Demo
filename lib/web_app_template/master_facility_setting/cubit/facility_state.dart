part of 'facility_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FacilityState — all possible states for the facility dialogs
// ─────────────────────────────────────────────────────────────────────────────

abstract class FacilityState extends Equatable {
  const FacilityState();

  @override
  List<Object?> get props => [];
}

/// Before anything has loaded
class FacilityInitial extends FacilityState {
  const FacilityInitial();
}

/// Dropdown data is loading
class FacilityDropdownsLoading extends FacilityState {
  const FacilityDropdownsLoading();
}

/// Dropdown data failed to load
class FacilityDropdownsError extends FacilityState {
  final String message;
  const FacilityDropdownsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Dropdown data loaded — main working state
/// All selections live here so widgets are fully driven by state
class FacilityDropdownsLoaded extends FacilityState {
  final List<EquipmentItem>        equipments;
  final List<Map<String, dynamic>> factories;       // Site / Plant values
  final List<Map<String, dynamic>> productionAreas; // Machine / Factory values
  final List<Map<String, dynamic>> zones;           // Zone values
  final List<Map<String, dynamic>> productionLines; // Line / Prod. Area values
  final List<Map<String, dynamic>> deviceTypes;

  // Selections
  final String?        selectedFactoryId;
  final String?        selectedFactoryName;
  final String?        selectedProductionAreaId;
  final String?        selectedProductionAreaName;
  final String?        selectedPlantId;
  final String?        selectedPlantName;
  final String?        selectedProductionLineId;
  final String?        selectedProductionLineName;
  final EquipmentItem? selectedEquipment;
  final String         equipmentType;
  final String?        selectedDeviceType;

  // Form fields managed by Cubit
  final String    status;
  final String    impactCategory;
  final DateTime? maintenanceDate;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final DateTime? registrationDate;

  const FacilityDropdownsLoaded({
    required this.equipments,
    required this.factories,
    required this.productionAreas,
    this.zones                       = const [],
    this.productionLines             = const [],
    this.deviceTypes                 = const [],
    this.selectedFactoryId,
    this.selectedFactoryName,
    this.selectedProductionAreaId,
    this.selectedProductionAreaName,
    this.selectedPlantId,
    this.selectedPlantName,
    this.selectedProductionLineId,
    this.selectedProductionLineName,
    this.selectedEquipment,
    this.equipmentType       = '',
    this.selectedDeviceType,
    this.status              = 'Active',
    this.impactCategory      = 'PRODUCTION',
    this.maintenanceDate,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.registrationDate,
  });

  FacilityDropdownsLoaded copyWith({
    List<EquipmentItem>?        equipments,
    List<Map<String, dynamic>>? factories,
    List<Map<String, dynamic>>? productionAreas,
    List<Map<String, dynamic>>? zones,
    List<Map<String, dynamic>>? productionLines,
    List<Map<String, dynamic>>? deviceTypes,
    String?                     selectedFactoryId,
    String?                     selectedFactoryName,
    String?                     selectedProductionAreaId,
    String?                     selectedProductionAreaName,
    String?                     selectedPlantId,
    String?                     selectedPlantName,
    bool                        clearPlant = false,
    String?                     selectedProductionLineId,
    String?                     selectedProductionLineName,
    bool                        clearProductionLine = false,
    EquipmentItem?              selectedEquipment,
    bool                        clearEquipment = false,
    String?                     equipmentType,
    Object?                     selectedDeviceType = _sentinel,
    String?                     status,
    String?                     impactCategory,
    DateTime?                   maintenanceDate,
    DateTime?                   lastMaintenanceDate,
    DateTime?                   nextMaintenanceDate,
    DateTime?                   registrationDate,
  }) {
    return FacilityDropdownsLoaded(
      equipments:                 equipments                 ?? this.equipments,
      factories:                  factories                  ?? this.factories,
      productionAreas:            productionAreas            ?? this.productionAreas,
      zones:                      zones                      ?? this.zones,
      productionLines:            productionLines            ?? this.productionLines,
      deviceTypes:                deviceTypes                ?? this.deviceTypes,
      selectedFactoryId:          selectedFactoryId           ?? this.selectedFactoryId,
      selectedFactoryName:        selectedFactoryName         ?? this.selectedFactoryName,
      selectedProductionAreaId:   selectedProductionAreaId   ?? this.selectedProductionAreaId,
      selectedProductionAreaName: selectedProductionAreaName ?? this.selectedProductionAreaName,
      selectedPlantId:            clearPlant ? null        : (selectedPlantId   ?? this.selectedPlantId),
      selectedPlantName:          clearPlant ? null        : (selectedPlantName ?? this.selectedPlantName),
      selectedProductionLineId:   clearProductionLine ? null : (selectedProductionLineId   ?? this.selectedProductionLineId),
      selectedProductionLineName: clearProductionLine ? null : (selectedProductionLineName ?? this.selectedProductionLineName),
      selectedEquipment:          clearEquipment ? null      : (selectedEquipment ?? this.selectedEquipment),
      equipmentType:              equipmentType              ?? this.equipmentType,
      selectedDeviceType:         selectedDeviceType == _sentinel
          ? this.selectedDeviceType
          : selectedDeviceType as String?,
      status:                     status                     ?? this.status,
      impactCategory:             impactCategory             ?? this.impactCategory,
      maintenanceDate:            maintenanceDate            ?? this.maintenanceDate,
      lastMaintenanceDate:        lastMaintenanceDate         ?? this.lastMaintenanceDate,
      nextMaintenanceDate:        nextMaintenanceDate         ?? this.nextMaintenanceDate,
      registrationDate:           registrationDate            ?? this.registrationDate,
    );
  }

  @override
  List<Object?> get props => [
    equipments, factories, productionAreas, zones, productionLines, deviceTypes,
    selectedFactoryId, selectedFactoryName,
    selectedProductionAreaId, selectedProductionAreaName,
    selectedPlantId, selectedPlantName,
    selectedProductionLineId, selectedProductionLineName,
    selectedEquipment, equipmentType, selectedDeviceType,
    status, impactCategory,
    maintenanceDate, lastMaintenanceDate,
    nextMaintenanceDate, registrationDate,
  ];
}

const _sentinel = Object();

/// Form is being submitted
class FacilitySubmitting extends FacilityState {
  const FacilitySubmitting();
}

/// Form submitted successfully — triggers dialog pop via BlocListener
class FacilitySubmitSuccess extends FacilityState {
  const FacilitySubmitSuccess();
}

/// Submit failed
class FacilitySubmitError extends FacilityState {
  final String message;
  const FacilitySubmitError(this.message);

  @override
  List<Object?> get props => [message];
}