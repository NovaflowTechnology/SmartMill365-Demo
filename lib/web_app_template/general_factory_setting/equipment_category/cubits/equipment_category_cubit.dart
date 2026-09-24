import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/equipment_category_template.dart';
import '../services/equipment_category_service.dart';

// ── States ────────────────────────────────────────────────────────────────────
abstract class EquipmentCategoryState {}

class EquipmentCategoryInitial extends EquipmentCategoryState {}

class EquipmentCategoryLoading extends EquipmentCategoryState {}

class EquipmentCategoryPageLoaded extends EquipmentCategoryState {
  final List<Map<String, dynamic>> categoryGroups;
  final List<Map<String, dynamic>> equipmentTypes;

  EquipmentCategoryPageLoaded({
    required this.categoryGroups,
    required this.equipmentTypes,
  });
}

class EquipmentCategoryError extends EquipmentCategoryState {
  final String message;
  EquipmentCategoryError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class EquipmentCategoryCubit extends Cubit<EquipmentCategoryState> {
  final EquipmentCategoryService _service;
  final String factoryId;
  final String userId;

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _types  = [];

  EquipmentCategoryCubit({
    required EquipmentCategoryService service,
    required this.factoryId,
    required this.userId,
  })  : _service = service,
        super(EquipmentCategoryInitial());

  void _emitLoaded() => emit(EquipmentCategoryPageLoaded(
        categoryGroups: List.from(_groups),
        equipmentTypes: List.from(_types),
      ));

  // ── Load — seed template on first access if backend has no data ────────────
  Future<void> fetchAll() async {
    if (factoryId.isEmpty) {
      emit(EquipmentCategoryError(
        'Factory ID is not configured for your account.\nPlease contact your administrator.',
      ));
      return;
    }

    emit(EquipmentCategoryLoading());
    try {
      _groups = await _service.fetchCategoryGroups(factoryId: factoryId);
      _types  = await _service.fetchCategories(factoryId: factoryId, userId: userId);

      // First-time access: seed default data into the backend so it persists
      if (_groups.isEmpty) {
        await _seedGroups();
        _groups = await _service.fetchCategoryGroups(factoryId: factoryId);
      }
      if (_types.isEmpty) {
        await _seedTypes();
        _types = await _service.fetchCategories(factoryId: factoryId, userId: userId);
      }

      _emitLoaded();
    } catch (e) {
      emit(EquipmentCategoryError('Failed to load equipment categories.'));
    }
  }

  /// Seeds all default category groups for this factory into the backend.
  Future<int> _seedGroups() async {
    int seeded = 0;
    for (final template in kEquipmentCategoryGroupTemplate) {
      final payload = Map<String, dynamic>.from(template)..remove('id');
      try {
        final ok = await _service.createCategoryGroup(payload, factoryId: factoryId);
        if (ok) {
          seeded++;
        } else {
          debugPrint('Seed group returned false for: ${payload['name']}');
        }
      } catch (e) {
        debugPrint('Seed group failed: $e');
      }
    }
    debugPrint('_seedGroups: seeded $seeded/${kEquipmentCategoryGroupTemplate.length} groups for factoryId="$factoryId"');
    return seeded;
  }

  /// Seeds all default equipment types for this factory into the backend.
  Future<int> _seedTypes() async {
    int seeded = 0;
    for (final template in kEquipmentCategoryTemplate) {
      final payload = Map<String, dynamic>.from(template)..remove('id');
      try {
        final ok = await _service.createCategory(payload, factoryId: factoryId);
        if (ok) {
          seeded++;
        } else {
          debugPrint('Seed type returned false for: ${payload['device_type']}');
        }
      } catch (e) {
        debugPrint('Seed type failed: $e');
      }
    }
    debugPrint('_seedTypes: seeded $seeded/${kEquipmentCategoryTemplate.length} types for factoryId="$factoryId"');
    return seeded;
  }

  /// Backward-compat alias
  Future<void> fetchCategories() => fetchAll();

  // ── Category Group CRUD ────────────────────────────────────────────────────

  Future<bool> createGroup(Map<String, dynamic> payload) async {
    final ok = await _service.createCategoryGroup(payload, factoryId: factoryId);
    if (ok) await fetchAll();
    return ok;
  }

  Future<bool> updateGroup(String id, Map<String, dynamic> payload) async {
    final ok = await _service.updateCategoryGroup(id, payload, factoryId: factoryId);
    if (ok) await fetchAll();
    return ok;
  }

  Future<bool> deleteGroup(String id) async {
    final ok = await _service.deleteCategoryGroup(id, factoryId: factoryId);
    if (ok) await fetchAll();
    return ok;
  }

  // ── Equipment Type CRUD ────────────────────────────────────────────────────

  Future<bool> createCategory(Map<String, dynamic> payload) async {
    final ok = await _service.createCategory(payload, factoryId: factoryId);
    if (ok) await fetchAll();
    return ok;
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> payload) async {
    final ok = await _service.updateCategory(id, payload, factoryId: factoryId);
    if (ok) await fetchAll();
    return ok;
  }

  Future<bool> deleteCategory(String id) async {
    final ok = await _service.deleteCategory(id, factoryId: factoryId);
    if (ok) await fetchAll();
    return ok;
  }
}
