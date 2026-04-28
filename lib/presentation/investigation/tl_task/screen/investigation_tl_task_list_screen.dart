import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/investigation/tl_task/cubit/investigation_tl_task_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvestigationTlTaskListScreen extends StatelessWidget {
  final String incidentId;
  final String incidentType;

  const InvestigationTlTaskListScreen({
    super.key,
    required this.incidentId,
    this.incidentType = 'Incident',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.investigationTlTaskCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: BlocBuilder<InvestigationTlTaskCubit, InvestigationTlTaskState>(
          builder: (context, state) {
            final tasks = state.tasks;
            final completedCount =
                tasks.where((t) => t.status == 'Completed').length;

            return Column(
              children: [
                // Header row with back button, case ID, chat icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => back(),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: ColorHelper.white.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                            border: Border.all(color: ColorHelper.white),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: ColorHelper.black,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'EmergeX Case $incidentId',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Chat icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ColorHelper.primaryColor,
                              ColorHelper.buttonColor,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: ColorHelper.primaryColor),
                        ),
                        child: Image.asset(
                          Assets.chat,
                          width: 18,
                          height: 18,
                          color: ColorHelper.white,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: ColorHelper.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Pills: Duration + Incident type
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: ColorHelper.primaryColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: ColorHelper.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${TextHelper.caseDuration} — 04:43:12',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorHelper.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                              color: ColorHelper.primaryColor.withValues(
                                  alpha: 0.3)),
                        ),
                        child: Text(
                          incidentType,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColorHelper.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Select Task List header + Filter
                        Row(
                          children: [
                            Text(
                              TextHelper.selectTaskList,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ColorHelper.primaryColor,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    size: 14,
                                    color: ColorHelper.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    TextHelper.filter,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: ColorHelper.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress card
                        AppContainer(
                          radius: 20,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${TextHelper.totalTaskCompleted} — $completedCount/${tasks.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9999),
                                child: LinearProgressIndicator(
                                  value: tasks.isEmpty
                                      ? 0
                                      : completedCount / tasks.length,
                                  minHeight: 8,
                                  backgroundColor: ColorHelper.textSecondary
                                      .withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          ColorHelper.primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Task cards
                        if (tasks.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: ColorHelper.primaryColor,
                              ),
                            ),
                          )
                        else
                          ...tasks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final task = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: index < tasks.length - 1 ? 12 : 0),
                              child: _TaskListCard(
                                task: task,
                                onTap: () {
                                  openScreen(
                                    Routes.investigationTlTaskDetailScreen,
                                    args: {'taskId': task.taskId},
                                  );
                                },
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TaskListCard extends StatelessWidget {
  final TlInvestigationTask task;
  final VoidCallback? onTap;

  const _TaskListCard({required this.task, this.onTap});

  Color _statusColor() {
    switch (task.status.toLowerCase()) {
      case 'completed':
        return ColorHelper.successColor;
      case 'in progress':
        return ColorHelper.primaryColor;
      case 'paused':
        return ColorHelper.warningColor;
      default:
        return ColorHelper.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    return GestureDetector(
      onTap: onTap,
      child: AppContainer(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              task.taskName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),

            // Case ref + date row
            Row(
              children: [
                Text(
                  task.taskId,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                Text(
                  '29/07/2020',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorHelper.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: ColorHelper.white.withValues(alpha: 0.6)),
              ),
              child: Text(
                task.taskDetails,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.textSecondary,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),

            // Timer + Status row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                        color: ColorHelper.textSecondary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: ColorHelper.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.timeTaken,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColorHelper.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    task.status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
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
