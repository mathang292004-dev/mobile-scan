import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/generated/color_helper.dart';

import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_details_cubit/role_details_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_form_cubit/role_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/role_form_utils.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/organization/labeled_field_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/organization/role_assigned_users_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/organization/role_permissions_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form content widget for editing a role
class EditRoleFormContent extends StatefulWidget {
  final String? roleId;
  final String? projectId;
  final RoleDetails? roleDetails;
  final List<AssignedUser> assignedUsers;
  final RoleFormState formState;
  final RoleDetailsState roleDetailsState;

  const EditRoleFormContent({
    super.key,
    required this.roleId,
    required this.projectId,
    required this.roleDetails,
    required this.assignedUsers,
    required this.formState,
    required this.roleDetailsState,
  });

  @override
  State<EditRoleFormContent> createState() => _EditRoleFormContentState();
}

class _EditRoleFormContentState extends State<EditRoleFormContent> {
  late TextEditingController roleNameController;
  late TextEditingController designationController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    roleNameController = TextEditingController(text: widget.formState.roleName);
    designationController = TextEditingController(
      text: widget.formState.designation,
    );
    descriptionController = TextEditingController(
      text: widget.formState.description,
    );
  }

  @override
  void didUpdateWidget(EditRoleFormContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.formState.roleName != oldWidget.formState.roleName) {
      final selection = roleNameController.selection;
      roleNameController.value = TextEditingValue(
        text: widget.formState.roleName,
        selection: selection,
      );
    }

    if (widget.formState.designation != oldWidget.formState.designation) {
      final selection = designationController.selection;
      designationController.value = TextEditingValue(
        text: widget.formState.designation,
        selection: selection,
      );
    }

    if (widget.formState.description != oldWidget.formState.description) {
      final selection = descriptionController.selection;
      descriptionController.value = TextEditingValue(
        text: widget.formState.description,
        selection: selection,
      );
    }
  }

  @override
  void dispose() {
    roleNameController.dispose();
    designationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<RoleFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                RoleFormUtils.handleBackNavigation(
                  context,
                  widget.assignedUsers,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorHelper.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ColorHelper.textLight, width: 1),
                ),
                child: Icon(
                  Icons.keyboard_arrow_left,
                  size: 24,
                  color: ColorHelper.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.roleDetails?.roleName?.toString() ?? 'Edit Role',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.organizationStructure,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorHelper.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ColorHelper.white),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TextHelper.roledetails,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorHelper.black4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LabeledFieldWidget(
                            label: "Role Name",
                            isRequired: true,
                            hint: "Enter Role Name",
                            controller: roleNameController,
                            onChanged: (value) {
                              formCubit.updateRoleName(value);
                            },
                          ),
                          const SizedBox(height: 10),
                          LabeledFieldWidget(
                            label: "Designation",
                            isRequired: true,
                            hint: "Enter Designation",
                            controller: designationController,
                            onChanged: (value) {
                              formCubit.updateDesignation(value);
                            },
                          ),

                          const SizedBox(height: 10),
                          LabeledFieldWidget(
                            label: "Description",
                            isRequired: true,
                            hint: "Enter Description",
                            maxLines: 3,
                            controller: descriptionController,
                            onChanged: (value) {
                              formCubit.updateDescription(value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                BlocBuilder<RoleFormCubit, RoleFormState>(
                  builder: (context, formState) {
                    final formCubit = context.read<RoleFormCubit>();
                    // Use current permissions from cubit if available, otherwise use roleDetails
                    final permissionsToShow =
                        formState.currentPermissions.isNotEmpty
                        ? formState.currentPermissions
                        : (widget.roleDetails?.permissions ?? []);

                    // Reconstruct modulePermissions if original had modules
                    List<ModulePermission>? reconstructedModules;
                    if (widget.roleDetails?.modulePermissions != null &&
                        widget.roleDetails!.modulePermissions!.isNotEmpty) {
                      // Reconstruct modules with updated permissions
                      reconstructedModules = widget
                          .roleDetails!
                          .modulePermissions!
                          .map((originalModule) {
                            // Map features from original module, but use updated permissions
                            final updatedFeatures = originalModule.features.map((
                              originalFeature,
                            ) {
                              // Find the updated permission for this feature
                              // Match by BOTH moduleName AND featureName to ensure
                              // module-scoped permission isolation
                              final updatedPermission = permissionsToShow
                                  .firstWhere(
                                    (perm) =>
                                        perm.featureName ==
                                            originalFeature.featureName &&
                                        perm.moduleName ==
                                            originalModule.moduleName,
                                    orElse: () => originalFeature,
                                  );
                              return updatedPermission;
                            }).toList();

                            return ModulePermission(
                              moduleName: originalModule.moduleName,
                              features: updatedFeatures,
                            );
                          })
                          .toList();
                    }

                    // Create a temporary RoleDetails with current permissions for display
                    final displayRoleDetails = widget.roleDetails != null
                        ? RoleDetails(
                            roleId: widget.roleDetails!.roleId,
                            roleName: widget.roleDetails!.roleName,
                            designation: widget.roleDetails!.designation,
                            description: widget.roleDetails!.description,
                            projectId: widget.roleDetails!.projectId,
                            permissions: permissionsToShow,
                            modulePermissions: reconstructedModules,
                          )
                        : null;

                    return RolePermissionsWidget(
                      roleDetails: displayRoleDetails,
                      isReadOnly: false,
                      onPermissionChanged:
                          (featureName, moduleName, index, value) {
                            formCubit.updatePermission(
                              featureName,
                              moduleName,
                              index,
                              value,
                            );
                          },
                    );
                  },
                ),
                const SizedBox(height: 16),
                BlocBuilder<RoleDetailsCubit, RoleDetailsState>(
                  builder: (context, roleState) {
                    final currentAssignedUsers =
                        roleState.roleDetailsResponse?.assignedUsers ?? [];
                    return RoleAssignedUsersWidget(
                      projectId: widget.projectId,
                      hasAssignedUsers: currentAssignedUsers.isNotEmpty,
                      assignedUsers: currentAssignedUsers,
                      roleId: widget.roleDetails?.roleId,
                      onUserAdded: (userId, userName, email) {
                        // Use session selection pattern to add user
                        final roleDetailsCubit = context
                            .read<RoleDetailsCubit>();
                        roleDetailsCubit.addToSessionSelection(userId, {
                          'name': userName,
                          'email': email,
                        });
                        roleDetailsCubit.commitAllSessionSelections();
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: ColorHelper.surfaceColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      EmergexButton(
                        width: 100,
                        buttonHeight: 40,
                        text: TextHelper.cancel,
                        borderRadius: 12,
                        textColor: ColorHelper.primaryColor,
                        colors: [
                          ColorHelper.surfaceColor.withValues(alpha: 0.6),
                          ColorHelper.surfaceColor.withValues(alpha: 0.6),
                        ],
                        onPressed: () {
                          RoleFormUtils.handleBackNavigation(
                            context,
                            widget
                                    .roleDetailsState
                                    .roleDetailsResponse
                                    ?.assignedUsers ??
                                [],
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      BlocBuilder<RoleDetailsCubit, RoleDetailsState>(
                        builder: (context, roleDetailsState) {
                          final currentAssignedUsers =
                              roleDetailsState
                                  .roleDetailsResponse
                                  ?.assignedUsers ??
                              [];
                          return BlocBuilder<RoleFormCubit, RoleFormState>(
                            builder: (context, formState) {
                              return BlocBuilder<
                                OnboardingOrganizationStructureCubit,
                                OnboardingOrganizationStructureState
                              >(
                                builder: (context, orgState) {
                                  final formCubit = context
                                      .read<RoleFormCubit>();
                                  final hasChanges = formCubit.hasChanges(
                                    currentAssignedUsers,
                                  );
                                  final isLoading =
                                      roleDetailsState.processState ==
                                          ProcessState.loading ||
                                      orgState.processState ==
                                          ProcessState.loading;

                                  // Check if all text fields are filled
                                  final areFieldsFilled =
                                      formState.roleName.trim().isNotEmpty &&
                                      formState.designation.trim().isNotEmpty &&
                                      formState.description.trim().isNotEmpty;

                                  // Check if at least one user is assigned
                                  final hasUsers =
                                      currentAssignedUsers.isNotEmpty;

                                  // Button is enabled only if: has changes, all fields filled, has users, and not loading
                                  final canSave =
                                      hasChanges &&
                                      areFieldsFilled &&
                                      hasUsers &&
                                      !isLoading;

                                  return EmergexButton(
                                    text: TextHelper.savechanges,
                                    textColor: ColorHelper.white,
                                    borderRadius: 12,
                                    buttonHeight: 40,
                                    disabled: !canSave,
                                    onPressed: canSave
                                        ? () {
                                            RoleFormUtils.handleUpdateRole(
                                              context,
                                              widget.roleId,
                                              widget.projectId,
                                              widget.roleDetails,
                                              currentAssignedUsers,
                                            );
                                            // Navigation is handled by BlocListener in organized_edit_member.dart
                                            // after the API call succeeds and RoleDetailsCubit is refreshed
                                          }
                                        : null,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
