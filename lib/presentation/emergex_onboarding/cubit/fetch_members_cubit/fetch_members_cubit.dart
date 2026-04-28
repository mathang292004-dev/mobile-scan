import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/upload_doc/fetch_members_response.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/upload_doc_use_case/upload_doc_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FetchMembersState extends Equatable {
  const FetchMembersState({
    this.membersResponse,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
  });

  final FetchMembersResponse? membersResponse;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;

  factory FetchMembersState.initial() => const FetchMembersState(
        processState: ProcessState.none,
      );

  FetchMembersState copyWith({
    FetchMembersResponse? membersResponse,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FetchMembersState(
      membersResponse: membersResponse ?? this.membersResponse,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        membersResponse,
        processState,
        isLoading,
        errorMessage,
      ];
}

class FetchMembersCubit extends Cubit<FetchMembersState> {
  final OnboardingOrganizationStructureUseCase _useCase;

  FetchMembersCubit(this._useCase) : super(FetchMembersState.initial());

  /// Fetch members by projectId (optionally with incidentId for add/reassign member)
  Future<void> fetchMembers(String projectId, {String? incidentId}) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _useCase.fetchMembers(
        projectId,
        incidentId: incidentId,
      );

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            membersResponse: response.data,
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to fetch members',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to fetch members: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void reset() {
    emit(FetchMembersState.initial());
  }
}

