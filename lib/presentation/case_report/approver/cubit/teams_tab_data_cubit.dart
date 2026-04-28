import 'package:emergex/presentation/case_report/approver/model/team_members_data_model.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ──────────────────────────────────────────────────────────────────

abstract class TeamsTabDataState extends Equatable {
  const TeamsTabDataState();

  @override
  List<Object?> get props => [];
}

class TeamsTabDataInitial extends TeamsTabDataState {}

class TeamsTabDataLoading extends TeamsTabDataState {}

class TeamsTabDataLoaded extends TeamsTabDataState {
  final TeamMembersData teamMembersData;

  const TeamsTabDataLoaded(this.teamMembersData);

  @override
  List<Object?> get props => [teamMembersData];
}

class TeamsTabDataError extends TeamsTabDataState {
  final String message;

  const TeamsTabDataError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class TeamsTabDataCubit extends Cubit<TeamsTabDataState> {
  final GetIncidentByIdUseCase _useCase;

  TeamsTabDataCubit(this._useCase) : super(TeamsTabDataInitial());

  Future<void> loadTeamsData(
    String projectId, {
    String? incidentId,
  }) async {
    try {
      emit(TeamsTabDataLoading());

      final response = await _useCase.fetchTeamMembers(
        projectId,
        incidentId: incidentId,
      );

      if (response.success == true && response.data != null) {
        emit(TeamsTabDataLoaded(response.data!));
      } else {
        emit(
          TeamsTabDataError(response.error ?? 'Failed to load team members'),
        );
      }
    } catch (e) {
      emit(TeamsTabDataError('Failed to load teams data: ${e.toString()}'));
    }
  }

  void reset() {
    emit(TeamsTabDataInitial());
  }

}
