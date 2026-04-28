import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/task_status_helper.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/model/ui_task_model.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:flutter/material.dart';

/// Shared task card widget used across all ERT roles (leader, member, approver).
/// Accepts a pre-mapped [UiTaskModel] so rendering stays pure UI.
class TaskCardWidget extends StatelessWidget {
  final UiTaskModel task;

  const TaskCardWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ColorHelper.white, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorHelper.black5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  task.code,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: ColorHelper.black4),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  task.date,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: ColorHelper.textPrimary),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorHelper.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.description,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ColorHelper.black5),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimerWidget(context),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: task.statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: task.statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget(BuildContext context) {
    // Live timer only when task is actively in progress
    if (TaskStatusHelper.isInProgress(task.status) &&
        task.startedAtDateTime != null) {
      final initialDuration = DateTimeFormatter.calculateTaskDuration(
        startedAt: task.startedAtDateTime,
        pausedAt: task.pausedAtDateTime,
        completedAt: task.completedAtDateTime,
        totalPausedTime: task.totalPausedTime,
        status: task.status,
      );
      return TimerWidget(
        key: ValueKey('timer_${task.code}'),
        startDuration: initialDuration,
        timerColor: task.timerColor,
        shouldRun: true,
        iconAsset: Assets.tasktime,
        iconSize: 12,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        borderRadius: 20,
        borderWidth: 1,
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: task.timerColor,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    // All other statuses (final, paused, draft, not started) show static time
    return _buildStaticTimer(context, task.timer, task.timerColor);
  }

  Widget _buildStaticTimer(BuildContext context, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Image.asset(Assets.tasktime, width: 12, height: 12, color: color),
          const SizedBox(width: 6),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
