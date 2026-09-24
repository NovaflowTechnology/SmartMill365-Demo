import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/discovery_models.dart';

/// Persists device discovery config to Firestore collection: real_time_devices
class DeviceConfigService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('real_time_devices');

  Future<Map<String, Map<String, dynamic>>> loadOverrides() async {
    try {
      final snap = await _col.get();
      return {
        for (final doc in snap.docs)
          doc.id: Map<String, dynamic>.from(doc.data() as Map)
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> approveDevice(String deviceId, DiscoveredDevice device) async {
    // Intentionally omits 'displayName' — that field is only ever set by an
    // explicit renameDevice() call. Writing the raw discovered name here
    // would mark this device as having a name override forever, causing
    // Master Facility Setting's manually-typed display name to be reverted
    // back to the raw device name on every subsequent Device Discovery sync.
    await _col.doc(deviceId).set({
      'isApproved': true,
      'isHidden': false,
      'deviceName': device.deviceName,
      'deviceType': device.deviceType,
      'plantId': device.plantId,
      'plantName': device.plantName,
      'zoneId': device.zoneId,
      'zoneName': device.zoneName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> hideDevice(String deviceId) async {
    await _col.doc(deviceId).set({
      'isHidden': true,
      'isApproved': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> renameDevice(String deviceId, String displayName) async {
    await _col.doc(deviceId).set({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> changeDeviceType(String deviceId, String deviceType) async {
    await _col.doc(deviceId).set({
      'deviceType': deviceType,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> restoreAllDevices() async {
    try {
      final snap = await _col.get();
      for (final doc in snap.docs) {
        await doc.reference.set({
          'isHidden': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> updateMapping(String deviceId,
      {required String plantId,
      required String plantName,
      required String zoneId,
      required String zoneName}) async {
    await _col.doc(deviceId).set({
      'plantId': plantId,
      'plantName': plantName,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
