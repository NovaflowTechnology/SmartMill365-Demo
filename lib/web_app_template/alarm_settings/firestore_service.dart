import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference alarmCollection =
      FirebaseFirestore.instance.collection('alarms');
  final CollectionReference equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');
  final CollectionReference deviceCollection =
      FirebaseFirestore.instance.collection('devices');

  Future<List<Map<String, dynamic>>> fetchDevice() async {
    try {
      QuerySnapshot snapshot = await deviceCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching devices: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchEquipment() async {
    try {
      QuerySnapshot snapshot = await equipmentCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching equipments: $e');
    }
  }
  
  Future<void> editAlarmESOP(
      String id,
      String esop) async {
    try {
      await alarmCollection.doc(id).update({
        'esop': esop,
      });
    } catch (e) {
      throw Exception('Error editing alarm: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAlarm() async {
    try {
      QuerySnapshot snapshot = await alarmCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching alarm : $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAlarmByCompany(String companyId) async {
    try {
      QuerySnapshot snapshot = await alarmCollection.where('company_id', isEqualTo: companyId).get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching alarm : $e');
    }
  }

  Future<void> deleteAlarm(String id) async {
    try {
      await alarmCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting alarm: $e');
    }
  }

  Future<void> addAlarm(
      String id,
      String name,
      String device,
      String message,
      String minimum,
      String maximum,
      String pic,
      String esop,
      String companyId) async {
    try {
      QuerySnapshot querySnapshot =
          await alarmCollection.where('name', isEqualTo: name).get();
      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('A alarm with the same name already exists.');
      }
      await alarmCollection.doc(id).set({
        'name': name,
        'device_id': device,
        'message': message,
        'threshold_minimum': minimum,
        'threshold_maximum': maximum,
        'esop': esop,
        'pic': pic,
        'status': true,
        'company_id': companyId,
      });
    } catch (e) {
      throw Exception('Error adding alarm: $e');
    }
  }

  String generateNextAlarmId(List<String> existingIds) {
    if (existingIds.isEmpty) {
      return 'A0001';
    } else {
      existingIds.sort();
      String lastId = existingIds.last;
      int numericPart = int.parse(lastId.substring(1));
      String nextId = 'A${(numericPart + 1).toString().padLeft(4, '0')}';
      return nextId;
    }
  }

  Future<void> addAlarmWithGeneratedId(
      String name,
      String device,
      String message,
      String minimum,
      String maximum,
      String pic,
      String esop,
      String companyId) async {
    try {
      QuerySnapshot snapshot = await alarmCollection.get();
      List<String> existingIds = snapshot.docs.map((doc) => doc.id).toList();

      String nextAlarmId = generateNextAlarmId(existingIds);

      await addAlarm(nextAlarmId, name, device, message, minimum, maximum, pic, esop, companyId);
    } catch (e) {
      throw Exception('Error adding alarm with custom ID: $e');
    }
  }

  Future<void> editAlarm(
      String id,
      String name,
      String device,
      String message,
      String minimum,
      String maximum,
      String pic,
      String esop) async {
    try {
      await alarmCollection.doc(id).update({
        'name': name,
        'device_id': device,
        'message': message,
        'threshold_minimum': minimum,
        'threshold_maximum': maximum,
        'pic': pic,
        'esop': esop,
      });
    } catch (e) {
      throw Exception('Error editing alarm: $e');
    }
  }

  Future<String> fetchESOPById(String id) async {
    try {
      DocumentSnapshot doc = await alarmCollection.doc(id).get();
      if (doc.exists) {
        return doc.get('esop') ?? '';
      } else {
        throw Exception("Alarm with ID $id not found");
      }
    } catch (e) {
      print("Error fetching ESOP: $e");
      rethrow;
    }
  }
}
