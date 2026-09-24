import 'package:intl/intl.dart';

enum FactorStatus { draft, active, locked }

enum AuditAction { created, activated, deactivated, autoLocked, restated, updated }

class EmissionFactor {
  final String id;
  final int fiscalYear;
  final double? factor;
  final String source;
  final double? carbonCost;
  final String? sourceChipLabel;
  final DateTime? publishedDate;
  final DateTime effectiveFrom;
  final FactorStatus status;
  final bool isRestated;
  final bool isPending;
  final String? documentReference;
  final String? notes;

  const EmissionFactor({
    required this.id,
    required this.fiscalYear,
    this.factor,
    required this.source,
    this.carbonCost,
    this.sourceChipLabel,
    this.publishedDate,
    required this.effectiveFrom,
    required this.status,
    this.isRestated = false,
    this.isPending = false,
    this.documentReference,
    this.notes,
  });

  String get fiscalYearLabel => 'FY $fiscalYear';
  String get fiscalYearRange => '1 Jan – 31 Dec $fiscalYear';

  String get factorDisplay {
    if (isPending) return '— pending —';
    if (factor == null) return '—';
    return factor!.toStringAsFixed(3);
  }

  String get carbonCostDisplay {
    if (carbonCost == null) return '—';
    return 'RM ${carbonCost!.toStringAsFixed(2)}';
  }

  String get publishedDisplay {
    if (publishedDate == null) return '—';
    return DateFormat('MMM yyyy').format(publishedDate!);
  }

  String get effectiveFromDisplay =>
      DateFormat('01 MMM yyyy').format(effectiveFrom);
}

class AuditLogEntry {
  final DateTime timestamp;
  final AuditAction action;
  final int fiscalYear;
  final double? fromValue;
  final double? toValue;
  final String actor;

  const AuditLogEntry({
    required this.timestamp,
    required this.action,
    required this.fiscalYear,
    this.fromValue,
    this.toValue,
    required this.actor,
  });

  String get actionLabel {
    switch (action) {
      case AuditAction.created:     return 'CREATED';
      case AuditAction.activated:   return 'ACTIVATED';
      case AuditAction.deactivated: return 'DEACTIVATED';
      case AuditAction.autoLocked:  return 'AUTO-LOCKED';
      case AuditAction.restated:    return 'RESTATED';
      case AuditAction.updated:     return 'UPDATED';
    }
  }

  String get changeDisplay {
    if (fromValue == null && toValue != null) {
      return '— → ${toValue!.toStringAsFixed(3)}';
    }
    if (fromValue != null && toValue != null) {
      return '${fromValue!.toStringAsFixed(3)} → ${toValue!.toStringAsFixed(3)}';
    }
    if (fromValue != null && toValue == null) {
      return '${fromValue!.toStringAsFixed(3)} → —';
    }
    if (action == AuditAction.autoLocked) return 'Active → Locked';
    return '—';
  }

  String get timestampDisplay =>
      DateFormat('yyyy-MM-dd\nHH:mm:ss').format(timestamp);
}

