import 'package:cloud_firestore/cloud_firestore.dart';

class WorkOrderRepository {
  WorkOrderRepository();

  final CollectionReference _productCollection =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference _downTimeCodeCollection =
      FirebaseFirestore.instance.collection('downTimeCodes');
  final CollectionReference _workOrderCollection =
      FirebaseFirestore.instance.collection('workOrders');
  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');

  Future<List<Map<String, dynamic>>> get productList async {
    try {
      QuerySnapshot snapshot = await _productCollection.get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> product = {};
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        product['id'] = doc.id;
        product['name'] = data['name'];

        return product;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get urgencyList => [
        {'id': '2', 'name': 'Standard'},
        {'id': '1', 'name': 'High'},
      ];

  Future<List<Map<String, dynamic>>> get downTimeCodeList async {
    try {
      QuerySnapshot snapshot = await _downTimeCodeCollection
          .where('isPlanned', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> downTimeCode = {};
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        downTimeCode['id'] = doc.id;
        downTimeCode['description'] = data['description'];

        return downTimeCode;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addWorkOrder(
      {required String id, required Map<String, dynamic> data}) async {
    try {
      await _workOrderCollection.doc(id).set(data);
    } catch (error) {
      throw Exception(error);
    }
  }

  Future<void> updateWorkOrder(
      {required String id, required Map<String, dynamic> data}) async {
    try {
      await _workOrderCollection.doc(id).update(data);
    } catch (error) {
      throw Exception(error);
    }
  }

  Future<void> deleteWorkOrder(String id) async {
    try {
      await _workOrderCollection.doc(id).delete();

      QuerySnapshot snapshot =
          await _equipmentCollection.where('work_id', arrayContains: id).get();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> workOrderList = List<String>.from(data['work_id']);

        workOrderList.remove(id);
        await doc.reference.update({'work_id': workOrderList});
      }
    } catch (error) {
      throw Exception(error);
    }
  }
}
