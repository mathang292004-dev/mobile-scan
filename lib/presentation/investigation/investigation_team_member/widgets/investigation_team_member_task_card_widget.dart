import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/cubit/investigation_team_member_cubit.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart';
import 'package:emergex/helpers/task_status_helper.dart';
import 'package:flutter/material.dart';

class InvestigationTeamMemberTaskCardWidget extends StatelessWidget {
  final InvestigationMemberTask task;

  const InvestigationTeamMemberTaskCardWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorHelper.white, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ColorHelper.black5,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            task.code,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ColorHelper.black4,
                                  fontSize: 12,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.date,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ColorHelper.black,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorHelper.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColorHelper.black,
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimerWidget(context),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBackgroundColor(task.status),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: ColorHelper.white.withValues(alpha: 0.41),
                      blurRadius: 13.5,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Text(
                  task.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusTextColor(task.status),
                    fontSize: 12,
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

  Color _getTimeBadgeBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return const Color(0xFF005B8B);
      case 'paused':
        return ColorHelper.black;
      case 'completed':
        return const Color(0xFF3DA229);
      case 'rejected':
        return const Color(0xFFFF3C56);
      default:
        return const Color(0xFF005B8B);
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return const Color(0xFFD3EBFF);
      case 'paused':
        return const Color(0xFFFFFCA8);
      case 'completed':
        return const Color(0xFFD7FFD3);
      case 'rejected':
        return const Color(0xFFFFB5A8);
      default:
        return const Color(0xFFD3EBFF);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return const Color(0xFF293DA2);
      case 'paused':
        return const Color(0xFFA27429);
      case 'completed':
        return const Color(0xFF41A229);
      case 'rejected':
        return const Color(0xFFA22929);
      default:
        return const Color(0xFF293DA2);
    }
  }

  Widget _buildTimerWidget(BuildContext context) {
    final timerColor = _getTimeBadgeBorderColor(task.status);
    if (TaskStatusHelper.isFinalState(task.status)) {
      final formattedTime = DateTimeFormatter.formatTaskDuration(
        startedAt: task.startedAt,
        pausedAt: task.pausedAt,
        completedAt: task.completedAt,
        totalPausedTime: task.totalPausedTime,
        status: task.status,
      );
      return _buildStaticTimer(context, formattedTime, timerColor);
    }

    if (TaskStatusHelper.isPaused(task.status)) {
      final formattedTime = DateTimeFormatter.formatTaskDuration(
        startedAt: task.startedAt,
        pausedAt: task.pausedAt,
        completedAt: task.completedAt,
        totalPausedTime: task.totalPausedTime,
        status: task.status,
      );
      return _buildStaticTimer(context, formattedTime, timerColor);
    }

    if (TaskStatusHelper.isInProgress(task.status) && task.startedAt != null) {
      final initialDuration = DateTimeFormatter.calculateTaskDuration(
        startedAt: task.startedAt,
        pausedAt: task.pausedAt,
        completedAt: task.completedAt,
        totalPausedTime: task.totalPausedTime,
        status: task.status,
      );

      return TimerWidget(
        key: ValueKey('timer_${task.taskId}'),
        startDuration: initialDuration,
        timerColor: timerColor,
        shouldRun: true,
        iconAsset: Assets.tasktime,
        iconSize: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        borderRadius: 24,
        borderWidth: 1,
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: timerColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return _buildStaticTimer(context, '00:00:00', timerColor);
  }

  Widget _buildStaticTimer(BuildContext context, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Assets.tasktime, width: 10, height: 10, color: color),
          const SizedBox(width: 5),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
