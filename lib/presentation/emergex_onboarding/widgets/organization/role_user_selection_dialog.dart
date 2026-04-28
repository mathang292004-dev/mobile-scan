import 'dart:ui';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/fetch_members_cubit/fetch_members_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_details_cubit/role_details_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/user_selection_cubit/user_selection_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'role_user_list_widget.dart';

/// Unified dialog for selecting users when creating or editing a role.
/// Uses isEditMode boolean to differentiate between create and edit modes.
class RoleUserSelectionDialog extends StatelessWidget {
  final String? projectId;
  final Function(String userId, String userName, String email)? onUserSelected;
  final Function(String userId)? onUserRemoved;
  final List<AssignedUser>? assignedUsers;
  final String? roleId;
  final bool isEditMode;

  const RoleUserSelectionDialog({
    super.key,
    this.projectId,
    this.onUserSelected,
    this.onUserRemoved,
    this.assignedUsers,
    this.roleId,
    this.isEditMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    String? projectId,
    Function(String userId, String userName, String email)? onUserSelected,
    Function(String userId)? onUserRemoved,
    List<AssignedUser>? assignedUsers,
    String? roleId,
    bool isEditMode = false,
  }) async {
    // Initialize cubit before showing dialog
    final userSelectionCubit = UserSelectionCubit(initialUsers: assignedUsers);

    // Fetch members when dialog is about to open
    if (projectId != null && projectId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppDI.fetchMembersCubit.fetchMembers(projectId);
      });
    }

    // Clear role details session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        AppDI.roleDetailsCubit.clearSessionSelections();
        if (!isEditMode) {
          AppDI.roleDetailsCubit.reset();
        }
      } catch (e) {
        debugPrint('Error clearing role details session: $e');
      }
    });

    await showGeneralDialog(
      context: context,
      barrierDismissible: !isEditMode,
      barrierColor: ColorHelper.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 200),
      barrierLabel: "RoleUserSelectionDialog",
      pageBuilder: (context, animation, secondaryAnimation) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: AppDI.fetchMembersCubit),
            BlocProvider.value(value: userSelectionCubit),
            BlocProvider.value(value: AppDI.roleDetailsCubit),
          ],
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Center(
              child: RoleUserSelectionDialog(
                projectId: projectId,
                onUserSelected: onUserSelected,
                onUserRemoved: onUserRemoved,
                assignedUsers: assignedUsers,
                roleId: roleId,
                isEditMode: isEditMode,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchMembersCubit, FetchMembersState>(
      builder: (context, state) {
        if (isEditMode) {
          return _buildEditModeDialog(context, state);
        } else {
          return _buildCreateModeDialog(context, state);
        }
      },
    );
  }

  Widget _buildCreateModeDialog(BuildContext context, FetchMembersState state) {
    return BlocBuilder<UserSelectionCubit, UserSelectionState>(
      builder: (context, selectionState) {
        return AlertDialog(
          backgroundColor: ColorHelper.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: ColorHelper.white, width: 2),
          ),
          insetPadding: const EdgeInsets.all(16),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 400,
            height: 700,
            child: Column(
              children: [
                DialogTitleBar(
                  title: TextHelper.addUsers,
                  onClose: () => back(),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  initialValue: selectionState.searchQuery,
                  hint: TextHelper.searchUsers,
                  fillColor: ColorHelper.white,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: ColorHelper.black4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide.none,
                  ),
                  onChanged: (value) {
                    context.read<UserSelectionCubit>().setSearchQuery(value);
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorHelper.successColor.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ColorHelper.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: _buildCreateModeMembersList(
                      context,
                      state,
                      selectionState.searchQuery,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorHelper.primaryColor,
                        backgroundColor: ColorHelper.surfaceColor.withValues(
                          alpha: 0.8,
                        ),
                        side: const BorderSide(
                          color: ColorHelper.white,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      onPressed: () => back(),
                      child: Text(TextHelper.cancel),
                    ),
                    const SizedBox(width: 16),
                    EmergexButton(
                      disabled: selectionState.sessionSelectedUserIds.isEmpty,
                      width: 100,
                      buttonHeight: 40,
                      text: TextHelper.done,
                      onPressed: selectionState.sessionSelectedUserIds.isEmpty
                          ? null
                          : () => _handleCreateDone(context),
                      borderRadius: 35,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditModeDialog(BuildContext context, FetchMembersState state) {
    final GlobalKey<RoleUserListWidgetState> roleUserListKey = GlobalKey();
final searchController = TextEditingController();
    return BlocBuilder<UserSelectionCubit, UserSelectionState>(
      builder: (context, selectionState) {
        return AlertDialog(
          backgroundColor: ColorHelper.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: ColorHelper.white, width: 2),
          ),
          insetPadding: const EdgeInsets.all(16),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 400,
            height: 700,
            child: Column(
              children: [
                DialogTitleBar(title: TextHelper.addUsers, onClose: () => back()),
                const SizedBox(height: 20),
                AppTextField(
  controller: searchController,
  hint: TextHelper.searchUsers,
  fillColor: ColorHelper.white,
  prefixIcon: const Icon(Icons.search, color: ColorHelper.black4),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(35),
    borderSide: BorderSide.none,
  ),
  onChanged: (value) {
    context.read<UserSelectionCubit>().setSearchQuery(value);
  },
),

                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorHelper.successColor.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ColorHelper.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: _buildEditModeMembersList(
                        context,
                        state,
                        roleUserListKey,
                        selectionState.searchQuery,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorHelper.primaryColor,
                        backgroundColor: ColorHelper.surfaceColor.withValues(
                          alpha: 0.8,
                        ),
                        side: const BorderSide(color: ColorHelper.white, width: 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      onPressed: () {
                        final roleListState = roleUserListKey.currentState;
                        roleListState?.cancelSelections();
                        back();
                      },
                      child: Text(TextHelper.cancel),
                    ),
                    const SizedBox(width: 16),
                    BlocBuilder<RoleDetailsCubit, RoleDetailsState>(
                      builder: (context, roleState) {
                        final hasSelectedUsers = (roleState.sessionSelectedUsers.isNotEmpty);
                        return EmergexButton(
                          width: 100,
                          buttonHeight: 40,
                          text: TextHelper.done,
                          disabled: !hasSelectedUsers,
                          onPressed:
                               () {
                                  final roleListState = roleUserListKey.currentState;
                                  roleListState?.addAllSelectedUsers();
                                  back();
                                },

                          borderRadius: 35,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCreateDone(BuildContext context) {
    final fetchMembersState = AppDI.fetchMembersCubit.state;
    final members = fetchMembersState.membersResponse?.members ?? [];
    final userSelectionCubit = context.read<UserSelectionCubit>();
    final selectionState = userSelectionCubit.state;

    final sessionSelectedIds = selectionState.sessionSelectedUserIds;
    final initialIds = selectionState.initialUserIds;
    final currentSelectedIds = selectionState.selectedUserIds;

    for (final userId in sessionSelectedIds) {
      final member = members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => throw Exception('Member not found: $userId'),
      );
      onUserSelected?.call(userId, member.name, member.email);
    }
    final removedUsers = initialIds.difference(currentSelectedIds);
    for (final userId in removedUsers) {
      onUserRemoved?.call(userId);
    }

    back();
  }

  Widget _buildCreateModeMembersList(
    BuildContext context,
    FetchMembersState state,
    String searchQuery,
  ) {
    if (state.processState == ProcessState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.processState == ProcessState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage ?? 'Failed to load members',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (projectId != null) {
                  AppDI.fetchMembersCubit.fetchMembers(projectId!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final members = state.membersResponse?.members ?? [];

    if (members.isEmpty) {
      return Center(
        child: Text(
          'No members available',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
        ),
      );
    }

    return BlocBuilder<UserSelectionCubit, UserSelectionState>(
      builder: (context, selectionState) {
        final query = searchQuery.toLowerCase();

        final filteredMembers = query.isEmpty
            ? members
            : members.where((member) {
                final name = member.name.toLowerCase();
                final email = member.email.toLowerCase();
                return name.contains(query) || email.contains(query);
              }).toList();

        return ListView.builder(
          itemCount: filteredMembers.length,
          itemBuilder: (context, index) {
            final member = filteredMembers[index];
            final isInitialUser = selectionState.initialUserIds.contains(
              member.userId,
            );
            final isSessionSelected = selectionState.sessionSelectedUserIds
                .contains(member.userId);
            final isSelected = selectionState.selectedUserIds.contains(
              member.userId,
            );

            if (isInitialUser && !isSessionSelected) {
              return const SizedBox.shrink();
            }

            final userSelectionCubit = context.read<UserSelectionCubit>();

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
                        color: ColorHelper.primaryColor.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : 'U',
                          style: Theme.of(context).textTheme.titleMedium
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: ColorHelper.titleMemberColor,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: ColorHelper.black4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 20,),
                        if (!isSelected)
                          GestureDetector(
                            onTap: () {
                              userSelectionCubit.addUser(member.userId);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ColorHelper.successColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ColorHelper.successColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add,
                                  color: ColorHelper.successColor,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        if (isSelected)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ColorHelper.successColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ColorHelper.successColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Image(
                                image: AssetImage(Assets.tik),
                                height: 20,
                                width: 20,
                              ),
                            ),
                          ),
                        if (isSelected) const SizedBox(width: 8),
                        if (isSelected)
                          GestureDetector(
                            onTap: () {
                              userSelectionCubit.removeUser(member.userId);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ColorHelper.crosscolor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ColorHelper.crosscolor.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close,
                                  color: ColorHelper.crosscolor,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditModeMembersList(
    BuildContext context,
    FetchMembersState state,
    GlobalKey<RoleUserListWidgetState> roleUserListKey,
    String searchQuery,
  ) {
    if (state.processState == ProcessState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.processState == ProcessState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage ?? 'Failed to load members',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (projectId != null) {
                  AppDI.fetchMembersCubit.fetchMembers(projectId!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final members = state.membersResponse?.members ?? [];

    if (members.isEmpty) {
      return Center(
        child: Text(
          'No members available',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
        ),
      );
    }

    // Filter members based on search query
    final query = searchQuery.toLowerCase();
    final filteredMembers = query.isEmpty
        ? members
        : members.where((member) {
            final name = member.name.toLowerCase();
            final email = member.email.toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();

    final List<Map<String, String>> membersList = filteredMembers.map((member) {
      return {
        "name": member.name,
        "role": member.email.isNotEmpty ? member.email : "Member",
        "email": member.email,
        "image": "",
        "userId": member.userId,
      };
    }).toList();

    return BlocProvider.value(
      value: AppDI.roleDetailsCubit,
      child: RoleUserListWidget(
        key: roleUserListKey,
        showAddIcon: true,
        employees: membersList,
        roleId: roleId,
        assignedUsers: assignedUsers ?? [],
        onUserAdded: (userMap) {
          final userId = userMap["userId"] ?? '';
          final userName = userMap["name"] ?? '';
          final member = members.firstWhere(
            (m) => m.userId == userId,
            orElse: () => members.firstWhere(
              (m) => m.name == userName,
              orElse: () => members.isNotEmpty
                  ? members.first
                  : throw Exception('No member found'),
            ),
          );
          onUserSelected?.call(userId, userName, member.email);
        },
      ),
    );
  }
}
