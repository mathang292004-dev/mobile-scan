import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/presentation/case_report/approver/model/emergency_card_model.dart';
import 'package:emergex/presentation/case_report/approver/widgets/add_team_member.dart';
import 'package:flutter/material.dart';
import '../../../../data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';

// --- COLORS ---
const Color brandGreen = Color(0xFF3DA229);
const Color lightGreenBg = Color(0xFFf4faf4);
const Color errorRed = Color(0xFFFF4037);

final Map<String, Color> statusBgColors = {
  'Inprogress': const Color(0xFFFFF9C4),
  'Pending': ColorHelper.memberStatusPendingBg,
  'Done': ColorHelper.memberStatusCompletedBg,
  'Completed': ColorHelper.memberStatusCompletedBg,
};

final Map<String, Color> statusTextColors = {
  'Inprogress': const Color(0xFFF57F17),
  'Pending': ColorHelper.memberStatusPendingText,
  'Done': ColorHelper.memberStatusCompletedText,
  'Completed': ColorHelper.memberStatusCompletedText,
};

class DynamicEmergencyResponseContainer extends StatefulWidget {
  final List<EmergencyResponseTeamTasks> emergencyData;
  final VoidCallback? onAddMember;
  final VoidCallback? onRefreshTeamData;
  final IncidentDetails incident;
  final bool isEditMode;

  const DynamicEmergencyResponseContainer({
    super.key,
    required this.emergencyData,
    this.onAddMember,
    this.onRefreshTeamData,
    required this.incident,
    this.isEditMode = false,
  });

  @override
  DynamicEmergencyResponseContainerState createState() =>
      DynamicEmergencyResponseContainerState();
}

class DynamicEmergencyResponseContainerState
    extends State<DynamicEmergencyResponseContainer> {
  // Tracks whether the user has started editing tasks (shows save/cancel icons)
  final ValueNotifier<bool> _isTaskEditingNotifier = ValueNotifier<bool>(false);
  final Map<int, GlobalKey<DynamicEmergencyResponseCardState>> _cardKeys = {};
  late ScrollController _scrollController;
  final ValueNotifier<bool> _canScrollLeftNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _canScrollRightNotifier =
      ValueNotifier<bool>(false);
  final ValueNotifier<int> _taskAssignmentVersion = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _initializeCardKeys();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollState();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _isTaskEditingNotifier.dispose();
    _canScrollLeftNotifier.dispose();
    _canScrollRightNotifier.dispose();
    _taskAssignmentVersion.dispose();
    super.dispose();
  }

  bool _shouldHideEditButton() {
    final tasksList = widget.incident.task;
    if (tasksList == null || tasksList.isEmpty) return true;

    final firstItem = tasksList[0];
    if (firstItem is! Map<String, dynamic>) return true;

    if (firstItem.containsKey('user') && firstItem.containsKey('tasks')) {
      final tasks = firstItem['tasks'] as List?;
      return tasks == null || tasks.isEmpty;
    }

    if (firstItem.containsKey('taskList')) {
      final taskList = firstItem['taskList'] as List?;
      return taskList == null || taskList.isEmpty;
    }

    return true;
  }

  @override
  void didUpdateWidget(DynamicEmergencyResponseContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset task editing state when switching out of edit mode
    if (oldWidget.isEditMode && !widget.isEditMode) {
      _isTaskEditingNotifier.value = false;
    }
    if (oldWidget.emergencyData.length != widget.emergencyData.length ||
        _hasDataChanged(oldWidget.emergencyData, widget.emergencyData)) {
      _initializeCardKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollState();
      });
    }
  }

  bool _hasDataChanged(
    List<EmergencyResponseTeamTasks> oldData,
    List<EmergencyResponseTeamTasks> newData,
  ) {
    if (oldData.length != newData.length) return true;
    return oldData.asMap().entries.any((entry) {
      final i = entry.key;
      return oldData[i].userDetails.roleId != newData[i].userDetails.roleId;
    });
  }

  void _initializeCardKeys() {
    _cardKeys.clear();
    _cardKeys.addAll(
      Map.fromEntries(
        widget.emergencyData.asMap().entries.map((entry) {
          return MapEntry(
            entry.key,
            GlobalKey<DynamicEmergencyResponseCardState>(),
          );
        }),
      ),
    );
  }

  bool _canAssignTask(String taskId, String currentRoleId) {
    final result = _cardKeys.entries.fold<Map<String, dynamic>>(
      {'count': 0, 'isCurrentlyAssigned': false},
      (acc, entry) {
        final cardState = entry.value.currentState;
        if (cardState != null) {
          final task = cardState.tasks.firstWhere(
            (t) => t.taskId == taskId,
            orElse: () => TaskDetails(
              taskName: '',
              status: 'Pending',
              taskId: '',
              isAssigned: false,
            ),
          );

          if (task.taskId == taskId &&
              (task.isAssigned ||
                  task.status == 'Completed' ||
                  task.status == 'Inprogress')) {
            acc['count'] = (acc['count'] as int) + 1;
            if (cardState.widget.cardData.userDetails.roleId == currentRoleId) {
              acc['isCurrentlyAssigned'] = true;
            }
          }
        }
        return acc;
      },
    );

    return (result['isCurrentlyAssigned'] as bool) ||
        (result['count'] as int) < 2;
  }

  Future<void> _handleSave() async {
    AppDI.incidentDetailsCubit.setEmergencyCardEdit(false);

    final results = await Future.wait(
      _cardKeys.entries.map((entry) async {
        final cardState = entry.value.currentState;
        if (cardState != null) {
          return await cardState.saveTaskChanges();
        }
        return true;
      }),
    );

    final allSaved = results.every((success) => success);

    if (allSaved) {
      _isTaskEditingNotifier.value = false;
      widget.onRefreshTeamData?.call();
      final incidentId = widget.incident.incidentId ?? '';
      if (incidentId.isNotEmpty) {
        AppDI.incidentDetailsCubit.getIncidentById(incidentId);
      }
    }
  }

  void _checkDataChanged() {
    final hasChanged = _cardKeys.entries.any((entry) {
      final cardState = entry.value.currentState;
      return cardState != null && cardState._hasDataChanged();
    });
    AppDI.incidentDetailsCubit.setEmergencyCardEdit(hasChanged);
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setEmergencyCardEdit(false);
    for (var cardKey in _cardKeys.values) {
      cardKey.currentState?.resetToOriginal();
    }
    _isTaskEditingNotifier.value = false;
  }

  void _notifyTaskAssignmentChanged() {
    _taskAssignmentVersion.value++;
  }

  void _onScroll() {
    _updateScrollState();
  }

  void _updateScrollState() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final currentPosition = _scrollController.position.pixels;

    _canScrollLeftNotifier.value = currentPosition > 0;
    _canScrollRightNotifier.value = currentPosition < maxScrollExtent - 10;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + actions
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.isEditMode
                      ? TextHelper.teamsAssigned
                      : TextHelper.teamsAssignedask,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              // Edit/Save/Cancel icons — only in edit mode
              if (widget.isEditMode)
                ValueListenableBuilder<bool>(
                  valueListenable: _isTaskEditingNotifier,
                  builder: (context, isTaskEditing, _) {
                    return Row(
                      children: [
                        if (!isTaskEditing) ...[
                          _shouldHideEditButton()
                              ? const SizedBox.shrink()
                              : IconButton(
                                  onPressed: () {
                                    if (AppDI.incidentDetailsCubit
                                        .isAnyEditActive()) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please save or cancel current edits first',
                                          ),
                                          backgroundColor: errorRed,
                                        ),
                                      );
                                      return;
                                    }
                                    AppDI.incidentDetailsCubit
                                        .setEmergencyCardEdit(true);
                                    _isTaskEditingNotifier.value = true;
                                  },
                                  icon: Image.asset(
                                    Assets.reportApEdit,
                                    height: 24,
                                    width: 24,
                                  ),
                                ),
                        ] else ...[
                          IconButton(
                            onPressed: _handleCancel,
                            icon: Icon(
                              Icons.close,
                              color: ColorHelper.textSecondary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _handleSave,
                            icon: Icon(
                              Icons.check,
                              color: ColorHelper.textSecondary,
                              size: 28,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
            ],
          ),
          // Add Member button — only in edit mode
          if (widget.isEditMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: widget.onAddMember ?? () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorHelper.addMemberColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: ColorHelper.addMemberColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: ColorHelper.successColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            TextHelper.addMember,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ColorHelper.successColor,
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
          // Horizontal card list
          Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                child: widget.emergencyData.isEmpty
                    ? _buildEmptyState()
                    : ValueListenableBuilder<bool>(
                        valueListenable: _isTaskEditingNotifier,
                        builder: (context, isTaskEditing, _) {
                          return ValueListenableBuilder<int>(
                            valueListenable: _taskAssignmentVersion,
                            builder: (context, _, __) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    widget.emergencyData.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final data = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: DynamicEmergencyResponseCard(
                                      key: _cardKeys[index],
                                      cardData: data,
                                      incident: widget.incident,
                                      isEditMode: widget.isEditMode,
                                      isTaskEditing: isTaskEditing,
                                      onRemove: () => _removeCard(index),
                                      onReassign: () => _reassignCard(index),
                                      canAssignTask: _canAssignTask,
                                      onTaskAssignmentChanged:
                                          _notifyTaskAssignmentChanged,
                                      onDataChanged: _checkDataChanged,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),
              ),
              if (widget.emergencyData.isNotEmpty)
                ValueListenableBuilder<bool>(
                  valueListenable: _canScrollRightNotifier,
                  builder: (context, canScrollRight, child) {
                    if (!canScrollRight) return const SizedBox.shrink();
                    return child!;
                  },
                  child: _buildScrollIndicator(true),
                ),
              if (widget.emergencyData.isNotEmpty)
                ValueListenableBuilder<bool>(
                  valueListenable: _canScrollLeftNotifier,
                  builder: (context, canScrollLeft, child) {
                    if (!canScrollLeft) return const SizedBox.shrink();
                    return child!;
                  },
                  child: _buildScrollIndicator(false),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator(bool isRight) {
    return Positioned(
      right: isRight ? 8 : null,
      left: !isRight ? 8 : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            final double offset = isRight ? 336 : -336;
            _scrollController.animateTo(
              (_scrollController.offset + offset).clamp(
                0.0,
                _scrollController.position.maxScrollExtent,
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: brandGreen.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isRight ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          TextHelper.noEmergencyResponseTeamAssigned,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ),
    );
  }

  void _removeCard(int index) {
    final emergencyItem = widget.emergencyData[index];
    showErrorDialog(
      context,
      () => _confirmRemoveMember(index),
      () => back(),
      TextHelper.removeTeamMember,
      '${TextHelper.areYouSureYouWantToRemove} ${emergencyItem.userDetails.userName} ${TextHelper.fromThisIncident}',
      TextHelper.yes,
      TextHelper.cancel,
    );
  }

  Future<void> _confirmRemoveMember(int index) async {
    back();
    final emergencyItem = widget.emergencyData[index];
    final incidentId = emergencyItem.incidentID;
    final response = await AppDI.incidentDetailsCubit.removeMemberTask(
      incidentId,
      emergencyItem.userDetails.roleId,
    );

    if (response.success) {
      widget.onRefreshTeamData?.call();
      if (incidentId.isNotEmpty) {
        AppDI.incidentDetailsCubit.getIncidentById(incidentId);
      }
    }
  }

  Future<void> _reassignCard(int index) async {
    final emergencyItem = widget.emergencyData[index];
    final incidentId = widget.incident.incidentId ?? '';
    final clientId = widget.incident.projectId ?? '';
    if (incidentId.isEmpty || clientId.isEmpty) return;

    final bool? wasSuccessful = await AddTeamMember.show(
      context,
      incidentId: incidentId,
      clientId: clientId,
      type: 'ert',
      role: 'member',
      currentRoleId: emergencyItem.userDetails.roleId,
    );

    if (wasSuccessful == true) {
      widget.onRefreshTeamData?.call();
      AppDI.incidentDetailsCubit.getIncidentById(incidentId);
    }
  }
}

class DynamicEmergencyResponseCard extends StatefulWidget {
  final EmergencyResponseTeamTasks cardData;
  final IncidentDetails incident;
  final bool isEditMode;
  final bool isTaskEditing;
  final VoidCallback? onRemove;
  final VoidCallback? onReassign;
  final bool Function(String taskId, String roleId)? canAssignTask;
  final VoidCallback? onTaskAssignmentChanged;
  final VoidCallback? onDataChanged;

  const DynamicEmergencyResponseCard({
    super.key,
    required this.cardData,
    required this.incident,
    this.isEditMode = false,
    this.isTaskEditing = false,
    this.onRemove,
    this.onReassign,
    this.canAssignTask,
    this.onTaskAssignmentChanged,
    this.onDataChanged,
  });

  @override
  DynamicEmergencyResponseCardState createState() =>
      DynamicEmergencyResponseCardState();
}

class DynamicEmergencyResponseCardState
    extends State<DynamicEmergencyResponseCard> {
  late ValueNotifier<List<TaskDetails>> _tasksNotifier;
  late List<TaskDetails> originalTasks;

  List<TaskDetails> get tasks => _tasksNotifier.value;

  @override
  void initState() {
    super.initState();
    _tasksNotifier = ValueNotifier<List<TaskDetails>>(
      List<TaskDetails>.from(widget.cardData.taskDetails),
    );
    originalTasks = List<TaskDetails>.from(widget.cardData.taskDetails);
  }

  @override
  void dispose() {
    _tasksNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DynamicEmergencyResponseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTaskEditing && !widget.isTaskEditing) {
      _initializeTasks();
    } else if (oldWidget.cardData.userDetails.roleId !=
            widget.cardData.userDetails.roleId ||
        oldWidget.cardData.taskDetails.length !=
            widget.cardData.taskDetails.length) {
      _initializeTasks();
    }
  }

  void _initializeTasks() {
    _tasksNotifier.value =
        List<TaskDetails>.from(widget.cardData.taskDetails);
    originalTasks = List<TaskDetails>.from(widget.cardData.taskDetails);
  }

  void resetToOriginal() {
    _tasksNotifier.value = List<TaskDetails>.from(originalTasks);
  }

  void toggleTask(int taskIndex) {
    if (!widget.isTaskEditing) return;

    final currentTasks = _tasksNotifier.value;
    final currentTask = currentTasks[taskIndex];
    final isCurrentlyChecked =
        currentTask.isAssigned ||
        currentTask.status == 'Completed' ||
        currentTask.status == 'Inprogress';

    if (!isCurrentlyChecked) {
      final canAssign =
          widget.canAssignTask?.call(
            currentTask.taskId,
            widget.cardData.userDetails.roleId,
          ) ??
          true;
      if (!canAssign) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This task is already assigned to 2 members'),
          ),
        );
        return;
      }
    }

    final newStatus = isCurrentlyChecked ? 'Pending' : 'Completed';
    final updatedTasks = List<TaskDetails>.from(currentTasks);
    updatedTasks[taskIndex] = TaskDetails(
      taskName: currentTask.taskName,
      status: newStatus,
      taskId: currentTask.taskId,
      isAssigned: newStatus != 'Pending',
    );
    _tasksNotifier.value = updatedTasks;

    widget.onTaskAssignmentChanged?.call();
    widget.onDataChanged?.call();
  }

  bool _hasDataChanged() {
    final currentTasks = _tasksNotifier.value;
    if (currentTasks.length != originalTasks.length) return true;
    for (int i = 0; i < currentTasks.length; i++) {
      if (currentTasks[i].status != originalTasks[i].status ||
          currentTasks[i].isAssigned != originalTasks[i].isAssigned) {
        return true;
      }
    }
    return false;
  }

  Future<bool> saveTaskChanges() async {
    try {
      if (!_hasDataChanged()) return true;

      final currentTasks = _tasksNotifier.value;
      final incidentJson = widget.incident.toJson();
      _updateTasksInJson(incidentJson);

      final membersToSend =
          (incidentJson['members'] as List?) ?? (incidentJson['task'] as List?);
      if (membersToSend == null) return false;

      final List<Map<String, dynamic>> finalMembersList =
          membersToSend.whereType<Map<String, dynamic>>().map((member) {
        final memberMap = Map<String, dynamic>.from(member);
        final memberUserId =
            (memberMap['userId'] ?? memberMap['user']?['_id'])?.toString() ??
            '';

        if (memberUserId == widget.cardData.userDetails.roleId) {
          memberMap['tasks'] =
              currentTasks.where((t) => t.isAssigned).map((t) {
            return {'taskId': t.taskId, 'status': t.status};
          }).toList();
        }
        return memberMap;
      }).toList();

      await AppDI.incidentDetailsCubit.updateMembers(
        widget.incident.incidentId ?? '',
        finalMembersList,
      );
      originalTasks = List<TaskDetails>.from(currentTasks);
      return true;
    } catch (e) {
      resetToOriginal();
      return false;
    }
  }

  void _updateTasksInJson(Map<String, dynamic> incidentJson) {
    final currentTasks = _tasksNotifier.value;
    final array =
        (incidentJson['members'] as List?) ?? (incidentJson['task'] as List?);
    if (array == null) return;

    for (var entry in array.whereType<Map<String, dynamic>>()) {
      final entryId = (entry['user']?['_id'] ?? entry['roleId'])?.toString();
      if (entryId == widget.cardData.userDetails.roleId) {
        if (entry.containsKey('tasks')) {
          final List tasksArray = entry['tasks'];
          tasksArray.clear();
          tasksArray.addAll(
            currentTasks
                .where((t) => t.isAssigned)
                .map((t) => {'taskId': t.taskId, 'status': t.status}),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cardPadding = widget.isEditMode ? 10 : 14;

    return Container(
      width: 270,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: const Alignment(-0.7, -1.0),
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.5),
          ],
          stops: const [0.756, 1.0],
        ),
        border: Border.all(color: ColorHelper.white, width: 0.5),
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, widget.cardData.userDetails),
          const SizedBox(height: 10),
          if (widget.isEditMode) ...[
            _buildIncidentInfo(
              context,
              widget.cardData.incidentID,
              widget.cardData.incident,
            ),
            const SizedBox(height: 10),
          ],
          ValueListenableBuilder<List<TaskDetails>>(
            valueListenable: _tasksNotifier,
            builder: (context, currentTasks, _) {
              return _buildTasksSection(
                context,
                currentTasks,
                toggleTask,
                widget.incident,
                widget.isEditMode,
                widget.isTaskEditing,
                widget.canAssignTask,
                widget.cardData.userDetails.roleId,
              );
            },
          ),
          const SizedBox(height: 10),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (!widget.isEditMode) {
      // View mode: "View Details" button only
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => openScreen(
            Routes.overviewScreen,
            args: {
              'incidentId': widget.incident.incidentId,
              'userId': widget.cardData.userDetails.roleId,
            },
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: brandGreen,
            side: const BorderSide(color: brandGreen, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(TextHelper.viewdetails),
        ),
      );
    }

    // Edit mode: Remove + Reassign buttons (always shown, no permission gate)
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.isTaskEditing ? null : widget.onRemove,
            style: OutlinedButton.styleFrom(
              foregroundColor: errorRed,
              side: const BorderSide(color: errorRed, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              TextHelper.btnTxtRemove,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: widget.isTaskEditing ? null : widget.onReassign,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              TextHelper.btnTxtReassign,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// --- HELPER WIDGETS ---
Widget _buildHeader(BuildContext context, UserDetails userDetails) {
  final Color bgColor =
      statusBgColors[userDetails.taskStatus] ?? Colors.grey[200]!;
  final Color textColor =
      statusTextColors[userDetails.taskStatus] ?? Colors.grey[600]!;

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: ColorHelper.userListBackgroundColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundImage: userDetails.avatarUrl.isNotEmpty
              ? NetworkImage(userDetails.avatarUrl)
              : null,
          radius: 21,
          child: userDetails.avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      userDetails.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: brandGreen,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      userDetails.taskStatus,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                userDetails.userRole,
                style: const TextStyle(
                  color: Color(0xFF525252),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildIncidentInfo(
  BuildContext context,
  String incidentID,
  String incident,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TextHelper.incidentIdLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: brandGreen,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                incidentID,
                style: const TextStyle(color: Color(0xFF525252), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TextHelper.incidentLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: brandGreen,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                incident,
                style: const TextStyle(color: Color(0xFF525252), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTasksSection(
  BuildContext context,
  List<TaskDetails> tasks,
  void Function(int) toggleTask,
  IncidentDetails incident,
  bool isEditMode,
  bool isTaskEditing,
  bool Function(String taskId, String roleId)? canAssignTask,
  String currentRoleId,
) {
  // In view mode: only show assigned/completed tasks
  final visibleTasks = isEditMode
      ? tasks
      : tasks.where((t) => t.isAssigned || t.status != 'Pending').toList();

  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TextHelper.tasksLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF2C2C2E),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 120),
          child: SingleChildScrollView(
            child: Column(
              children: visibleTasks.asMap().entries.map((entry) {
                final originalIndex = isEditMode
                    ? entry.key
                    : tasks.indexOf(entry.value);
                return isEditMode
                    ? _buildEditTaskItem(
                        context,
                        entry.value,
                        originalIndex,
                        toggleTask,
                        isTaskEditing,
                        canAssignTask,
                        currentRoleId,
                      )
                    : _buildViewTaskItem(entry.value);
              }).toList(),
            ),
          ),
        ),
        if (isEditMode) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Opacity(
                opacity: 0.5,
                child: TextButton(
                  onPressed: null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    TextHelper.addTask,
                    style: const TextStyle(
                      color: brandGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => openScreen(
                  Routes.taskDetails,
                  args: {
                    'incidentId': incident.incidentId,
                    'caseType': incident.type ?? '',
                    'reportedDate': incident.reportedDate ?? '',
                  },
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  TextHelper.viewTaskDetails,
                  style: const TextStyle(
                    color: brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: brandGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildViewTaskItem(TaskDetails task) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Opacity(
      opacity: 0.6,
      child: Text(
        task.taskName,
        style: const TextStyle(
          color: Color(0xFF2C2C2E),
          fontSize: 12,
        ),
      ),
    ),
  );
}

Widget _buildEditTaskItem(
  BuildContext context,
  TaskDetails task,
  int index,
  void Function(int) toggleTask,
  bool isTaskEditing,
  bool Function(String taskId, String roleId)? canAssignTask,
  String currentRoleId,
) {
  final bool isTaskChecked = task.isAssigned || task.status != 'Pending';
  final bool canAssign =
      canAssignTask?.call(task.taskId, currentRoleId) ?? true;
  final bool isTaskDisabled = !canAssign && !isTaskChecked;
  final bool isCheckboxEnabled = isTaskEditing && !isTaskDisabled;

  return InkWell(
    onTap: isCheckboxEnabled ? () => toggleTask(index) : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Opacity(
        opacity: 0.6,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isTaskChecked ? brandGreen : Colors.transparent,
                border: Border.all(
                  color: isTaskChecked
                      ? brandGreen
                      : (isTaskDisabled || !isTaskEditing
                            ? Colors.grey
                            : errorRed),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isTaskChecked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.taskName,
                style: TextStyle(
                  color: isTaskDisabled ? Colors.grey : const Color(0xFF2C2C2E),
                  fontSize: 12,
                  decoration:
                      isTaskDisabled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
