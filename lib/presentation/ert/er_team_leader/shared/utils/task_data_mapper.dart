import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/model/ui_task_model.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart' as api;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for mapping raw task/incident data to UI and API models.
/// Keeps screens focused on UI only.
class TaskDataMapper {
  /// Extract tasks belonging to a specific user from incident task data.
  static List<Map<String, dynamic>> extractUserTasks(
    List<dynamic>? tasks,
    String? filterUserId,
  ) {
    final userTasks = <Map<String, dynamic>>[];
    if (tasks == null || tasks.isEmpty) return userTasks;

    for (final taskItem in tasks) {
      if (taskItem is Map<String, dynamic>) {
        final taskUserId =
            taskItem['userId']?.toString() ??
            taskItem['user']?['_id']?.toString() ??
            '';

        final isSelectedUser =
            filterUserId == null ||
            filterUserId.isEmpty ||
            taskUserId == filterUserId;

        if (isSelectedUser) {
          if (taskItem.containsKey('tasks') && taskItem['tasks'] is List) {
            final tasksList = taskItem['tasks'] as List;
            for (final task in tasksList) {
              if (task is Map<String, dynamic>) {
                final mergedTask = Map<String, dynamic>.from(task);
                mergedTask['user'] = taskItem['user'];
                mergedTask['userId'] = taskUserId;

                if (task.containsKey('task') && task['task'] is Map) {
                  final nestedTask = task['task'] as Map<String, dynamic>;
                  mergedTask.addAll(nestedTask);
                }

                userTasks.add(mergedTask);
              }
            }
          } else if (taskItem.containsKey('task')) {
            final taskData = Map<String, dynamic>.from(taskItem);

            if (taskItem['task'] is Map<String, dynamic>) {
              final nestedTask = taskItem['task'] as Map<String, dynamic>;
              taskData.addAll(nestedTask);
            }

            taskData['userId'] = taskUserId;
            userTasks.add(taskData);
          }
        }
      }
    }
    return userTasks;
  }

  /// Extract case description from incident's emergexCaseSummary.
  static String extractCaseDescription(dynamic incident) {
    final summaryData = incident.emergexCaseSummary;

    if (summaryData is Map<String, dynamic>) {
      final summary = summaryData['summary'];

      if (summary is List) {
        return summary.join(', ');
      }

      if (summary is String && summary.isNotEmpty) {
        return summary;
      }
    }

    return 'No description available';
  }

  /// Map raw task data (Map) to a [UiTaskModel] for display in task cards.
  static UiTaskModel mapToUiTask(Map<String, dynamic> task) {
    String timer = '00:00:00';
    Color timerColor = ColorHelper.black4;
    final startedAtStr = task['startedAt']?.toString();
    final completedAtStr = task['completedAt']?.toString();
    final pausedAtStr = task['pausedAt']?.toString();
    final timeTaken = task['timeTaken']?.toString();
    final totalPausedTime = task['totalPausedTime'] as int?;

    DateTime? startedAt;
    DateTime? completedAt;
    DateTime? pausedAt;

    if (startedAtStr != null && startedAtStr.isNotEmpty) {
      try {
        startedAt = DateTime.parse(startedAtStr);
      } catch (_) {}
    }
    if (completedAtStr != null && completedAtStr.isNotEmpty) {
      try {
        completedAt = DateTime.parse(completedAtStr);
      } catch (_) {}
    }
    if (pausedAtStr != null && pausedAtStr.isNotEmpty) {
      try {
        pausedAt = DateTime.parse(pausedAtStr);
      } catch (_) {}
    }

    if (timeTaken != null && timeTaken.isNotEmpty) {
      timer = DateTimeFormatter.formatTimeTakenAsDuration(timeTaken);
    } else {
      timer = DateTimeFormatter.formatTaskDuration(
        startedAt: startedAt,
        pausedAt: pausedAt,
        completedAt: completedAt,
        totalPausedTime: totalPausedTime,
        status: task['status']?.toString(),
      );
    }

    String status = 'Pending';
    Color statusColor = ColorHelper.black;

    final taskStatus = task['status']?.toString();
    if (taskStatus != null) {
      status = taskStatus;
      if (status.toLowerCase() == 'completed' ||
          status.toLowerCase() == 'done') {
        status = 'Completed';
        statusColor = ColorHelper.successColor;
      } else if (status.toLowerCase() == 'in progress' ||
          status.toLowerCase() == 'inprogress') {
        status = 'In Progress';
        statusColor = ColorHelper.erteamleaderprogress;
      } else if (status.toLowerCase() == 'draft') {
        status = 'Draft';
        statusColor = ColorHelper.black4;
      }
    }

    String date = '';
    final createdAtStr = task['createdAt']?.toString();
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        final createdAt = DateTime.parse(createdAtStr);
        date = DateFormat('dd/MM/yyyy').format(createdAt);
      } catch (_) {}
    }

    String? formattedStartedAt;
    if (startedAt != null) {
      formattedStartedAt = DateFormat('dd/MM/yyyy HH:mm').format(startedAt);
    }

    return UiTaskModel(
      title: task['taskName']?.toString() ?? 'Task',
      code: task['taskId']?.toString() ?? '',
      date: date,
      description: task['taskDetails']?.toString() ?? '',
      timer: timer,
      status: status,
      statusColor: statusColor,
      timerColor: timerColor,
      startedAt: formattedStartedAt,
      startedAtDateTime: startedAt,
      pausedAtDateTime: pausedAt,
      completedAtDateTime: completedAt,
      totalPausedTime: totalPausedTime,
      statusBg: ColorHelper.transparent,
    );
  }

  /// Map raw task data (Map) to an [api.Task] model for API/navigation.
  static api.Task mapToApiTask(
    Map<String, dynamic> taskData,
    String projectId,
  ) {
    final attachments = <api.Attachment>[];
    if (taskData['attachments'] is List) {
      final attList = taskData['attachments'] as List;
      for (final att in attList) {
        if (att is Map<String, dynamic>) {
          attachments.add(
            api.Attachment(
              id: att['_id']?.toString(),
              fileUrl: att['fileUrl']?.toString() ?? '',
              fileName: att['fileName']?.toString() ?? '',
              key: att['key']?.toString() ?? '',
            ),
          );
        }
      }
    }

    DateTime? createdAt;
    DateTime? updatedAt;
    DateTime? startedAt;
    DateTime? completedAt;

    if (taskData['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(taskData['createdAt'].toString());
      } catch (_) {}
    }
    if (taskData['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(taskData['updatedAt'].toString());
      } catch (_) {}
    }
    if (taskData['startedAt'] != null) {
      try {
        startedAt = DateTime.parse(taskData['startedAt'].toString());
      } catch (_) {}
    }
    if (taskData['completedAt'] != null) {
      try {
        completedAt = DateTime.parse(taskData['completedAt'].toString());
      } catch (_) {}
    }

    api.AiAnalysis? aiAnalysis;
    if (taskData['aiAnalysis'] is Map<String, dynamic>) {
      final aiData = taskData['aiAnalysis'] as Map<String, dynamic>;
      aiAnalysis = api.AiAnalysis(
        aiSummary: aiData['aiSummary']?.toString() ?? '',
        delayRiskDetected: aiData['delayRiskDetected']?.toString() ?? '',
        aiRecommendations: aiData['aiRecommendations']?.toString() ?? '',
      );
    }

    return api.Task(
      id: taskData['_id']?.toString(),
      taskId: taskData['taskId']?.toString() ?? '',
      projectId: projectId,
      taskName: taskData['taskName']?.toString() ?? '',
      taskDetails: taskData['taskDetails']?.toString() ?? '',
      attachments: attachments,
      isDeleted: taskData['isDeleted'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: taskData['status']?.toString(),
      statusUpdate: taskData['statusUpdate']?.toString(),
      completedBy: taskData['completedBy']?.toString(),
      startedAt: startedAt,
      completedAt: completedAt,
      timeTaken: taskData['timeTaken']?.toString(),
      aiAnalysis: aiAnalysis,
    );
  }
}
