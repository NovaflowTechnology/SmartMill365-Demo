import 'package:cloud_firestore/cloud_firestore.dart';

class WorkOrderReportRepository {
  WorkOrderReportRepository();

  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');
  final CollectionReference _workOrderCollection =
      FirebaseFirestore.instance.collection('workOrders');

  Future<List<Map<String, dynamic>>> get equipmentList async {
    try {
      QuerySnapshot snapshot = await _equipmentCollection.get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> equipment = {};
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        equipment['id'] = doc.id;
        equipment['name'] = data['name'];

        return equipment;
      }).toList();
    } catch (_) {
      return [];
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
}
