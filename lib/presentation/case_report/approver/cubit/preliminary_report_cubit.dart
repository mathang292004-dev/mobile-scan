import 'package:emergex/data/model/incident/preliminary_report_model.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ───────────────────────────────────────────────────────────────────

abstract class PreliminaryReportState extends Equatable {
  const PreliminaryReportState();

  @override
  List<Object?> get props => [];
}

class PreliminaryReportInitial extends PreliminaryReportState {
  const PreliminaryReportInitial();
}

class PreliminaryReportLoading extends PreliminaryReportState {
  const PreliminaryReportLoading();
}

class PreliminaryReportLoaded extends PreliminaryReportState {
  final PreliminaryReportData data;

  const PreliminaryReportLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class PreliminaryReportError extends PreliminaryReportState {
  final String message;

  const PreliminaryReportError(this.message);

  @override
  List<Object?> get props => [message];
}

class PreliminaryReportSaving extends PreliminaryReportState {
  const PreliminaryReportSaving();
}

class PreliminaryReportSaved extends PreliminaryReportState {
  final PreliminaryReportData data;

  const PreliminaryReportSaved(this.data);

  @override
  List<Object?> get props => [data];
}

class PreliminaryReportPdfReady extends PreliminaryReportState {
  final String localPath;

  const PreliminaryReportPdfReady(this.localPath);

  @override
  List<Object?> get props => [localPath];
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class PreliminaryReportCubit extends Cubit<PreliminaryReportState> {
  final GetIncidentByIdUseCase _useCase;

  PreliminaryReportCubit(this._useCase) : super(const PreliminaryReportInitial());

  Future<void> fetch(String incidentId) async {
    emit(const PreliminaryReportLoading());

    final response = await _useCase.getPreliminaryReport(incidentId);

    if (response.success == true && response.data != null) {
      emit(PreliminaryReportLoaded(response.data!));
    } else {
      emit(PreliminaryReportError(response.error ?? 'Failed to load preliminary report'));
    }
  }

  Future<void> save(
    String incidentId,
    String tab,
    Map<String, dynamic> data,
  ) async {
    emit(const PreliminaryReportSaving());

    final response = await _useCase.updatePreliminaryReport(incidentId, tab, data);

    if (response.success == true && response.data != null) {
      emit(PreliminaryReportSaved(response.data!));
    } else {
      emit(PreliminaryReportError(response.error ?? 'Failed to save'));
    }
  }

  Future<void> exportPdf(String incidentId) async {
    emit(const PreliminaryReportSaving());

    final response = await _useCase.exportPreliminaryReportPdf(incidentId);

    if (response.success == true && response.data != null) {
      emit(PreliminaryReportPdfReady(response.data!));
    } else {
      emit(PreliminaryReportError(response.error ?? 'Failed to export PDF'));
    }
  }
}
