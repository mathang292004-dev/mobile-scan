import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/presentation/case_report/approver/model/emergency_card_model.dart';
import 'package:emergex/presentation/case_report/approver/widgets/add_team_member.dart';
import 'package:emergex/presentation/case_report/approver/utils/incident_teams_utils.dart';
import 'package:flutter/material.dart';

const Color _errorRed = Color(0xFFFF4037);

class TlAssignmentCard extends StatefulWidget {
  final EmergencyResponseTeamTasks? ertTl;
  final EmergencyResponseTeamTasks? investigationTl;
  final IncidentDetails incident;
  final VoidCallback? onRefreshData;

  const TlAssignmentCard({
    super.key,
    this.ertTl,
    this.investigationTl,
    required this.incident,
    this.onRefreshData,
  });

  @override
  State<TlAssignmentCard> createState() => _TlAssignmentCardState();
}

class _TlAssignmentCardState extends State<TlAssignmentCard> {
  final ValueNotifier<bool> _isEditMode = ValueNotifier<bool>(false);

  late ValueNotifier<List<TaskDetails>> _ertTasksNotifier;
  late ValueNotifier<List<TaskDetails>> _invTasksNotifier;
  late List<TaskDetails> _ertOriginalTasks;
  late List<TaskDetails> _invOriginalTasks;

  @override
  void initState() {
    super.initState();
    _initTasks();
  }

  @override
  void didUpdateWidget(covariant TlAssignmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ertChanged = oldWidget.ertTl?.userDetails.roleId != widget.ertTl?.userDetails.roleId ||
        oldWidget.ertTl?.taskDetails.length != widget.ertTl?.taskDetails.length;
    final invChanged = oldWidget.investigationTl?.userDetails.roleId != widget.investigationTl?.userDetails.roleId ||
        oldWidget.investigationTl?.taskDetails.length != widget.investigationTl?.taskDetails.length;
    if (ertChanged || invChanged) _initTasks();
  }

  void _initTasks() {
    _ertTasksNotifier = ValueNotifier(List<TaskDetails>.from(widget.ertTl?.taskDetails ?? []));
    _invTasksNotifier = ValueNotifier(List<TaskDetails>.from(widget.investigationTl?.taskDetails ?? []));
    _ertOriginalTasks = List<TaskDetails>.from(widget.ertTl?.taskDetails ?? []);
    _invOriginalTasks = List<TaskDetails>.from(widget.investigationTl?.taskDetails ?? []);
  }

  @override
  void dispose() {
    _isEditMode.dispose();
    _ertTasksNotifier.dispose();
    _invTasksNotifier.dispose();
    super.dispose();
  }

  void _toggleTask(ValueNotifier<List<TaskDetails>> notifier, int index) {
    if (!_isEditMode.value) return;
    final tasks = notifier.value;
    final task = tasks[index];
    final isChecked =
        task.isAssigned || task.status == 'Completed' || task.status == 'Inprogress';
    final newStatus = isChecked ? 'Pending' : 'Completed';
    final updated = List<TaskDetails>.from(tasks);
    updated[index] = TaskDetails(
      taskName: task.taskName,
      status: newStatus,
      taskId: task.taskId,
      isAssigned: newStatus != 'Pending',
    );
    notifier.value = updated;
    AppDI.incidentDetailsCubit.setEmergencyCardEdit(true);
  }

  Future<void> _handleSave() async {
    AppDI.incidentDetailsCubit.setEmergencyCardEdit(false);
    final incidentId = widget.incident.incidentId ?? '';

    final ertUserId = widget.ertTl?.userDetails.roleId;
    final invUserId = widget.investigationTl?.userDetails.roleId;

    final payload = <String, dynamic>{
      'caseId': incidentId,
      if (ertUserId != null)
        'ertTeamLead': {
          'userId': ertUserId,
          'taskIds': _ertTasksNotifier.value
              .where((t) => t.isAssigned || t.status != 'Pending')
              .map((t) => t.taskId)
              .toList(),
        },
      if (invUserId != null)
        'investigationTeamLead': {
          'userId': invUserId,
          'taskIds': _invTasksNotifier.value
              .where((t) => t.isAssigned || t.status != 'Pending')
              .map((t) => t.taskId)
              .toList(),
        },
    };

    await AppDI.incidentDetailsCubit.updateReportFieldsPayload(
      payload,
      incidentId: incidentId,
    );

    _ertOriginalTasks = List<TaskDetails>.from(_ertTasksNotifier.value);
    _invOriginalTasks = List<TaskDetails>.from(_invTasksNotifier.value);
    _isEditMode.value = false;
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setEmergencyCardEdit(false);
    _ertTasksNotifier.value = List<TaskDetails>.from(_ertOriginalTasks);
    _invTasksNotifier.value = List<TaskDetails>.from(_invOriginalTasks);
    _isEditMode.value = false;
  }

  Future<void> _handleReassign(String flow) async {
    final incidentId = widget.incident.incidentId ?? '';
    final clientId = widget.incident.projectId ?? '';
    if (incidentId.isEmpty || clientId.isEmpty) return;

    final tl = flow == 'ert'
        ? getErtTlCard(widget.incident)
        : getInvestigationTlCard(widget.incident);

    final bool? wasSuccessful = await AddTeamMember.show(
      context,
      incidentId: incidentId,
      clientId: clientId,
      type: flow,
      role: 'tl',
      currentRoleId: tl?.userDetails.roleId,
    );

    if (wasSuccessful == true) {
      widget.onRefreshData?.call();
      AppDI.incidentDetailsCubit.getIncidentById(incidentId);
    }
  }

  /// Opens the dialog with the current TL pre-selected — skips user selection.
  Future<void> _handleAddTask(String flow) async {
    final incidentId = widget.incident.incidentId ?? '';
    final clientId = widget.incident.projectId ?? '';
    if (incidentId.isEmpty || clientId.isEmpty) return;

    final tl = flow == 'ert'
        ? getErtTlCard(widget.incident)
        : getInvestigationTlCard(widget.incident);

    final bool? wasSuccessful = await AddTeamMember.show(
      context,
      incidentId: incidentId,
      clientId: clientId,
      type: flow,
      role: 'tl',
      preselectedUserId: tl?.userDetails.roleId,
      skipToTaskSelect: true,
    );

    if (wasSuccessful == true) {
      widget.onRefreshData?.call();
      AppDI.incidentDetailsCubit.getIncidentById(incidentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      color: ColorHelper.white.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with edit / save / cancel
          Row(
            children: [
              Expanded(
                child: Text(
                  TextHelper.assignTeamLeader,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.black4,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isEditMode,
                builder: (context, isEdit, _) {
                  if (!isEdit) {
                    return IconButton(
                      onPressed: () {
                        if (AppDI.incidentDetailsCubit.isAnyEditActive()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please save or cancel current edits first'),
                              backgroundColor: _errorRed,
                            ),
                          );
                          return;
                        }
                        AppDI.incidentDetailsCubit.setEmergencyCardEdit(true);
                        _isEditMode.value = true;
                      },
                      icon: Image.asset(Assets.reportApEdit, height: 24, width: 24),
                    );
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _handleCancel,
                        icon: Icon(Icons.close, color: ColorHelper.textSecondary, size: 26),
                      ),
                      IconButton(
                        onPressed: _handleSave,
                        icon: Icon(Icons.check, color: ColorHelper.textSecondary, size: 26),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ERT TL
          ValueListenableBuilder<bool>(
            valueListenable: _isEditMode,
            builder: (context, isEdit, _) => _buildTlSection(
              context,
              roleLabel: TextHelper.ertTl,
              tlData: widget.ertTl,
              tasksNotifier: _ertTasksNotifier,
              isEditMode: isEdit,
              onToggleTask: (i) => _toggleTask(_ertTasksNotifier, i),
              onReassign: () => _handleReassign('ert'),
              onAddTask: () => _handleAddTask('ert'),
            ),
          ),
          const SizedBox(height: 16),
          // Investigation TL
          ValueListenableBuilder<bool>(
            valueListenable: _isEditMode,
            builder: (context, isEdit, _) => _buildTlSection(
              context,
              roleLabel: TextHelper.investigationTl,
              tlData: widget.investigationTl,
              tasksNotifier: _invTasksNotifier,
              isEditMode: isEdit,
              onToggleTask: (i) => _toggleTask(_invTasksNotifier, i),
              onReassign: () => _handleReassign('investigation'),
              onAddTask: () => _handleAddTask('investigation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTlSection(
    BuildContext context, {
    required String roleLabel,
    required EmergencyResponseTeamTasks? tlData,
    required ValueNotifier<List<TaskDetails>> tasksNotifier,
    required bool isEditMode,
    required void Function(int) onToggleTask,
    required VoidCallback onReassign,
    required VoidCallback onAddTask,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              roleLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: ColorHelper.black4,
              ),
            ),
            Opacity(
              opacity: isEditMode ? 0.4 : 1.0,
              child: GestureDetector(
                onTap: isEditMode ? null : onReassign,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorHelper.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: ColorHelper.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    TextHelper.reassign,
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
        const SizedBox(height: 10),
        tlData != null
            ? _buildTlContentCard(
                context,
                tl: tlData,
                tasksNotifier: tasksNotifier,
                isEditMode: isEditMode,
                onToggleTask: onToggleTask,
                onAddTask: onAddTask,
              )
            : _buildEmptyTlCard(context),
      ],
    );
  }

  Widget _buildTlContentCard(
    BuildContext context, {
    required EmergencyResponseTeamTasks tl,
    required ValueNotifier<List<TaskDetails>> tasksNotifier,
    required bool isEditMode,
    required void Function(int) onToggleTask,
    required VoidCallback onAddTask,
  }) {
    final name = tl.userDetails.userName;
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Column(
        children: [
          // Profile row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
              color: ColorHelper.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(16),
              ),),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: ColorHelper.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ColorHelper.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorHelper.primaryColor,
                      ),
                    ),
                    Text(
                      TextHelper.teamLeaderLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.black4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
          // Incident info row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.transparent,
            child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: ColorHelper.primaryColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(16),
            ),),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(context, TextHelper.incidentId, widget.incident.incidentId ?? '-'),
                ),
                Expanded(
                  child: _buildInfoColumn(context, TextHelper.incident, widget.incident.title ?? '-'),
                ),
              ],
            ),
            ),
          ),
          // Tasks section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TextHelper.tasksLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF373737),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<TaskDetails>>(
                  valueListenable: tasksNotifier,
                  builder: (context, tasks, _) {
                    // Show all tasks — every task in the TL's array is assigned.
                    final visibleTasks = tasks.asMap().entries.toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (visibleTasks.isEmpty)
                          Text(
                            TextHelper.noTaskAssign,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF2C2C2E).withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: SingleChildScrollView(
                              child: Column(
                                children: visibleTasks.map((entry) {
                                  return _buildTaskRow(
                                    context,
                                    task: entry.value,
                                    index: entry.key,
                                    isEditMode: isEditMode,
                                    onToggle: onToggleTask,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Center(
                          child: Opacity(
                            opacity: 0.5,
                            child: GestureDetector(
                              onTap: onAddTask,
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
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTlCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Center(
        child: Text(
          TextHelper.noTaskAssign,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.black4.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorHelper.primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColorHelper.black4),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTaskRow(
    BuildContext context, {
    required TaskDetails task,
    required int index,
    required bool isEditMode,
    required void Function(int) onToggle,
  }) {
    final isChecked = task.isAssigned || task.status != 'Pending';

    return InkWell(
      onTap: isEditMode ? () => onToggle(index) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Opacity(
              opacity: isEditMode ? 1.0 : 0.5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isChecked ? ColorHelper.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isChecked
                        ? ColorHelper.primaryColor
                        : (isEditMode ? _errorRed : Colors.grey),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.taskName,
                style: TextStyle(
                  color: isEditMode ? Colors.black : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
