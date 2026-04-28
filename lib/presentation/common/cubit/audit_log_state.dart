import 'package:emergex/data/model/incident/audit_log_response.dart';
import 'package:equatable/equatable.dart';

abstract class AuditLogState extends Equatable {
  const AuditLogState();

  @override
  List<Object?> get props => [];
}

class AuditLogInitial extends AuditLogState {
  const AuditLogInitial();
}

class AuditLogLoading extends AuditLogState {
  const AuditLogLoading();
}

class AuditLogLoaded extends AuditLogState {
  final AuditLogResponse data;

  const AuditLogLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AuditLogError extends AuditLogState {
  final String message;

  const AuditLogError(this.message);

  @override
  List<Object?> get props => [message];
}
