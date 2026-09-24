import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EmissionFactorRecord extends FirestoreRecord {
  EmissionFactorRecord._(super.reference, super.data) {
    _initializeFields();
  }

  // "fiscal_year" field.
  int? _fiscalYear;
  int get fiscalYear => _fiscalYear ?? 0;
  bool hasFiscalYear() => _fiscalYear != null;

  // "factor" field — null means pending/unknown.
  double? _factor;
  double? get factor => _factor;
  bool hasFactor() => _factor != null;

  // "source" field.
  String? _source;
  String get source => _source ?? '';
  bool hasSource() => _source != null;

  // "carbon_cost" field — RM per tCO2e, drives the Emission Cost card.
  double? _carbonCost;
  double? get carbonCost => _carbonCost;
  bool hasCarbonCost() => _carbonCost != null;

  // "source_chip_label" field.
  String? _sourceChipLabel;
  String? get sourceChipLabel => _sourceChipLabel;
  bool hasSourceChipLabel() => _sourceChipLabel != null;

  // "published_date" field.
  DateTime? _publishedDate;
  DateTime? get publishedDate => _publishedDate;
  bool hasPublishedDate() => _publishedDate != null;

  // "effective_from" field.
  DateTime? _effectiveFrom;
  DateTime get effectiveFrom => _effectiveFrom ?? DateTime(fiscalYear, 1, 1);
  bool hasEffectiveFrom() => _effectiveFrom != null;

  // "status" field — values: 'draft', 'active', 'locked'.
  String? _status;
  String get status => _status ?? 'draft';
  bool hasStatus() => _status != null;

  // "is_restated" field.
  bool? _isRestated;
  bool get isRestated => _isRestated ?? false;
  bool hasIsRestated() => _isRestated != null;

  // "is_pending" field.
  bool? _isPending;
  bool get isPending => _isPending ?? false;
  bool hasIsPending() => _isPending != null;

  // "document_reference" field.
  String? _documentReference;
  String? get documentReference => _documentReference;
  bool hasDocumentReference() => _documentReference != null;

  // "notes" field.
  String? _notes;
  String? get notes => _notes;
  bool hasNotes() => _notes != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "created_by" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  void _initializeFields() {
    _fiscalYear = castToType<int>(snapshotData['fiscal_year']);
    _factor = castToType<double>(snapshotData['factor']);
    _source = snapshotData['source'] as String?;
    _carbonCost = castToType<double>(snapshotData['carbon_cost']);
    _sourceChipLabel = snapshotData['source_chip_label'] as String?;
    _publishedDate = snapshotData['published_date'] as DateTime?;
    _effectiveFrom = snapshotData['effective_from'] as DateTime?;
    _status = snapshotData['status'] as String?;
    _isRestated = snapshotData['is_restated'] as bool?;
    _isPending = snapshotData['is_pending'] as bool?;
    _documentReference = snapshotData['document_reference'] as String?;
    _notes = snapshotData['notes'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
    _createdBy = snapshotData['created_by'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('emission_factors');

  static Stream<EmissionFactorRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EmissionFactorRecord.fromSnapshot(s));

  static Future<EmissionFactorRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => EmissionFactorRecord.fromSnapshot(s));

  static EmissionFactorRecord fromSnapshot(DocumentSnapshot snapshot) =>
      EmissionFactorRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EmissionFactorRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EmissionFactorRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EmissionFactorRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EmissionFactorRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEmissionFactorRecordData({
  int? fiscalYear,
  double? factor,
  String? source,
  double? carbonCost,
  String? sourceChipLabel,
  DateTime? publishedDate,
  DateTime? effectiveFrom,
  String? status,
  bool? isRestated,
  bool? isPending,
  String? documentReference,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
  String? createdBy,
}) {
  return mapToFirestore(<String, dynamic>{
    'fiscal_year': fiscalYear,
    'factor': factor,
    'source': source,
    'carbon_cost': carbonCost,
    'source_chip_label': sourceChipLabel,
    'published_date': publishedDate,
    'effective_from': effectiveFrom,
    'status': status,
    'is_restated': isRestated,
    'is_pending': isPending,
    'document_reference': documentReference,
    'notes': notes,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'created_by': createdBy,
  }.withoutNulls);
}

class EmissionFactorRecordDocumentEquality
    implements Equality<EmissionFactorRecord> {
  const EmissionFactorRecordDocumentEquality();

  @override
  bool equals(EmissionFactorRecord? e1, EmissionFactorRecord? e2) {
    return e1?.fiscalYear == e2?.fiscalYear &&
        e1?.factor == e2?.factor &&
        e1?.status == e2?.status &&
        e1?.isRestated == e2?.isRestated;
  }

  @override
  int hash(EmissionFactorRecord? e) => const ListEquality()
      .hash([e?.fiscalYear, e?.factor, e?.status, e?.isRestated]);

  @override
  bool isValidKey(Object? o) => o is EmissionFactorRecord;
}
