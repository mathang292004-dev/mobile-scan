import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_details_cubit/role_details_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_form_cubit/role_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/upload_doc_use_case/upload_doc_use_case.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/role_form_utils.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/organization/edit_role_form_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:get_it/get_it.dart';

class OrganizedEditMember extends StatelessWidget {
  final String? roleId;

  const OrganizedEditMember({super.key, this.roleId});

  @override
  Widget build(BuildContext context) {
    final roleDetailsCubit = AppDI.roleDetailsCubit;
    final orgCubit = AppDI.onboardingOrganizationStructureCubit;

    return BlocProvider(
      create: (_) {
        final cubit = RoleFormCubit(
          GetIt.instance<OnboardingOrganizationStructureUseCase>(),
        );
        // Will be initialized to edit mode when data is loaded
        return cubit;
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: roleDetailsCubit),
          BlocProvider.value(value: orgCubit),
        ],
        child: Builder(
          builder: (context) {
            // Fetch role details when screen loads
            if (roleId != null && roleId!.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Clear any uncommitted changes
                roleDetailsCubit.clearSessionSelections();
                // Fetch fresh data from API
                roleDetailsCubit.getRoleDetails(roleId!);
              });
            }

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (!didPop) {
                  // User is trying to go back, check for unsaved changes
                  final currentAssignedUsers =
                      roleDetailsCubit
                          .state
                          .roleDetailsResponse
                          ?.assignedUsers ??
                      [];
                  try {
                    RoleFormUtils.handleBackNavigation(
                      context,
                      currentAssignedUsers,
                    );
                  } catch (e) {
                    // Cubit might not be available, just navigate back
                    if (context.mounted) {
                      back();
                    }
                  }
                }
              },
              child: _EditMemberContent(roleId: roleId),
            );
          },
        ),
      ),
    );
  }
}

class _EditMemberContent extends StatelessWidget {
  final String? roleId;

  const _EditMemberContent({required this.roleId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      OnboardingOrganizationStructureCubit,
      OnboardingOrganizationStructureState
    >(
      listener: (context, state) {
        if (state.processState == ProcessState.loading) {
          loaderService.showLoader();
        } else if (state.processState == ProcessState.done ||
            state.processState == ProcessState.error) {
          loaderService.hideLoader();
          if (state.processState == ProcessState.error &&
              state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) {
            showSnackBar(context, state.errorMessage!, isSuccess: false);
          } else if (state.processState == ProcessState.done) {
            showSnackBar(context, 'Role updated successfully', isSuccess: true);
            // Reset form state
            final formCubit = context.read<RoleFormCubit>();
            formCubit.reset();

            // Navigate to Role Details screen (EmployeeTeamScreen) after successful save
            // This ensures consistent behavior regardless of where the edit was initiated:
            // - Edit from Role List: Goes to Role Details (not back to list)
            // - Edit from Role Details: Stays in Role Details view
            // This matches web application behavior where user stays in Role Details after saving
            if (context.mounted && roleId != null && roleId!.isNotEmpty) {
              // First, pop the edit screen from the navigation stack
              back();

              // Then navigate to Role Details screen with the roleId
              // Using a post-frame callback ensures the back() completes first
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Refresh role details data from the backend
                final roleDetailsCubit = AppDI.roleDetailsCubit;
                roleDetailsCubit.getRoleDetails(roleId!);

                // Navigate to Role Details screen
                // This replaces the current screen (which could be RolesScreen or EmployeeTeamScreen)
                // ensuring consistent navigation regardless of entry point
                openScreen(Routes.employeeteamscreen, args: {'roleId': roleId});
              });
            } else if (context.mounted) {
              // Fallback: If no roleId, just go back
              back();
            }
          }
        }
      },
      child: BlocListener<RoleDetailsCubit, RoleDetailsState>(
        listener: (context, state) {
          if (state.processState == ProcessState.loading) {
            loaderService.showLoader();
          } else if (state.processState == ProcessState.error) {
            loaderService.hideLoader();
            if (context.mounted) {
              showSnackBar(
                context,
                state.errorMessage ?? 'Role not found',
                isSuccess: false,
              );
              back();
            }
          } else if (state.processState == ProcessState.done) {
            loaderService.hideLoader();

            // Initialize form with role details when data is loaded
            // Only initialize ONCE - check if form is not already in edit mode
            if (state.roleDetailsResponse != null &&
                state.roleDetailsResponse!.roleDetails.roleId == roleId) {
              final formCubit = context.read<RoleFormCubit>();

              // Only initialize if not already in edit mode (prevents resetting on user add/remove)
              if (formCubit.state.mode != RoleFormMode.edit) {
                final roleDetails = state.roleDetailsResponse!.roleDetails;
                final assignedUsers = state.roleDetailsResponse!.assignedUsers;

                // Initialize the cubit for edit mode with the loaded data
                formCubit.initializeForEdit(roleDetails, assignedUsers);
              }
            }
          }
        },
        child: BlocBuilder<RoleDetailsCubit, RoleDetailsState>(
          builder: (context, state) {
            return AppScaffold(
              useGradient: true,
              gradientBegin: Alignment.topCenter,
              gradientEnd: Alignment.bottomCenter,
              showDrawer: false,
              appBar: const AppBarWidget(hasNotifications: true),
              showBottomNav: false,
              backgroundColor: ColorHelper.textLight.withValues(alpha: 0.2),
              child: SafeArea(
                child: BlocBuilder<RoleDetailsCubit, RoleDetailsState>(
                  builder: (context, roleState) {
                    final currentRoleDetails =
                        roleState.roleDetailsResponse?.roleDetails;
                    final currentAssignedUsers =
                        roleState.roleDetailsResponse?.assignedUsers ?? [];
                    final currentProjectId =
                        roleState.roleDetailsResponse?.roleDetails.projectId;

                    return BlocBuilder<RoleFormCubit, RoleFormState>(
                      builder: (context, formState) {
                        return EditRoleFormContent(
                          roleId: roleId,
                          projectId: currentProjectId,
                          roleDetails: currentRoleDetails,
                          assignedUsers: currentAssignedUsers,
                          formState: formState,
                          roleDetailsState: roleState,
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
