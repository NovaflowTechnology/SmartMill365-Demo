import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RolesRecord extends FirestoreRecord {
  RolesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "accessible_modules" field.
  List<String>? _accessibleModules;
  List<String> get accessibleModules => _accessibleModules ?? const [];
  bool hasAccessibleModules() => _accessibleModules != null;

  // "accessible_sub_modules" field.
  List<String>? _accessibleSubModules;
  List<String> get accessibleSubModules => _accessibleSubModules ?? const [];
  bool hasAccessibleSubModules() => _accessibleSubModules != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _accessibleModules = (snapshotData['accessible_modules'] as List<dynamic>?)?.map((e) => e as String).toList();
    _accessibleSubModules = (snapshotData['accessible_sub_modules'] as List<dynamic>?)?.map((e) => e as String).toList();
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('roles');

  static Stream<RolesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => RolesRecord.fromSnapshot(s));

  static Future<RolesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => RolesRecord.fromSnapshot(s));

  static RolesRecord fromSnapshot(DocumentSnapshot snapshot) => RolesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static RolesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      RolesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'RolesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is RolesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createRolesRecordData({
  String? name,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
    }.withoutNulls,
  );

  return firestoreData;
}

class RolesRecordDocumentEquality implements Equality<RolesRecord> {
  const RolesRecordDocumentEquality();

  @override
  bool equals(RolesRecord? e1, RolesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.name == e2?.name &&
        listEquality.equals(e1?.accessibleModules, e2?.accessibleModules) &&
        listEquality.equals(e1?.accessibleSubModules, e2?.accessibleSubModules);
  }

  @override
  int hash(RolesRecord? e) => const ListEquality()
      .hash([e?.name, e?.accessibleModules, e?.accessibleSubModules]);

  @override
  bool isValidKey(Object? o) => o is RolesRecord;
}
