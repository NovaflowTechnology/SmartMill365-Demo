import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService();

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

      workOrderList.sort(
          (a, b) => a['urgency'].toString().compareTo(b['urgency'].toString()));

      return workOrderList;
    } catch (e) {
      throw Exception('Error fetching work orders: $e');
    }
  }
}
