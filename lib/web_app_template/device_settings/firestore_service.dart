import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';


class FirestoreService {
  final CollectionReference _devicesCollection =
      FirebaseFirestore.instance.collection('devices');
  final CollectionReference _equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');
  final CollectionReference _productionAreaCollection =
      FirebaseFirestore.instance.collection('productionAreas');
  final CollectionReference _factoryCollection =
      FirebaseFirestore.instance.collection('factories');
  final Queue<String> _topicQueue = Queue<String>();
  bool _isProcessing = false;
  StreamSubscription<DatabaseEvent>? _topicSubscription;

  void dispose() {
    _topicSubscription?.cancel();
  }

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> addDevice(
    String id,
    String deviceName,
    String equipmentID,
    String topic,
    String channelName,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await _devicesCollection.where('device_name', isEqualTo: deviceName).get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('A device with the same name already exists.');
      }

      await _devicesCollection.doc(id).set({
        'device_name': deviceName,
        'equipment_id': equipmentID,
        'topic': topic,
        'channel_name': channelName,
        'productionArea':"0",
        "factory_id": "0",
      });
      print("Device added: $id with channel $channelName for topic $topic");
    } catch (e) {
      throw Exception('Error adding device: $e');
    }
  }

  Future<String> getNextDeviceId() async {
    try {
      QuerySnapshot snapshot = await _devicesCollection.get();
      if (snapshot.docs.isEmpty) {
        return 'D0001';
      }
      int maxNumber = 0;
      for (var doc in snapshot.docs) {
        String id = doc.id;
        if (id.startsWith('D')) {
          int currentNumber = int.tryParse(id.substring(1)) ?? 0;
          if (currentNumber > maxNumber) {
            maxNumber = currentNumber;
          }
        }
      }
      return 'D${(maxNumber + 1).toString().padLeft(4, '0')}';
    } catch (e) {
      throw Exception('Error generating next device ID: $e');
    }
  }

  Future<bool> addDeviceWithGeneratedId(
    String deviceName,
    String equipmentID,
    String topic,
    String channelName,
  ) async {
    try {
      if (await checkDeviceExists(topic, channelName)) {
        print(
            "Device with topic $topic and channel $channelName already exists. Skipping.");
        return false;
      }
      String nextDeviceId = await getNextDeviceId();
      await addDevice(
          nextDeviceId, deviceName, equipmentID, topic, channelName);
      return true;
    } catch (e) {
      throw Exception('Error adding device with generated ID: $e');
    }
  }

  Future<bool> checkDeviceExists(String topic, String channelName) async {
    try {
      QuerySnapshot existingDevices = await _devicesCollection
          .where('topic', isEqualTo: topic)
          .where('channel_name', isEqualTo: channelName)
          .get();
      return existingDevices.docs.isNotEmpty;
    } catch (e) {
      print("Error checking for existing devices: $e");
      return false;
    }
  }

  Future<void> _processNextTopic() async {
    if (_isProcessing) return;

    _isProcessing = true;
    try {
      while (_topicQueue.isNotEmpty) {
        String topic = _topicQueue.removeFirst();
        await fetchAndStoreTopicData(topic);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> startListeningForTopics() async {
    try {
      await _topicSubscription?.cancel();
      _topicSubscription =
          _dbRef.onChildAdded.listen((DatabaseEvent event) async {
        String topic = event.snapshot.key!;
        print("New topic detected: $topic");
        _topicQueue.add(topic);
        if (!_isProcessing) {
          await _processNextTopic();
        }
      }, onError: (error) {
        print("Error in topic listener: $error");
      });
    } catch (e) {
      print("Error occurred: $e");
      throw Exception('Error listening for new topics: $e');
    }
  }

  Future<void> fetchAndStoreTopicData(String topic) async {
    DatabaseReference topicRef = _dbRef.child(topic);
    try {
      print("Starting to process topic: $topic");
      DataSnapshot snapshot = await topicRef.limitToLast(1).get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> topicData =
            Map<dynamic, dynamic>.from(snapshot.value as Map);
        String equipmentID = '0';
        for (var entry in topicData.entries) {
          var channels = entry.value;
          if (channels is! Map) continue;
          List<String> channelNames = [];
          for (var channel in channels.keys) {
            if (channel.toString().startsWith('ch')) {
              channelNames.add(channel.toString());
            }
          }
          channelNames.sort();
          for (var channel in channelNames) {
            String deviceName = "$topic _ $channel";
            bool added = await addDeviceWithGeneratedId(
              deviceName,
              equipmentID,
              topic,
              channel,
            );
            if (added) {
              print("Stored channel $channel for topic $topic as device $deviceName");
            }
          }
        }
        print("Completed processing all channels for topic $topic");
      } else {
        print("No data found for topic $topic.");
      }
    } catch (e) {
      print("Error fetching data for topic $topic: $e");
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> fetchDevices() async {
    try {
      QuerySnapshot snapshot = await _devicesCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching devices: $e');
    }
  }

  Future<void> editDevice(
    String id,
    String deviceName,
    String equipmentID,
    String productionArea,
    String factoryID,
  ) async {
    try {
      DocumentSnapshot docSnapshot = await _devicesCollection.doc(id).get();
      if (!docSnapshot.exists) {
        throw Exception('Device with ID $id does not exist.');
      }

      await _devicesCollection.doc(id).update({
        'device_name': deviceName,
        'equipment_id': equipmentID,
        'productionArea': productionArea,
        "factory_id": factoryID,
      });
      print("Device updated: $id");
    } catch (e) {
      throw Exception('Error editing device: $e');
    }
  }

  Future<void> deleteDevice(String id) async {
    try {
      await _devicesCollection.doc(id).delete();
      print("Device deleted: $id");
    } catch (e) {
      throw Exception('Error deleting device: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchEquipments() async {
    try {
      QuerySnapshot snapshot = await _equipmentCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching equipments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFactory() async {
    try {
      QuerySnapshot snapshot = await _factoryCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching factory: $e');
    }
  }

    Future<List<Map<String, dynamic>>> fetchProductionArea() async {
    try {
      QuerySnapshot snapshot = await _productionAreaCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching production area: $e');
    }
  }
}
