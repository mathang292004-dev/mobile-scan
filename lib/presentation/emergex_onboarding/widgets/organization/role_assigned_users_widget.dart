import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_details_cubit/role_details_cubit.dart';
import 'role_user_selection_dialog.dart';

/// Widget for displaying and managing assigned users for a role.
/// Used in create, edit, and view role screens.
class RoleAssignedUsersWidget extends StatelessWidget {
  final bool hasAssignedUsers;
  final List<AssignedUser> assignedUsers;
  final bool showDeleteIcon;
  final bool isReadOnly;
  final String? projectId;
  final String? roleId;
  final Function(String userId, String userName, String email)? onUserAdded;
  final Function(String userId)? onUserDeleted;

  const RoleAssignedUsersWidget({
    super.key,
    this.hasAssignedUsers = false,
    this.assignedUsers = const [],
    this.showDeleteIcon = true,
    this.isReadOnly = false,
    this.projectId,
    this.roleId,
    this.onUserAdded,
    this.onUserDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleDetailsCubit, RoleDetailsState>(
      bloc: AppDI.roleDetailsCubit,
      listener: (context, state) {
        // Show error message if delete fails
        if (state.processState == ProcessState.error &&
            state.errorMessage != null &&
            state.errorMessage!.isNotEmpty) {
          if (context.mounted) {
            showSnackBar(context, state.errorMessage!, isSuccess: false);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorHelper.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TextHelper.assignedUsers,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ColorHelper.textSecondary,
                  ),
                ),
                !isReadOnly &&
                        (PermissionHelper.hasCreatePermission(
                          moduleName: "Client Admin",
                          featureName: "User Management",
                        ))
                    ? ElevatedButton.icon(
                        onPressed: () {
                          // Use unified dialog with isEditMode flag
                          final isEdit = roleId != null && roleId!.isNotEmpty;
                          RoleUserSelectionDialog.show(
                            context,
                            projectId: projectId,
                            roleId: roleId,
                            assignedUsers: assignedUsers,
                            isEditMode: isEdit,
                            onUserSelected: (userId, userName, email) {
                              onUserAdded?.call(userId, userName, email);
                            },
                            onUserRemoved: (userId) {
                              onUserDeleted?.call(userId);
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.add,
                          color: ColorHelper.primaryColor,
                          size: 20,
                        ),
                        label: Text(
                          TextHelper.add,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorHelper.primaryColor,
                              ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorHelper.newClient.withValues(
                            alpha: 0.7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(
                              color: ColorHelper.addMemberColor,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
                          ),
                          minimumSize: const Size(50, 30),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 20),
            assignedUsers.isNotEmpty
                ? SingleChildScrollView(
                    child: Column(
                      children: assignedUsers.map((user) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorHelper.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorHelper.grey.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorHelper.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : 'U',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: ColorHelper.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: ColorHelper.textPrimary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorHelper.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (showDeleteIcon && !isReadOnly &&
                                    (PermissionHelper.hasDeletePermission(
                                      moduleName: "Client Admin",
                                      featureName: "User Management",
                                    )))
                                  IconButton(
                                    icon: Image.asset(
                                      Assets.reportIncidentRecycleBin,
                                      height: 20,
                                      width: 20,
                                    ),
                                    onPressed: () {
                                      CustomDialog.showError(
                                        context: context,
                                        title: TextHelper.areYouSure,
                                        subtitle: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              TextHelper.userError,
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: ColorHelper.errorColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: ColorHelper.white,
                                                  width: 9,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: ColorHelper
                                                          .primaryColor
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        user.name.isNotEmpty
                                                            ? user.name[0]
                                                                  .toUpperCase()
                                                            : 'U',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                              color: ColorHelper
                                                                  .primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          user.name,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 15,
                                                                color:
                                                                    ColorHelper
                                                                        .black4,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          user.email,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                fontSize: 13,
                                                                color: ColorHelper
                                                                    .dateStatusColor,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        primaryButtonText: TextHelper.delete,
                                        secondaryButtonText: TextHelper.cancel,
                                        onPrimaryPressed: () {
                                          back();
                                          if (roleId != null &&
                                              roleId!.isNotEmpty) {
                                            // Remove member from cubit state (no API call)
                                            final cubit =
                                                AppDI.roleDetailsCubit;
                                            cubit.removeMember(user.userId);
                                          } else {
                                            // For create screen, just call the callback
                                            onUserDeleted?.call(user.userId);
                                          }
                                        },
                                        onSecondaryPressed: () {
                                          back();
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Center(
                    child: Column(
                      children: [
                        Image.asset(Assets.noneUsers, height: 120, width: 200),
                        const SizedBox(height: 12),
                        Text(
                          TextHelper.noUsersAssignedYet,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ColorHelper.successColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          TextHelper.addteammemberstothisrole,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ColorHelper.black4,
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
