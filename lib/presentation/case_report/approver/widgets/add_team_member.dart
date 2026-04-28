import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/custom_dropdown.dart';
import 'package:emergex/presentation/case_report/approver/cubit/reassign_eligible_users_cubit.dart';
import 'package:emergex/presentation/case_report/approver/model/reassign_eligible_users_model.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Assign / Reassign Team Member dialog.
///
/// Figma: 32:105831 (selecting) → 32:107011 (after select + tasks)
class AddTeamMember extends StatefulWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onSuccess;
  final String incidentId;
  final String clientId;
  final String type;
  final String role;
  final String? currentRoleId;
  final String? preselectedUserId;
  final bool skipToTaskSelect;

  const AddTeamMember({
    super.key,
    required this.title,
    required this.onClose,
    required this.incidentId,
    required this.clientId,
    required this.type,
    required this.role,
    this.onSuccess,
    this.currentRoleId,
    this.preselectedUserId,
    this.skipToTaskSelect = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String incidentId,
    required String clientId,
    required String type,
    required String role,
    String? title,
    String? currentRoleId,
    String? preselectedUserId,
    bool skipToTaskSelect = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (_) => ReassignEligibleUsersCubit(
          getIt<GetIncidentByIdUseCase>(),
        ),
        child: Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: ColorHelper.transparent,
          child: AddTeamMember(
            title: title ?? TextHelper.addTeamMember,
            onClose: () => Navigator.pop(dialogContext, false),
            onSuccess: () => Navigator.pop(dialogContext, true),
            incidentId: incidentId,
            clientId: clientId,
            type: type,
            role: role,
            currentRoleId: currentRoleId,
            preselectedUserId: preselectedUserId,
            skipToTaskSelect: skipToTaskSelect,
          ),
        ),
      ),
    );
  }

  @override
  State<AddTeamMember> createState() => _AddTeamMemberState();
}

class _AddTeamMemberState extends State<AddTeamMember> {
  final ValueNotifier<bool> _isDropdownOpen = ValueNotifier<bool>(false);
  bool _taskDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReassignEligibleUsersCubit>().fetchEligibleUsers(
        clientId: widget.clientId,
        type: widget.type,
        role: widget.role,
        caseId: widget.incidentId,
      );
    });
  }

  @override
  void dispose() {
    _isDropdownOpen.dispose();
    super.dispose();
  }

  /// Opens the _AddTaskDialog directly, then auto-submits on Done.
  Future<void> _openTaskSelectDialog() async {
    final cubit = context.read<ReassignEligibleUsersCubit>();
    final state = cubit.state;
    if (state is! ReassignEligibleUsersLoaded) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _AddTaskDialog(
        selectedUser: state.selectedUser,
        categoryTasks: state.categoryTasks,
        selectedTaskIds: Set<String>.from(state.selectedTaskIds),
        onToggleTasks: (ids) {
          for (final id in ids) {
            cubit.toggleTask(id);
          }
        },
        onAddManualTask: (title, details) {
          cubit.addManualTask(title, details);
        },
      ),
    );

    // After task dialog closes, auto-submit and close
    await _handleAssign();
  }

  Future<void> _handleAssign() async {
    final cubit = context.read<ReassignEligibleUsersCubit>();
    final state = cubit.state;
    if (state is! ReassignEligibleUsersLoaded || state.selectedUser == null) {
      return;
    }

    loaderService.showLoader();
    final success = await cubit.submitReassign(
      incidentId: widget.incidentId,
      type: widget.type,
      role: widget.role,
    );
    loaderService.hideLoader();

    if (success) widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorHelper.white),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: BlocListener<ReassignEligibleUsersCubit, ReassignEligibleUsersState>(
            listener: (ctx, state) {
              if (state is ReassignEligibleUsersLoaded &&
                  widget.preselectedUserId != null &&
                  state.selectedUser == null) {
                // Try matching by userId first, then fall back to isCurrentTl
                EligibleUserModel? match;
                try {
                  match = state.users.firstWhere(
                    (u) => u.userId == widget.preselectedUserId,
                  );
                } catch (_) {
                  try {
                    match = state.users.firstWhere((u) => u.isCurrentTl);
                  } catch (_) {}
                }
                if (match != null) {
                  ctx.read<ReassignEligibleUsersCubit>().selectUser(match);
                } else if (widget.skipToTaskSelect) {
                  _taskDialogShown = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _openTaskSelectDialog();
                  });
                }
              }
              // Auto-open task selection dialog after user is selected
              if (widget.skipToTaskSelect &&
                  !_taskDialogShown &&
                  state is ReassignEligibleUsersLoaded &&
                  state.selectedUser != null) {
                _taskDialogShown = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _openTaskSelectDialog();
                });
              }
            },
            child: BlocBuilder<ReassignEligibleUsersCubit, ReassignEligibleUsersState>(
              builder: (context, state) {
                final isLoaded = state is ReassignEligibleUsersLoaded;
                final loaded = isLoaded ? state : null;
                final hasSelection = loaded?.selectedUser != null;
                final skipDropdown = widget.preselectedUserId != null;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──────────────────────────────────────────────
                      _DialogHeader(
                        title: widget.title,
                        onClose: widget.onClose,
                      ),
                      const SizedBox(height: 12),

                      // ── Member section ──────────────────────────────────────
                      if (state is ReassignEligibleUsersLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is ReassignEligibleUsersError)
                        _ErrorView(message: state.message)
                      else if (isLoaded) ...[
                        // Hide dropdown when user is preselected (add-task mode)
                        if (!skipDropdown)
                          _MemberDropdownSection(
                            users: loaded!.users,
                            selectedUser: loaded.selectedUser,
                            isDropdownOpen: _isDropdownOpen,
                          ),

                        // ── Tasks section ────────────────────────────────────
                        if (hasSelection) ...[
                          const SizedBox(height: 12),
                          _TasksSection(
                            tasks: loaded!.tasks,
                            categoryTasks: loaded.categoryTasks,
                            selectedTaskIds: loaded.selectedTaskIds,
                            manualTasks: loaded.manualTasks,
                            selectedUser: loaded.selectedUser,
                          ),
                        ] else if (skipDropdown && state is ReassignEligibleUsersLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],

                      const SizedBox(height: 12),

                      // ── Action buttons ─────────────────────────────────────
                      _ActionButtons(
                        hasSelection: hasSelection,
                        onCancel: widget.onClose,
                        onAssign: _handleAssign,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dialog Header ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _DialogHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorHelper.black4,
            ),
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ColorHelper.primaryColor.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.close, size: 14, color: ColorHelper.primaryColor),
          ),
        ),
      ],
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Member Dropdown Section ───────────────────────────────────────────────────

class _MemberDropdownSection extends StatelessWidget {
  final List<EligibleUserModel> users;
  final EligibleUserModel? selectedUser;
  final ValueNotifier<bool> isDropdownOpen;

  const _MemberDropdownSection({
    required this.users,
    required this.selectedUser,
    required this.isDropdownOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TextHelper.selectAMember,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorHelper.black4,
          ),
        ),
        const SizedBox(height: 4),
        // Dropdown pill
        ValueListenableBuilder<bool>(
          valueListenable: isDropdownOpen,
          builder: (_, isOpen, __) => GestureDetector(
            onTap: () => isDropdownOpen.value = !isOpen,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: ColorHelper.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D101824),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedUser?.name ?? TextHelper.selectMember,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        letterSpacing: -0.24,
                        color: selectedUser != null
                            ? ColorHelper.black5
                            : ColorHelper.tertiaryColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: ColorHelper.black4.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Member list (shown when dropdown open)
        ValueListenableBuilder<bool>(
          valueListenable: isDropdownOpen,
          builder: (_, isOpen, __) {
            if (!isOpen) return const SizedBox.shrink();
            final eligibleUsers =
                users.where((u) => !u.isCurrentTl).toList();
            return Column(
              children: [
                const SizedBox(height: 8),
                if (eligibleUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      TextHelper.userUnavailable,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.textSecondary,
                      ),
                    ),
                  )
                else
                  ...eligibleUsers.map(
                    (u) => _MemberCard(
                      user: u,
                      selectedUser: selectedUser,
                      onSelect: (selected) {
                        context
                            .read<ReassignEligibleUsersCubit>()
                            .selectUser(selected);
                        isDropdownOpen.value = false;
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Member Card ───────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final EligibleUserModel user;
  final EligibleUserModel? selectedUser;
  final ValueChanged<EligibleUserModel> onSelect;

  const _MemberCard({
    required this.user,
    required this.selectedUser,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedUser?.userId == user.userId;
    final isCurrentTl = user.isCurrentTl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: isCurrentTl ? null : () => onSelect(user),
        child: Container(
          height: 56,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorHelper.memberSelectedBg
                : ColorHelper.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: ColorHelper.memberSelectedBorder, width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: ColorHelper.primaryBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Name + role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: ColorHelper.black5,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: ColorHelper.black4,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Badges
              if (isCurrentTl || user.isCurrentMember)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCurrentTl)
                      _Badge(
                        label: TextHelper.currentTlBadge,
                        color: ColorHelper.primaryColor,
                      ),
                    if (user.isCurrentMember && !isCurrentTl)
                      _Badge(
                        label: TextHelper.currentMemberBadge,
                        color: ColorHelper.primaryColor.withValues(alpha: 0.7),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Tasks Section ─────────────────────────────────────────────────────────────

class _TasksSection extends StatelessWidget {
  final List<EligibleTaskModel> tasks;
  final List<TaskCategoryModel> categoryTasks;
  final Set<String> selectedTaskIds;
  final List<ManualTaskEntry> manualTasks;
  final EligibleUserModel? selectedUser;

  const _TasksSection({
    required this.tasks,
    required this.categoryTasks,
    required this.selectedTaskIds,
    required this.manualTasks,
    this.selectedUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TextHelper.tasksLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorHelper.black4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorHelper.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ColorHelper.taskCardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Task list
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Library tasks
                    if (tasks.isEmpty && manualTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          TextHelper.noDataAvailable,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorHelper.textSecondary,
                          ),
                        ),
                      )
                    else ...[
                      ...tasks.map((task) {
                        final isChecked =
                            selectedTaskIds.contains(task.libraryTaskId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TaskCheckboxRow(
                            label: task.taskTitle,
                            isChecked: isChecked,
                            onTap: () => context
                                .read<ReassignEligibleUsersCubit>()
                                .toggleTask(task.libraryTaskId),
                          ),
                        );
                      }),
                      // Manual tasks (always shown as selected)
                      if (manualTasks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...manualTasks.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: ColorHelper.checkboxChecked,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.check, size: 14, color: ColorHelper.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.taskTitle,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2C2C2E),
                                      ),
                                    ),
                                    if (m.taskDetails.isNotEmpty)
                                      Text(
                                        m.taskDetails,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontSize: 10,
                                          color: ColorHelper.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ],
                ),
              ),
              // +Add Task footer
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: ColorHelper.taskSeparator, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showAddTaskDialog(context),
                    child: Text(
                      TextHelper.addTask,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorHelper.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final cubit = context.read<ReassignEligibleUsersCubit>();
    final state = cubit.state;
    if (state is! ReassignEligibleUsersLoaded) return;
    showDialog<void>(
      context: context,
      builder: (_) => _AddTaskDialog(
        selectedUser: selectedUser,
        categoryTasks: categoryTasks,
        selectedTaskIds: Set<String>.from(state.selectedTaskIds),
        onToggleTasks: (ids) {
          for (final id in ids) {
            cubit.toggleTask(id);
          }
        },
        onAddManualTask: (title, details) {
          cubit.addManualTask(title, details);
        },
      ),
    );
  }
}

// ── Task Checkbox Row ─────────────────────────────────────────────────────────

class _TaskCheckboxRow extends StatelessWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;
  final bool isCategory;

  const _TaskCheckboxRow({
    required this.label,
    required this.isChecked,
    required this.onTap,
    this.isCategory = false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCategory
                  ? (isChecked
                  ?ColorHelper.rejectedTimerColor
                  : ColorHelper.transparent)
                  : (isChecked
                  ? ColorHelper.checkboxChecked
                  : ColorHelper.transparent),

              border: isCategory
                  ? Border.all(color: ColorHelper.rejectedTimerColor, width: 1)
                  : (isChecked
                  ? null
                  : Border.all(
                color: ColorHelper.checkboxUnchecked,
                width: 1,
              )),

              borderRadius: BorderRadius.circular(4),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 14, color: ColorHelper.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: const Color(0xFF2C2C2E),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Task Manually Dialog ──────────────────────────────────────────────────
// Figma: 32:107891

class _AddTaskManuallyDialog extends StatefulWidget {
  final void Function(String title, String details) onSave;

  const _AddTaskManuallyDialog({required this.onSave});

  @override
  State<_AddTaskManuallyDialog> createState() => _AddTaskManuallyDialogState();
}

class _AddTaskManuallyDialogState extends State<_AddTaskManuallyDialog> {
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: ColorHelper.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorHelper.white.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    TextHelper.addTaskManually,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.black4,
                    ),
                  ),
                ),
                // GestureDetector(
                //   onTap: () => Navigator.pop(context),
                //   child: Container(
                //     width: 24,
                //     height: 24,
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       border: Border.all(
                //         color: ColorHelper.black4.withValues(alpha: 0.3),
                //       ),
                //     ),
                //     child: const Icon(
                //       Icons.close,
                //       size: 14,
                //       color: ColorHelper.black4,
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 14),
            // Form card
            Container(
              decoration: BoxDecoration(
                color: ColorHelper.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColorHelper.taskCardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Name
                  Text(
                    TextHelper.taskNameLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: ColorHelper.black4,
                      letterSpacing: -0.24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _nameController,
                    hint: TextHelper.enterTaskNameManually,
                    fillColor: ColorHelper.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Task Details
                  Text(
                    TextHelper.taskDetailsLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: ColorHelper.black4,
                      letterSpacing: -0.24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _detailsController,
                    hint: TextHelper.taskDetailsLabel,
                    fillColor: ColorHelper.inputFill,
                    maxLines: 4,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: ColorHelper.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x69FFFFFF),
                            blurRadius: 13.5,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        TextHelper.cancel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: ColorHelper.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final title = _nameController.text.trim();
                      if (title.isEmpty) return;
                      widget.onSave(title, _detailsController.text.trim());
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: ColorHelper.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x69FFFFFF),
                            blurRadius: 13.5,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        TextHelper.save,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: ColorHelper.white,
                        ),
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
  }
}

// ── Add Task Dialog ───────────────────────────────────────────────────────────
// Figma: 32:105960

class _AddTaskDialog extends StatefulWidget {
  final EligibleUserModel? selectedUser;
  final List<TaskCategoryModel> categoryTasks;
  final Set<String> selectedTaskIds;
  final void Function(List<String> ids) onToggleTasks;
  final void Function(String title, String details) onAddManualTask;

  const _AddTaskDialog({
    required this.selectedUser,
    required this.categoryTasks,
    required this.selectedTaskIds,
    required this.onToggleTasks,
    required this.onAddManualTask,
  });

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  String _selectedCategory = '';
  final Set<String> _locallySelected = {};

  @override
  void initState() {
    super.initState();
    if (widget.categoryTasks.isNotEmpty) {
      _selectedCategory = widget.categoryTasks.first.category;
    }
  }

  List<EligibleTaskModel> get _categoryTasks {
    final cat = widget.categoryTasks
        .where((c) => c.category == _selectedCategory)
        .firstOrNull;
    return cat?.tasks ?? [];
  }

  List<EligibleTaskModel> get _availableTasks => _categoryTasks
      .where((t) => !widget.selectedTaskIds.contains(t.libraryTaskId))
      .toList();

  List<EligibleTaskModel> get _assignedTasks => widget.categoryTasks
      .expand((c) => c.tasks)
      .where((t) => widget.selectedTaskIds.contains(t.libraryTaskId))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: ColorHelper.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorHelper.white.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      TextHelper.addTaskTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorHelper.black4,
                      ),
                    ),
                  ),
                  // GestureDetector(
                  //   onTap: () => Navigator.pop(context),
                  //   child: Container(
                  //     width: 24,
                  //     height: 24,
                  //     decoration: BoxDecoration(
                  //       shape: BoxShape.circle,
                  //       border: Border.all(
                  //         color: ColorHelper.black4.withValues(alpha: 0.3),
                  //       ),
                  //     ),
                  //     child: const Icon(
                  //       Icons.close,
                  //       size: 14,
                  //       color: ColorHelper.black4,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: ColorHelper.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorHelper.taskCardBorder),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected user row
                    if (widget.selectedUser != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: ColorHelper.primaryBackground,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.selectedUser!.name.isNotEmpty
                                  ? widget.selectedUser!.name[0].toUpperCase()
                                  : '?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: ColorHelper.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedUser!.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ColorHelper.primaryColor,
                                ),
                              ),
                              Text(
                                widget.selectedUser!.role,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                  fontSize: 10,
                                  color: ColorHelper.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Assigned Tasks title
                    if (_assignedTasks.isNotEmpty) ...[
                      Text(
                        TextHelper.assignedTasks,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorHelper.black4,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Task list
                    ..._assignedTasks.map(
                          (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: ColorHelper.checkboxChecked,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: ColorHelper.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.taskTitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: const Color(0xFF2C2C2E),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                const SizedBox(height: 12),

              // Category dropdown
              if (widget.categoryTasks.isNotEmpty) ...[
                Text(
                  TextHelper.selectTaskCategory,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.black4,
                  ),
                ),
                const SizedBox(height: 8),
                CustomDropdown(
                  isFullWidth: true,
                  items: widget.categoryTasks.map((c) => c.category).toList(),
                  initialValue: _selectedCategory,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.textColorDefault,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Task list from selected category
              if (_availableTasks.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: ColorHelper.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColorHelper.taskCardBorder),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: _availableTasks
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TaskCheckboxRow(
                              label: t.taskTitle,
                              isChecked: _locallySelected.contains(
                                t.libraryTaskId,
                              ),
                              onTap: () => setState(() {
                                if (_locallySelected.contains(
                                  t.libraryTaskId,
                                )) {
                                  _locallySelected.remove(t.libraryTaskId);
                                } else {
                                  _locallySelected.add(t.libraryTaskId);
                                }
                              }),
                              isCategory: true,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Add Task Manually link
              Center(
                child: GestureDetector(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => _AddTaskManuallyDialog(
                        onSave: widget.onAddManualTask,
                      ),
                    );
                  },
                  child: Text(
                    TextHelper.addTaskManually,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Cancel / Done buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: ColorHelper.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x69FFFFFF),
                              blurRadius: 13.5,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          TextHelper.cancel,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ColorHelper.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_locallySelected.isNotEmpty) {
                          widget.onToggleTasks(_locallySelected.toList());
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: ColorHelper.primaryColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x69FFFFFF),
                              blurRadius: 13.5,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          TextHelper.done,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ColorHelper.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback onCancel;
  final VoidCallback onAssign;

  const _ActionButtons({
    required this.hasSelection,
    required this.onCancel,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onCancel,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: ColorHelper.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x69FFFFFF),
                    blurRadius: 13.5,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                TextHelper.cancel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: ColorHelper.primaryColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: hasSelection ? onAssign : null,
            child: Opacity(
              opacity: hasSelection ? 1.0 : 0.5,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: ColorHelper.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x69FFFFFF),
                      blurRadius: 13.5,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  TextHelper.assignLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: ColorHelper.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
