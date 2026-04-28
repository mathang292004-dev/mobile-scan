import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/presentation/case_report/approver/model/emergency_card_model.dart';
import 'package:emergex/presentation/case_report/approver/widgets/emergency_response_gantt_chart.dart';

/// Maps the API incident response to UI card models for the emergency response view.
List<EmergencyResponseTeamTasks> mapIncidentToEmergencyData(
  IncidentDetails incident,
) {
  final List<EmergencyResponseTeamTasks> cards = [];
  final tasksList = incident.task ?? [];
  final String incidentId = incident.incidentId ?? '';
  final String incidentTitle = incident.title ?? '';

  for (final taskItem in tasksList) {
    if (taskItem is Map<String, dynamic>) {
      // Latest API structure: 'user' + 'tasks' array
      if (taskItem.containsKey('user') && taskItem.containsKey('tasks')) {
        _parseNewFormatWithTasksArray(
          taskItem,
          cards,
          incidentId,
          incidentTitle,
        );
      }
      // Previous API structure: 'user' + 'task' singular
      else if (taskItem.containsKey('user') && taskItem.containsKey('task')) {
        _parseNewFormatWithSingleTask(
          taskItem,
          cards,
          incidentId,
          incidentTitle,
        );
      }
      // Old structure: 'taskList'
      else if (taskItem.containsKey('taskList')) {
        _parseOldFormat(taskItem, cards, incidentId, incidentTitle);
      }
    }
  }

  return cards;
}

void _parseNewFormatWithTasksArray(
  Map<String, dynamic> taskItem,
  List<EmergencyResponseTeamTasks> cards,
  String incidentId,
  String incidentTitle,
) {
  final user = taskItem['user'] as Map<String, dynamic>?;
  final tasks = taskItem['tasks'] as List<dynamic>? ?? [];

  if (user == null) return;

  final userId =
      taskItem['userId']?.toString() ??
      user['_id']?.toString() ??
      user['userId']?.toString() ??
      '';
  final userName = user['name']?.toString() ?? '';
  final userEmail = user['email']?.toString() ?? '';
  final userProfile = user['profile']?.toString() ?? '';

  final List<TaskDetails> taskDetails = tasks
      .whereType<Map<String, dynamic>>()
      .map((task) {
        final taskStatus = task['status']?.toString();
        final completedAt = task['completedAt']?.toString();
        final startedAt = task['startedAt']?.toString();

        return TaskDetails(
          taskName: task['taskName']?.toString() ?? 'Task',
          status: deriveTaskStatusFromNewFormat(taskStatus, completedAt),
          taskId: task['taskId']?.toString() ?? '',
          isAssigned:
              taskStatus != null || completedAt != null || startedAt != null,
        );
      })
      .toList();

  cards.add(
    EmergencyResponseTeamTasks(
      userDetails: UserDetails(
        userName: userName,
        userRole: userEmail,
        roleId: userId,
        taskStatus: calculateUserStatus(taskDetails),
        avatarUrl: userProfile,
      ),
      incidentID: incidentId,
      incident: incidentTitle,
      taskDetails: taskDetails,
      uploadedFiles: const [],
    ),
  );
}

void _parseNewFormatWithSingleTask(
  Map<String, dynamic> taskItem,
  List<EmergencyResponseTeamTasks> cards,
  String incidentId,
  String incidentTitle,
) {
  final user = taskItem['user'] as Map<String, dynamic>?;
  final task = taskItem['task'] as Map<String, dynamic>?;

  if (user == null || task == null) return;

  final userId = user['_id']?.toString() ?? '';
  final userName = user['name']?.toString() ?? '';
  final userEmail = user['email']?.toString() ?? '';
  final userProfile = user['profile']?.toString() ?? '';
  final taskStatus = taskItem['status']?.toString();
  final completedAt = taskItem['completedAt']?.toString();

  final taskDetails = [
    TaskDetails(
      taskName: task['taskName']?.toString() ?? 'Task',
      status: deriveTaskStatusFromNewFormat(taskStatus, completedAt),
      taskId: task['taskId']?.toString() ?? '',
      isAssigned: taskStatus != null || completedAt != null,
    ),
  ];

  cards.add(
    EmergencyResponseTeamTasks(
      userDetails: UserDetails(
        userName: userName,
        userRole: userEmail,
        roleId: userId,
        taskStatus: calculateUserStatus(taskDetails),
        avatarUrl: userProfile,
      ),
      incidentID: incidentId,
      incident: incidentTitle,
      taskDetails: taskDetails,
      uploadedFiles: const [],
    ),
  );
}

void _parseOldFormat(
  Map<String, dynamic> taskItem,
  List<EmergencyResponseTeamTasks> cards,
  String incidentId,
  String incidentTitle,
) {
  final List<dynamic> teamMembers =
      taskItem['taskList'] as List<dynamic>? ?? [];

  for (final member in teamMembers) {
    if (member is Map<String, dynamic>) {
      final String name = member['name']?.toString() ?? '';
      final String roleName = member['roleName']?.toString() ?? '';
      final String roleId = member['roleId']?.toString() ?? '';

      final List<dynamic> memberTasks =
          member['task'] as List<dynamic>? ?? [];
      final List<TaskDetails> taskDetails = memberTasks
          .whereType<Map<String, dynamic>>()
          .map(
            (t) => TaskDetails(
              taskName:
                  t['short']?.toString() ??
                  t['long']?.toString() ??
                  'Task',
              status: deriveTaskStatus(t),
              taskId: t['taskId']?.toString() ?? '',
              isAssigned:
                  t['assigned'] == true ||
                  t['assigned']?.toString().toLowerCase() == 'true',
            ),
          )
          .toList();

      cards.add(
        EmergencyResponseTeamTasks(
          userDetails: UserDetails(
            userName: name,
            userRole: roleName,
            roleId: roleId,
            taskStatus: calculateUserStatus(taskDetails),
            avatarUrl: '',
          ),
          incidentID: incidentId,
          incident: incidentTitle,
          taskDetails: taskDetails,
          uploadedFiles: const [],
        ),
      );
    }
  }
}

/// Returns the ERT team leader card for the approver view.
EmergencyResponseTeamTasks? getErtTlCard(IncidentDetails incident) {
  return _getTlCard(incident, 'ert');
}

/// Returns the Investigation team leader card for the approver view.
EmergencyResponseTeamTasks? getInvestigationTlCard(IncidentDetails incident) {
  return _getTlCard(incident, 'investigation');
}

EmergencyResponseTeamTasks? _getTlCard(IncidentDetails incident, String flow) {
  final tasksList = incident.task ?? [];

  // Find the specific entry that belongs to this flow AND has role == 'tl'.
  // A user can appear in multiple flows (e.g. ERT member AND investigation TL),
  // so matching by userId alone would return the wrong entry.
  Map<String, dynamic>? tlEntry;
  for (final t in tasksList.whereType<Map<String, dynamic>>()) {
    if (t['flow'] == flow && t['role'] == 'tl') {
      tlEntry = t;
      break;
    }
  }
  if (tlEntry == null) return null;

  // Build a single card directly from this entry to avoid cross-flow collision.
  final cards = <EmergencyResponseTeamTasks>[];
  _parseNewFormatWithTasksArray(
    tlEntry,
    cards,
    incident.incidentId ?? '',
    incident.title ?? '',
  );
  return cards.isNotEmpty ? cards.first : null;
}

/// ERT team leader view: only ERT flow members (role == 'member', excludes TL).
List<EmergencyResponseTeamTasks> mapIncidentToEmergencyDataErt(
  IncidentDetails incident,
) {
  final all = mapIncidentToEmergencyData(incident);
  final tasksList = incident.task ?? [];
  final ertUserIds = <String>{};
  for (final t in tasksList.whereType<Map<String, dynamic>>()) {
    if (t['flow'] == 'ert' && t['role'] == 'member') {
      final userId =
          t['userId']?.toString() ??
          (t['user'] is Map ? t['user']['_id']?.toString() : null) ??
          '';
      if (userId.isNotEmpty) ertUserIds.add(userId);
    }
  }
  if (ertUserIds.isEmpty) return all;
  return all.where((card) => ertUserIds.contains(card.userDetails.roleId)).toList();
}

/// Approver view: only the ERT team leader entry.
List<EmergencyResponseTeamTasks> mapIncidentToEmergencyDataApprover(
  IncidentDetails incident,
) {
  final all = mapIncidentToEmergencyData(incident);
  final tasksList = incident.task ?? [];
  final ertTlIds = <String>{};
  for (final t in tasksList.whereType<Map<String, dynamic>>()) {
    if (t['flow'] == 'ert' && t['role'] == 'tl') {
      final userId = t['userId']?.toString() ?? '';
      if (userId.isNotEmpty) ertTlIds.add(userId);
    }
  }
  return all.where((card) => ertTlIds.contains(card.userDetails.roleId)).toList();
}

/// Maps incident tasks to Gantt chart models.
List<GanttTask> mapIncidentToGanttTasks(IncidentDetails incident) {
  final ganttTasks = <GanttTask>[];
  final tasksList = incident.task ?? [];
  final now = DateTime.now().toUtc();

  for (final taskItem in tasksList.whereType<Map<String, dynamic>>()) {
    // Latest API structure: 'user' + 'tasks' array
    if (taskItem.containsKey('user') && taskItem.containsKey('tasks')) {
      _parseGanttNewFormatArray(taskItem, ganttTasks, now);
    }
    // Previous API structure: 'user' + 'task' singular
    else if (taskItem.containsKey('user') && taskItem.containsKey('task')) {
      _parseGanttNewFormatSingle(taskItem, ganttTasks, now);
    }
    // Old structure: 'taskList'
    else if (taskItem.containsKey('taskList')) {
      _parseGanttOldFormat(taskItem, ganttTasks, now);
    }
  }

  return ganttTasks;
}

void _parseGanttNewFormatArray(
  Map<String, dynamic> taskItem,
  List<GanttTask> ganttTasks,
  DateTime now,
) {
  final user = taskItem['user'] as Map<String, dynamic>?;
  final tasks = taskItem['tasks'] as List<dynamic>? ?? [];

  if (user == null) return;

  final assignee = user['name']?.toString() ?? 'Member';
  final assigneeImageUrl = user['profile']?.toString() ?? '';

  for (final task in tasks.whereType<Map<String, dynamic>>()) {
    final taskName = task['taskName']?.toString() ?? 'Task';
    final taskId = task['taskId']?.toString() ?? '';
    final startedAt = task['startedAt']?.toString();
    final completedAt = task['completedAt']?.toString();
    final status = task['status']?.toString();

    var start = parseDateTime(startedAt) ?? now;
    var end =
        parseDateTime(completedAt) ??
        (status != null
            ? now.add(const Duration(hours: 2))
            : start.add(const Duration(hours: 1)));

    if (!end.isAfter(start)) {
      end = start.add(const Duration(minutes: 30));
    }

    final taskStatus = completedAt != null && completedAt.isNotEmpty
        ? TaskStatus.completed
        : (status != null ? TaskStatus.inProgress : TaskStatus.delay);

    ganttTasks.add(
      GanttTask(
        id: '$taskId$assignee',
        label: taskName,
        dateStart: start,
        dateEnd: end,
        status: taskStatus,
        assigneeName: assignee,
        assigneeImageUrl: assigneeImageUrl,
        isAssigned: status != null || completedAt != null,
      ),
    );
  }
}

void _parseGanttNewFormatSingle(
  Map<String, dynamic> taskItem,
  List<GanttTask> ganttTasks,
  DateTime now,
) {
  final user = taskItem['user'] as Map<String, dynamic>?;
  final task = taskItem['task'] as Map<String, dynamic>?;

  if (user == null || task == null) return;

  final assignee = user['name']?.toString() ?? 'Member';
  final taskName = task['taskName']?.toString() ?? 'Task';
  final taskId = task['taskId']?.toString() ?? '';
  final startedAt = taskItem['startedAt']?.toString();
  final completedAt = taskItem['completedAt']?.toString();
  final status = taskItem['status']?.toString();

  var start = parseDateTime(startedAt) ?? now;
  var end =
      parseDateTime(completedAt) ??
      (status != null
          ? now.add(const Duration(hours: 2))
          : start.add(const Duration(hours: 1)));

  if (!end.isAfter(start)) {
    end = start.add(const Duration(minutes: 30));
  }

  final taskStatus = completedAt != null && completedAt.isNotEmpty
      ? TaskStatus.completed
      : (status != null ? TaskStatus.inProgress : TaskStatus.delay);

  ganttTasks.add(
    GanttTask(
      id: '$taskId$assignee',
      label: taskName,
      dateStart: start,
      dateEnd: end,
      status: taskStatus,
      assigneeName: assignee,
      assigneeImageUrl: user['profile']?.toString() ?? '',
      isAssigned: status != null || completedAt != null,
    ),
  );
}

void _parseGanttOldFormat(
  Map<String, dynamic> taskItem,
  List<GanttTask> ganttTasks,
  DateTime now,
) {
  final teamMembers = taskItem['taskList'] as List<dynamic>? ?? [];

  for (final member in teamMembers.whereType<Map<String, dynamic>>()) {
    final assignee = member['name']?.toString() ?? 'Member';
    final memberTasks = member['task'] as List<dynamic>? ?? [];

    for (final t in memberTasks.whereType<Map<String, dynamic>>()) {
      final label = t['short']?.toString().trim().isNotEmpty == true
          ? t['short'].toString()
          : (t['long']?.toString() ?? 'Task');

      final assigned =
          t['assigned'] == true ||
          t['assigned']?.toString().toLowerCase() == 'true';

      var start = parseDateTime(t['start']) ?? now;
      var end =
          parseDateTime(t['end']) ??
          (assigned
              ? now.add(const Duration(hours: 2))
              : start.add(const Duration(hours: 1)));

      if (!end.isAfter(start)) {
        end = start.add(const Duration(minutes: 30));
      }

      final status = t['end']?.toString().isNotEmpty == true
          ? TaskStatus.completed
          : (assigned ? TaskStatus.inProgress : TaskStatus.delay);

      ganttTasks.add(
        GanttTask(
          id: '${t['taskId'] ?? ''}$assignee',
          label: label,
          dateStart: start,
          dateEnd: end,
          status: status,
          assigneeName: assignee,
          assigneeImageUrl: '',
          isAssigned: assigned,
        ),
      );
    }
  }
}

/// Calculates task assignment counts across all emergency response team members.
Map<String, int> calculateTaskCounts(IncidentDetails incident) {
  final taskCounts = <String, int>{};
  for (var team in mapIncidentToEmergencyData(incident)) {
    for (var task in team.taskDetails) {
      if (task.status == 'Completed' || task.status == 'Inprogress') {
        taskCounts[task.taskId] = (taskCounts[task.taskId] ?? 0) + 1;
      }
    }
  }
  return taskCounts;
}

/// Derives task status from the old API format.
String deriveTaskStatus(Map<String, dynamic> task) {
  final end = task['end']?.toString() ?? '';
  final backendStatus = task['status']?.toString() ?? '';
  final assigned =
      task['assigned'] == true ||
      task['assigned']?.toString().toLowerCase() == 'true';

  if (end.isNotEmpty) return 'Completed';
  if (backendStatus.isNotEmpty) return backendStatus;
  return assigned ? 'Inprogress' : 'Pending';
}

/// Derives task status from the new API format.
String deriveTaskStatusFromNewFormat(String? status, String? completedAt) {
  if (completedAt != null && completedAt.isNotEmpty) return 'Completed';
  if (status != null && status.isNotEmpty) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'completed' || lowerStatus == 'done') return 'Completed';
    if (lowerStatus == 'inprogress' || lowerStatus == 'in progress') {
      return 'Inprogress';
    }
    if (lowerStatus == 'draft' || lowerStatus == 'pending') return 'Pending';
    return status;
  }
  return 'Pending';
}

/// Calculates the overall user status based on their task statuses.
String calculateUserStatus(List<TaskDetails> taskDetails) {
  if (taskDetails.isEmpty) return 'Pending';
  if (taskDetails.any((task) => task.status == 'Inprogress')) {
    return 'Inprogress';
  }
  if (taskDetails.every((task) => task.status == 'Completed')) {
    return 'Completed';
  }
  return 'Pending';
}

/// Parses a date-time string, returning `null` on failure.
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString()).toUtc();
  } catch (_) {
    return null;
  }
}
