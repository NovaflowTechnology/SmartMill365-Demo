import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EmissionFactorAuditRecord extends FirestoreRecord {
  EmissionFactorAuditRecord._(super.reference, super.data) {
    _initializeFields();
  }

  // "timestamp" field.
  DateTime? _timestamp;
  DateTime get timestamp => _timestamp ?? DateTime.now();
  bool hasTimestamp() => _timestamp != null;

  // "action" field — values match AuditAction enum names.
  String? _action;
  String get action => _action ?? '';
  bool hasAction() => _action != null;

  // "fiscal_year" field.
  int? _fiscalYear;
  int get fiscalYear => _fiscalYear ?? 0;
  bool hasFiscalYear() => _fiscalYear != null;

  // "from_value" field — null when not applicable.
  double? _fromValue;
  double? get fromValue => _fromValue;
  bool hasFromValue() => _fromValue != null;

  // "to_value" field — null when not applicable.
  double? _toValue;
  double? get toValue => _toValue;
  bool hasToValue() => _toValue != null;

  // "actor" field — email or 'System'.
  String? _actor;
  String get actor => _actor ?? '';
  bool hasActor() => _actor != null;

  void _initializeFields() {
    _timestamp = snapshotData['timestamp'] as DateTime?;
    _action = snapshotData['action'] as String?;
    _fiscalYear = castToType<int>(snapshotData['fiscal_year']);
    _fromValue = castToType<double>(snapshotData['from_value']);
    _toValue = castToType<double>(snapshotData['to_value']);
    _actor = snapshotData['actor'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('emission_factor_audits');

  static Stream<EmissionFactorAuditRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EmissionFactorAuditRecord.fromSnapshot(s));

  static Future<EmissionFactorAuditRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => EmissionFactorAuditRecord.fromSnapshot(s));

  static EmissionFactorAuditRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EmissionFactorAuditRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EmissionFactorAuditRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EmissionFactorAuditRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EmissionFactorAuditRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EmissionFactorAuditRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEmissionFactorAuditRecordData({
  DateTime? timestamp,
  String? action,
  int? fiscalYear,
  double? fromValue,
  double? toValue,
  String? actor,
}) {
  return mapToFirestore(<String, dynamic>{
    'timestamp': timestamp,
    'action': action,
    'fiscal_year': fiscalYear,
    'from_value': fromValue,
    'to_value': toValue,
    'actor': actor,
  }.withoutNulls);
}

class EmissionFactorAuditRecordDocumentEquality
    implements Equality<EmissionFactorAuditRecord> {
  const EmissionFactorAuditRecordDocumentEquality();

  @override
  bool equals(EmissionFactorAuditRecord? e1, EmissionFactorAuditRecord? e2) {
    return e1?.timestamp == e2?.timestamp &&
        e1?.action == e2?.action &&
        e1?.fiscalYear == e2?.fiscalYear;
  }

  @override
  int hash(EmissionFactorAuditRecord? e) => const ListEquality()
      .hash([e?.timestamp, e?.action, e?.fiscalYear]);

  @override
  bool isValidKey(Object? o) => o is EmissionFactorAuditRecord;
}
