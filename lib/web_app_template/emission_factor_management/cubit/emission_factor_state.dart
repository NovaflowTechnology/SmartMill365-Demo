import 'package:equatable/equatable.dart';
import '../emission_factor_model.dart';

abstract class EmissionFactorState extends Equatable {
  const EmissionFactorState();

  @override
  List<Object?> get props => [];
}

class EmissionFactorInitial extends EmissionFactorState {
  const EmissionFactorInitial();
}

class EmissionFactorLoading extends EmissionFactorState {
  const EmissionFactorLoading();
}

class EmissionFactorLoaded extends EmissionFactorState {
  final List<EmissionFactor> factors;
  final List<AuditLogEntry> auditLog;
  final bool isSaving;

  const EmissionFactorLoaded({
    required this.factors,
    required this.auditLog,
    this.isSaving = false,
  });

  EmissionFactorLoaded copyWith({
    List<EmissionFactor>? factors,
    List<AuditLogEntry>? auditLog,
    bool? isSaving,
  }) {
    return EmissionFactorLoaded(
      factors: factors ?? this.factors,
      auditLog: auditLog ?? this.auditLog,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [factors, auditLog, isSaving];
}

class EmissionFactorError extends EmissionFactorState {
  final String message;

  const EmissionFactorError(this.message);

  @override
  List<Object?> get props => [message];
}
