import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_details_cubit/role_details_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';

class UserListWidget extends StatefulWidget {
  final bool showAddIcon;
  final bool showDeleteIcon;
  final Function(Map<String, String>)? onUserAdded;
  final List<Map<String, String>>? employees;
  final String? roleId;
  final List<AssignedUser>? assignedUsers;

  const UserListWidget({
    super.key,
    this.showAddIcon = false,
    this.showDeleteIcon = false,
    this.onUserAdded,
    this.employees,
    this.roleId,
    this.assignedUsers,
  });

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  List<Map<String, String>> get employees => widget.employees ?? [];

  final Set<int> confirmSelectionIndexes = {};

  @override
  Widget build(BuildContext context) {
    // If roleId is provided, listen to cubit state to get updated assignedUsers
    List<AssignedUser> currentAssignedUsers = widget.assignedUsers ?? [];

    if (widget.roleId != null && widget.roleId!.isNotEmpty) {
      return BlocBuilder<RoleDetailsCubit, RoleDetailsState>(
        builder: (context, state) {
          // Get updated assignedUsers from cubit state
          final updatedAssignedUsers =
              state.roleDetailsResponse?.assignedUsers ?? [];
          currentAssignedUsers = updatedAssignedUsers.isNotEmpty
              ? updatedAssignedUsers
              : (widget.assignedUsers ?? []);

          return _buildUserList(currentAssignedUsers);
        },
      );
    }

    return _buildUserList(currentAssignedUsers);
  }

  Widget _buildUserList(List<AssignedUser> assignedUsers) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: employees.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final emp = employees[index];
        final bool isConfirming = confirmSelectionIndexes.contains(index);
        final userId = emp["userId"] ?? '';
        final bool isAlreadySelected = assignedUsers.any(
          (u) => u.userId == userId,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorHelper.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: ColorHelper.grey.withValues(alpha: 0.05),
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
                    color: emp["image"]?.isNotEmpty == true
                        ? null
                        : ColorHelper.primaryColor.withValues(alpha: 0.2),
                    image: emp["image"]?.isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(emp["image"]!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: emp["image"]?.isEmpty ?? true
                      ? Center(
                          child: Text(
                            emp["name"]?.isNotEmpty == true
                                ? emp["name"]![0].toUpperCase()
                                : 'U',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: ColorHelper.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp["name"]!,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: ColorHelper.titleMemberColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emp["role"]!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w400,

                          fontSize: 14,
                          color: ColorHelper.black4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showAddIcon)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isAlreadySelected
                        ? Row(
                            key: ValueKey('selected_$userId'),
                            children: [
                              Container(
                                width: 37,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: ColorHelper.successColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ColorHelper.successColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: ColorHelper.successColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 37,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: ColorHelper.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ColorHelper.blue.withValues(
                                      alpha: 0.1,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: ColorHelper.crosscolor,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    // Remove user if roleId is provided
                                    if (widget.roleId != null &&
                                        widget.roleId!.isNotEmpty) {
                                      try {
                                        final cubit = context
                                            .read<RoleDetailsCubit>();
                                        cubit.removeMember(userId);
                                      } catch (e) {
                                        // Handle error silently
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          )
                        : isConfirming
                        ? Row(
                            key: const ValueKey('confirmButtons'),
                            children: [
                              Container(
                                width: 37,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: ColorHelper.successColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ColorHelper.successColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.done_all,
                                    color: ColorHelper.successColor,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    widget.onUserAdded?.call(emp);
                                    setState(() {
                                      confirmSelectionIndexes.remove(index);
                                    });
                                  },
                                ),
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: ColorHelper.crosscolor,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    confirmSelectionIndexes.remove(index);
                                  });
                                },
                              ),
                            ],
                          )
                        : Container(
                            key: const ValueKey('addButton'),
                            width: 45,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ColorHelper.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ColorHelper.blue.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: ColorHelper.successColor,
                                size: 22,
                              ),
                              onPressed: () {
                                // If roleId is provided, directly call cubit addMember method
                                if (widget.roleId != null &&
                                    widget.roleId!.isNotEmpty) {
                                  try {
                                    final cubit = context
                                        .read<RoleDetailsCubit>();
                                    final userId = emp["userId"] ?? '';
                                    final userName = emp["name"] ?? '';
                                    // Use email field if available, otherwise fall back to role field
                                    final email =
                                        emp["email"] ?? emp["role"] ?? '';

                                    if (userId.isNotEmpty &&
                                        userName.isNotEmpty) {
                                      cubit.addMember(userId, userName, email);
                                    }
                                  } catch (e) {
                                    // If cubit is not available, fall back to callback
                                    widget.onUserAdded?.call(emp);
                                  }
                                } else {
                                  // For create screen or when no roleId, use confirm flow
                                  setState(() {
                                    confirmSelectionIndexes.add(index);
                                  });
                                }
                              },
                            ),
                          ),
                  )
                else if (widget.showDeleteIcon)
                  GestureDetector(
                    onTap: () {
                      final user = employees[index];
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
                                color: ColorHelper.errorColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
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
                                      image: DecorationImage(
                                        image: NetworkImage(user["image"]!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user["name"]!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: ColorHelper.black4,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user["role"]!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 13,
                                              color:
                                                  ColorHelper.dateStatusColor,
                                            ),
                                      ),
                                    ],
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
                        },
                        onSecondaryPressed: () => back(),
                      );
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorHelper.recycleBin.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Image.asset(
                          Assets.reportIncidentRecycleBin,
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
