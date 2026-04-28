import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/organization_structure/org_structure_response.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/organization_structure/model/org_data.dart';
import 'package:emergex/presentation/organization_structure/model/org_member_model.dart';
import 'package:emergex/presentation/organization_structure/model/org_role_model.dart';
import 'package:emergex/presentation/organization_structure/use_cases/org_structure_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Organization Structure State
class OrgStructureState extends Equatable {
  final List<OrgStructureResponse>? data;
  final OrgRole? rootRole;
  final String? selectedRoleId;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;

  const OrgStructureState({
    this.data,
    this.rootRole,
    this.selectedRoleId,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
  });

  factory OrgStructureState.initial() {
    return const OrgStructureState(
      data: null,
      rootRole: null,
      selectedRoleId: null,
      processState: ProcessState.none,
      isLoading: false,
      errorMessage: null,
    );
  }

  OrgStructureState copyWith({
    List<OrgStructureResponse>? data,
    OrgRole? rootRole,
    String? selectedRoleId,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrgStructureState(
      data: data ?? this.data,
      rootRole: rootRole ?? this.rootRole,
      selectedRoleId: selectedRoleId ?? this.selectedRoleId,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        data,
        rootRole,
        selectedRoleId,
        processState,
        isLoading,
        errorMessage,
      ];
}

/// Organization Structure Cubit
class OrgStructureCubit extends Cubit<OrgStructureState> {
  final OrgStructureUseCase _useCase;

  OrgStructureCubit(this._useCase) : super(OrgStructureState.initial());

  Future<void> loadOrgStructure() async {
    final projectId =
        AppDI.emergexAppCubit.state.userPermissions?.projectId ?? '';

    if (projectId.isNotEmpty) {
      await getOrgStructure(projectId);
    } else {
      emit(state.copyWith(
        rootRole: OrgData.getOrgStructure(),
        processState: ProcessState.done,
        isLoading: false,
        clearError: true,
      ));
    }
  }

  Future<void> getOrgStructure(String projectId) async {
    if (projectId.isEmpty) {
      emit(state.copyWith(
        processState: ProcessState.error,
        errorMessage: 'Project ID is required',
        clearError: false,
      ));
      return;
    }

    emit(state.copyWith(
      processState: ProcessState.loading,
      isLoading: true,
      errorMessage: null,
      clearError: true,
    ));

    final response = await _useCase.getOrgStructure(projectId);

    if (response.success == true &&
        response.data != null &&
        response.data!.isNotEmpty) {
      final converted = _convertToOrgRole(
        response.data!.first.organizationStructure,
        response.data!.first.roleMembers,
        response.data!.first.organizationStructure.level,
      );
      emit(state.copyWith(
        data: response.data!,
        rootRole: converted,
        processState: ProcessState.done,
        isLoading: false,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(
        processState: ProcessState.error,
        isLoading: false,
        errorMessage: response.error ?? 'Failed to load organization structure',
        clearError: false,
      ));
    }
  }

  void selectRole(String roleId) {
    emit(state.copyWith(selectedRoleId: roleId));
  }

  void reset() {
    emit(OrgStructureState.initial());
  }

  OrgRole _convertToOrgRole(
    OrganizationStructure orgStructure,
    List<RoleMember> roleMembers,
    int level,
  ) {
    final roleMember = roleMembers.firstWhere(
      (rm) => rm.roleName == orgStructure.roleName,
      orElse: () => RoleMember(roleName: orgStructure.roleName, members: []),
    );

    final members = roleMember.members.map((m) {
      return OrgMember(
        id: m.id ?? '',
        name: m.memberName,
        email: m.memberEmail,
        avatar: '',
        isOnline: false,
        position: orgStructure.roleName,
      );
    }).toList();

    String colorCode;
    if (level == 1) {
      colorCode = OrgData.topLevelColor;
    } else if (level == 2 || level == 3) {
      colorCode = OrgData.midLevelColor;
    } else {
      colorCode = OrgData.lowLevelColor;
    }

    final children = orgStructure.children.map((child) {
      return _convertToOrgRole(child, roleMembers, child.level);
    }).toList();

    return OrgRole(
      id: orgStructure.roleName.toLowerCase().replaceAll(' ', '-'),
      title: orgStructure.roleName,
      members: members,
      children: children,
      level: orgStructure.level,
      colorCode: colorCode,
    );
  }
}
