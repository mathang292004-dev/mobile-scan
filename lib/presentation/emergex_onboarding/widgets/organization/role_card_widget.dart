//import 'package:emergex/er_team_screen.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/project_view_management/project_responce.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/permission_helper.dart';

class RoleListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> roledata;

  const RoleListWidget({super.key, required this.roledata});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorHelper.textLight.withValues(alpha: 0.2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: roledata.length + 1,
                itemBuilder: (context, index) {
                  if (index == roledata.length) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: ColorHelper.surfaceColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          BlocBuilder<
                            OnboardingOrganizationStructureCubit,
                            OnboardingOrganizationStructureState
                          >(
                            builder: (context, state) {
                              final cubit =
                                  AppDI.onboardingOrganizationStructureCubit;
                              final projectId = state.selectedProjectId;

                              final isLoading =
                                  state.processState == ProcessState.loading;

                              // Check if project uploadStatus is "Done"
                              final projectCubit = AppDI.projectCubit;
                              final project = projectCubit.state.projects
                                  .firstWhere(
                                    (p) => p.projectId == projectId,
                                    orElse: () => Project(),
                                  );
                              final isProjectDone =
                                  project.uploadStatus == 'Done';

                              return EmergexButton(
                                text: TextHelper.completeOnboarding,
                                textColor: ColorHelper.white,
                                fontWeight: FontWeight.w500,
                                borderRadius: 8,
                                buttonHeight: 40,
                                disabled:
                                    isLoading ||
                                    projectId == null ||
                                    isProjectDone,
                                onPressed:
                                    isLoading ||
                                        projectId == null ||
                                        isProjectDone
                                    ? null
                                    : () async {
                                        await cubit.completeOnboarding(
                                          projectId,
                                        );

                                        if (context.mounted) {
                                          final currentState = cubit.state;
                                          if (currentState.processState ==
                                              ProcessState.done) {
                                            CustomDialog.showSuccess(
                                              context: context,
                                              title: TextHelper
                                                  .organizationStructureCreated,
                                              subtitle: Text(
                                                TextHelper.organizationsubtitle,
                                                textAlign: TextAlign.center,
                                              ),
                                              buttonText:
                                                  TextHelper.continueText,
                                              onPressed: () {
                                                // Close the dialog using root navigator
                                                Navigator.of(
                                                  context,
                                                  rootNavigator: true,
                                                ).pop();

                                                // Get navigation source to determine where to go back
                                                final navigationSource = cubit
                                                    .state
                                                    .navigationSource;

                                                // Schedule post-frame callback to handle navigation and refresh
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                      // Refresh project data to reflect updated uploadStatus
                                                      AppDI.projectCubit
                                                          .refreshProjects();
                                                    });

                                                // Navigate based on the source:
                                                // - 'viewProjectScreen' → Client flow → go to ViewProjectScreen
                                                // - 'projectListScreen' or null → Drawer flow → go to ProjectListScreen
                                                // Check navigation source or defensive fallback for client context
                                                bool returnToClient =
                                                    navigationSource ==
                                                    'viewProjectScreen';

                                                // Fallback: If source is null but we have a valid client ID, assume client context
                                                if (navigationSource == null &&
                                                    cubit
                                                            .state
                                                            .selectedClientId !=
                                                        null &&
                                                    cubit
                                                        .state
                                                        .selectedClientId!
                                                        .isNotEmpty) {
                                                  returnToClient = true;
                                                }

                                                if (returnToClient) {
                                                  final clientId =
                                                      cubit
                                                          .state
                                                          .selectedClientId ??
                                                      '';
                                                  final clientName =
                                                      cubit
                                                          .state
                                                          .selectedClientName ??
                                                      '';
                                                  openScreen(
                                                    Routes.viewprojectscreen,
                                                    clearOldStacks: true,
                                                    args: {
                                                      'clientId': clientId,
                                                      'clientName': clientName,
                                                    },
                                                  );
                                                } else {
                                                  openScreen(
                                                    Routes.projectListScreen,
                                                    clearOldStacks: true,
                                                  );
                                                }

                                                // Clear navigation source after navigation
                                                cubit.clearNavigationSource();
                                              },
                                            );
                                          } else if (currentState
                                                  .errorMessage !=
                                              null) {
                                            CustomDialog.showError(
                                              context: context,
                                              title: 'Error',
                                              subtitle: Text(
                                                currentState.errorMessage!,
                                                textAlign: TextAlign.center,
                                              ),
                                              primaryButtonText: 'OK',
                                              secondaryButtonText: "back",
                                              onPrimaryPressed: () {
                                                back();
                                                AppDI.projectCubit
                                                    .refreshProjects();

                                                // Navigate based on the source
                                                final navigationSource = cubit
                                                    .state
                                                    .navigationSource;
                                                // Check navigation source or defensive fallback for client context
                                                bool returnToClient =
                                                    navigationSource ==
                                                    'viewProjectScreen';

                                                // Fallback: If source is null but we have a valid client ID, assume client context
                                                if (navigationSource == null &&
                                                    cubit
                                                            .state
                                                            .selectedClientId !=
                                                        null &&
                                                    cubit
                                                        .state
                                                        .selectedClientId!
                                                        .isNotEmpty) {
                                                  returnToClient = true;
                                                }

                                                if (returnToClient) {
                                                  final clientId =
                                                      cubit
                                                          .state
                                                          .selectedClientId ??
                                                      '';
                                                  final clientName =
                                                      cubit
                                                          .state
                                                          .selectedClientName ??
                                                      '';
                                                  openScreen(
                                                    Routes.viewprojectscreen,
                                                    clearOldStacks: true,
                                                    args: {
                                                      'clientId': clientId,
                                                      'clientName': clientName,
                                                    },
                                                  );
                                                } else {
                                                  openScreen(
                                                    Routes.projectListScreen,
                                                    clearOldStacks: true,
                                                  );
                                                }

                                                // Clear navigation source after navigation
                                                cubit.clearNavigationSource();
                                              },
                                              onSecondaryPressed: () => back(),
                                            );
                                          }
                                        }
                                      },
                              );
                            },
                          ),
                    );
                  }

                  final r = roledata[index];
                  return Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorHelper.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: ColorHelper.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: ColorHelper.white.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r["title"],
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: ColorHelper.textPrimary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (PermissionHelper.hasEditPermission(
                              moduleName: "Client Admin",
                              featureName: "Role Management",
                            )||PermissionHelper.hasEditPermission(
                              moduleName: "Client Admin",
                              featureName: "User Management",
                            ) )
                              GestureDetector(
                                onTap: () {
                                  openScreen(
                                    Routes.organizationeditscreen,
                                    args: {"roleId": r["roleId"] ?? ""},
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorHelper.white.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      Assets.reportApEdit,
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                r["subtitle"],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: ColorHelper.textSecondary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: ColorHelper.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              TextHelper.erteam,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: ColorHelper.textSecondary,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ColorHelper.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ColorHelper.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TextHelper.description,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: ColorHelper.black4,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                r["description"],
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: ColorHelper.black4,
                                      height: 1.5,
                                    ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                              PermissionHelper.hasDeletePermission(
                                moduleName: "Client Admin",
                                featureName: "Role Management",
                              )
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.end,
                          children: [
                            // Show delete button only if user has delete permission
                            if (PermissionHelper.hasDeletePermission(
                              moduleName: "Client Admin",
                              featureName: "Role Management",
                            ))
                              GestureDetector(
                                onTap: () {
                                  final orgCubit = AppDI
                                      .onboardingOrganizationStructureCubit;
                                  final projectId =
                                      orgCubit.state.selectedProjectId;
                                  if (projectId == null || projectId.isEmpty) {
                                    return;
                                  }
                                  CustomDialog.showError(
                                    context: context,
                                    title: TextHelper.areYouSure,
                                    subtitle: const Text(
                                      TextHelper.roleerror,
                                      textAlign: TextAlign.center,
                                    ),
                                    primaryButtonText: TextHelper.delete,
                                    secondaryButtonText: TextHelper.cancel,
                                    onPrimaryPressed: () async {
                                      // Close the confirmation dialog first
                                      back();

                                      // Delete the role
                                      await AppDI
                                          .onboardingOrganizationStructureCubit
                                          .deleteRole(r["roleId"], projectId);

                                      // Check the state after deletion and show appropriate snackbar
                                      if (context.mounted) {
                                        final state = AppDI
                                            .onboardingOrganizationStructureCubit
                                            .state;
                                        if (state.processState ==
                                            ProcessState.done) {
                                          showSnackBar(
                                            context,
                                            'Role Deleted Successfully',
                                            isSuccess: true,
                                          );
                                        } else if (state.processState ==
                                            ProcessState.error) {
                                          showSnackBar(
                                            context,
                                            state.errorMessage ??
                                                'Failed to delete role',
                                            isSuccess: false,
                                          );
                                        }
                                      }
                                    },
                                    onSecondaryPressed: () => back(),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorHelper.white.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      Assets.reportIncidentRecycleBin,
                                      width: 18,
                                      height: 18,
                                      color: ColorHelper.red,
                                    ),
                                  ),
                                ),
                              ),
                            if (PermissionHelper.hasViewPermission(
                              moduleName: "Client Admin",
                              featureName: "Role Management",
                            ))
                              EmergexButton(
                                text: TextHelper.viewdetails,
                                textColor: ColorHelper.white,
                                fontWeight: FontWeight.w600,
                                borderRadius: 50,
                                buttonHeight: 36,
                                onPressed: () {
                                  AppDI.roleDetailsCubit.getRoleDetails(
                                    r["roleId"],
                                  );

                                  openScreen(
                                    Routes.employeeteamscreen,
                                    args: {"roleId": r["roleId"]},
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
