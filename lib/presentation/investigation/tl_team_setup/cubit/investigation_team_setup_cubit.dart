import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State for Investigation Team Setup
class InvestigationTeamSetupState extends Equatable {
  const InvestigationTeamSetupState({
    this.teamMembers = const [],
    this.availableMembers = const [],
    this.processState = ProcessState.none,
    this.errorMessage,
  });

  final List<Map<String, String>> teamMembers;
  final List<Map<String, String>> availableMembers;
  final ProcessState processState;
  final String? errorMessage;

  factory InvestigationTeamSetupState.initial() =>
      const InvestigationTeamSetupState(
        processState: ProcessState.none,
      );

  InvestigationTeamSetupState copyWith({
    List<Map<String, String>>? teamMembers,
    List<Map<String, String>>? availableMembers,
    ProcessState? processState,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InvestigationTeamSetupState(
      teamMembers: teamMembers ?? this.teamMembers,
      availableMembers: availableMembers ?? this.availableMembers,
      processState: processState ?? this.processState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        teamMembers,
        availableMembers,
        processState,
        errorMessage,
      ];
}

/// Cubit for managing Investigation Team Setup state — UI only with dummy data
class InvestigationTeamSetupCubit
    extends Cubit<InvestigationTeamSetupState> {
  InvestigationTeamSetupCubit()
      : super(InvestigationTeamSetupState.initial());

  /// Load dummy team data
  Future<void> loadTeam() async {
    emit(state.copyWith(
      processState: ProcessState.loading,
      clearError: true,
    ));

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final dummyTeamMembers = <Map<String, String>>[
      {
        'id': 'TM-001',
        'name': 'John Smith',
        'role': 'Lead Investigator',
        'email': 'john.smith@emergex.com',
        'status': 'Active',
      },
      {
        'id': 'TM-002',
        'name': 'Sarah Johnson',
        'role': 'Safety Officer',
        'email': 'sarah.johnson@emergex.com',
        'status': 'Active',
      },
      {
        'id': 'TM-003',
        'name': 'Michael Brown',
        'role': 'Technical Expert',
        'email': 'michael.brown@emergex.com',
        'status': 'Active',
      },
      {
        'id': 'TM-004',
        'name': 'Emily Davis',
        'role': 'Documentation Specialist',
        'email': 'emily.davis@emergex.com',
        'status': 'Active',
      },
    ];

    final dummyAvailableMembers = <Map<String, String>>[
      {
        'id': 'AM-001',
        'name': 'Robert Wilson',
        'role': 'Safety Analyst',
        'email': 'robert.wilson@emergex.com',
        'status': 'Available',
      },
      {
        'id': 'AM-002',
        'name': 'Jessica Taylor',
        'role': 'Environmental Specialist',
        'email': 'jessica.taylor@emergex.com',
        'status': 'Available',
      },
      {
        'id': 'AM-003',
        'name': 'David Martinez',
        'role': 'Risk Assessor',
        'email': 'david.martinez@emergex.com',
        'status': 'Available',
      },
    ];

    emit(state.copyWith(
      teamMembers: dummyTeamMembers,
      availableMembers: dummyAvailableMembers,
      processState: ProcessState.done,
      clearError: true,
    ));
  }

  /// Add a member from available list to team
  void addMember(String memberId) {
    final memberIndex = state.availableMembers
        .indexWhere((m) => m['id'] == memberId);
    if (memberIndex == -1) return;

    final member = Map<String, String>.from(
        state.availableMembers[memberIndex]);
    member['status'] = 'Active';

    final updatedAvailable =
        List<Map<String, String>>.from(state.availableMembers)
          ..removeAt(memberIndex);
    final updatedTeam =
        List<Map<String, String>>.from(state.teamMembers)..add(member);

    emit(state.copyWith(
      teamMembers: updatedTeam,
      availableMembers: updatedAvailable,
    ));
  }

  /// Remove a member from team back to available list
  void removeMember(String memberId) {
    final memberIndex =
        state.teamMembers.indexWhere((m) => m['id'] == memberId);
    if (memberIndex == -1) return;

    final member = Map<String, String>.from(
        state.teamMembers[memberIndex]);
    member['status'] = 'Available';

    final updatedTeam =
        List<Map<String, String>>.from(state.teamMembers)
          ..removeAt(memberIndex);
    final updatedAvailable =
        List<Map<String, String>>.from(state.availableMembers)
          ..add(member);

    emit(state.copyWith(
      teamMembers: updatedTeam,
      availableMembers: updatedAvailable,
    ));
  }
}
