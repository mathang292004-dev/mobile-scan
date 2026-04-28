import 'package:emergex/presentation/common/cubit/audit_log_state.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuditLogCubit extends Cubit<AuditLogState> {
  final GetIncidentByIdUseCase _useCase;

  AuditLogCubit(this._useCase) : super(const AuditLogInitial());

  Future<void> fetchAuditLogs(String caseId) async {
    if (caseId.isEmpty) {
      emit(const AuditLogError('Case ID is required'));
      return;
    }
    emit(const AuditLogLoading());
    try {
      final response = await _useCase.getAuditLogs(caseId);
      if (response.success == true && response.data != null) {
        emit(AuditLogLoaded(response.data!));
      } else {
        emit(AuditLogError(response.error ?? 'Failed to fetch audit logs'));
      }
    } catch (e) {
      emit(AuditLogError('Failed to fetch audit logs: ${e.toString()}'));
    }
  }

  void reset() => emit(const AuditLogInitial());
}
