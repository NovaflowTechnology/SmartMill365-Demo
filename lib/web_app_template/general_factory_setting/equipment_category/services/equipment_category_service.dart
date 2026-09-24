import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EquipmentCategoryService {
  static final _db = FirebaseFirestore.instance;

  // ── Category Groups ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchCategoryGroups({
    String? factoryId,
  }) async {
    try {
      final snap = await _db
          .collection('equipmentCategoryGroups')
          .where('factory_id', isEqualTo: factoryId ?? '')
          .get();
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return docs;
    } catch (e) {
      debugPrint('fetchCategoryGroups exception: $e');
      return [];
    }
  }

  Future<bool> createCategoryGroup(
    Map<String, dynamic> payload, {
    String? factoryId,
  }) async {
    try {
      final data = Map<String, dynamic>.from(payload)
        ..remove('id')
        ..['factory_id'] = factoryId ?? '';
      await _db.collection('equipmentCategoryGroups').add(data);
      return true;
    } catch (e) {
      debugPrint('createCategoryGroup exception: $e');
      return false;
    }
  }

  Future<bool> updateCategoryGroup(
    String id,
    Map<String, dynamic> payload, {
    String? factoryId,
  }) async {
    try {
      final data = Map<String, dynamic>.from(payload)
        ..remove('id')
        ..['factory_id'] = factoryId ?? '';
      await _db.collection('equipmentCategoryGroups').doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('updateCategoryGroup exception: $e');
      return false;
    }
  }

  Future<bool> deleteCategoryGroup(String id, {String? factoryId}) async {
    try {
      await _db.collection('equipmentCategoryGroups').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteCategoryGroup exception: $e');
      return false;
    }
  }

  // ── Equipment Types ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchCategories({
    String? factoryId,
    String? userId,
  }) async {
    try {
      final snap = await _db
          .collection('equipmentCategories')
          .where('factory_id', isEqualTo: factoryId ?? '')
          .get();
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) => (a['device_type'] as String).compareTo(b['device_type'] as String));
      return docs;
    } catch (e) {
      debugPrint('fetchCategories exception: $e');
      return [];
    }
  }

  Future<bool> createCategory(
    Map<String, dynamic> payload, {
    String? factoryId,
  }) async {
    try {
      final data = Map<String, dynamic>.from(payload)
        ..remove('id')
        ..['factory_id'] = factoryId ?? '';
      await _db.collection('equipmentCategories').add(data);
      return true;
    } catch (e) {
      debugPrint('createCategory exception: $e');
      return false;
    }
  }

  Future<bool> updateCategory(
    String id,
    Map<String, dynamic> payload, {
    String? factoryId,
  }) async {
    try {
      final data = Map<String, dynamic>.from(payload)
        ..remove('id')
        ..['factory_id'] = factoryId ?? '';
      await _db.collection('equipmentCategories').doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('updateCategory exception: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(String id, {String? factoryId}) async {
    try {
      await _db.collection('equipmentCategories').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('deleteCategory exception: $e');
      return false;
    }
  }
}
