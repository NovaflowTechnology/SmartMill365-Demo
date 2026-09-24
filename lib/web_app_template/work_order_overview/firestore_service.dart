import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');
  final CollectionReference _workOrderCollection =
      FirebaseFirestore.instance.collection('workOrders');

  Future<List<Map<String, dynamic>>> fetchWorkOrders() async {
    try {
      QuerySnapshot snapshot = await _workOrderCollection.get();
      List<Map<String, dynamic>> workOrderList = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      workOrderList
          .sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));

      return workOrderList;
    } catch (e) {
      throw Exception('Error fetching work orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchWorkOrdersByCompany(
      String companyID) async {
    try {
      QuerySnapshot snapshot = await _workOrderCollection
          .where('company_id', isEqualTo: companyID)
          .get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        Timestamp timestamp = data['planDate'] as Timestamp;
        data['planDate'] = timestamp.toDate().toString();
        Timestamp timestamp1 = data['actualDate'] as Timestamp;
        data['actualDate'] = timestamp1.toDate().toString();
        Timestamp timestamp2 = data['planCDate'] as Timestamp;
        data['planCDate'] = timestamp2.toDate().toString();
        Timestamp timestamp3 = data['actualCDate'] as Timestamp;
        data['actualCDate'] = timestamp3.toDate().toString();
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching work orders: $e');
    }
  }

  Future<void> addWorkOrder(
      String id,
      String saleOrderID,
      String name,
      String productID,
      int quantity,
      String unit,
      Timestamp planSDate,
      Timestamp actuaSlDate,
      String status,
      Timestamp planCDate,
      Timestamp actualCDate,
      int workProgress,
      String companyId) async {
    try {
      QuerySnapshot querySnapshot = await _workOrderCollection
          .where('sale_id', isEqualTo: saleOrderID)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('A equipment with the same serial no. already exists.');
      }
      await _workOrderCollection.doc(id).set({
        'sale_id': saleOrderID,
        'name': name,
        'product_id': productID,
        'quantity': quantity,
        'unit': unit,
        'planDate': planSDate,
        'actualDate': actuaSlDate,
        'status': status,
        'planCDate': planCDate,
        'actualCDate': actualCDate,
        'workProgress': workProgress,
        'company_id': companyId
      });
    } catch (e) {
      throw Exception('Error adding equipment: $e');
    }
  }

  String generateNextWorkOrderId(List<String> existingIds) {
    if (existingIds.isEmpty) {
      return 'W0001';
    } else {
      existingIds.sort();
      String lastId = existingIds.last;
      int numericPart = int.parse(lastId.substring(1));
      String nextId = 'W${(numericPart + 1).toString().padLeft(4, '0')}';
      return nextId;
    }
  }

  Future<void> addWorkOrderWithGeneratedId(
      String saleOrderID,
      String name,
      String productID,
      int quantity,
      String unit,
      Timestamp planSDate,
      Timestamp actuaSlDate,
      String status,
      Timestamp planCDate,
      Timestamp actualCDate,
      int workProgress,
      String companyId) async {
    try {
      QuerySnapshot snapshot = await _workOrderCollection.get();
      List<String> existingIds = snapshot.docs.map((doc) => doc.id).toList();
      String nextWorkOrderId = generateNextWorkOrderId(existingIds);
      await addWorkOrder(
          nextWorkOrderId,
          saleOrderID,
          name,
          productID,
          quantity,
          unit,
          planSDate,
          actuaSlDate,
          status,
          planCDate,
          actualCDate,
          workProgress,
          companyId);
    } catch (e) {
      throw Exception('Error adding equipment with custom ID: $e');
    }
  }

  Future<void> editWorkOrder(
      String id,
      String name,
      String saleOrderID,
      String productID,
      int quantity,
      String unit,
      Timestamp planSDate,
      Timestamp actuaSlDate,
      String status,
      Timestamp planCDate,
      Timestamp actualCDate,
      int workProgress) async {
    try {
      await _workOrderCollection.doc(id).update({
        'sale_id': saleOrderID,
        'name': name,
        'product_id': productID,
        'quantity': quantity,
        'unit': unit,
        'planDate': planSDate,
        'actualDate': actuaSlDate,
        'status': status,
        'planCDate': planCDate,
        'actualCDate': actualCDate,
        'workProgress': workProgress
      });
    } catch (e) {
      throw Exception('Error editing equipment: $e');
    }
  }

  Future<void> deleteWorkOrder(String id) async {
    try {
      await _workOrderCollection.doc(id).delete();
      final QuerySnapshot deviceSnapshot =
          await _equipmentCollection.where('work_id', isEqualTo: id).get();
      for (var doc in deviceSnapshot.docs) {
        await doc.reference.update({'work_id': '0'});
      }
    } catch (e) {
      throw Exception('Error deleting equipment: $e');
    }
  }

  // Future<List<String>> fetchEquipmentWorkIds() async {
  //   try {
  //     QuerySnapshot snapshot = await _equipmentCollection.get();
  //     return snapshot.docs.map((doc) {
  //       var data = doc.data() as Map<String, dynamic>;
  //       return data['work_id'] as String;
  //     }).toList();
  //   } catch (e) {
  //     throw Exception('Error fetching equipment work IDs: $e');
  //   }
  // }
}
