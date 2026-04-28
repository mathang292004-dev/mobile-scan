import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/widgets/investigation_team_member_task_card_widget.dart';
import 'package:emergex/presentation/investigation/investigation_team_member/cubit/investigation_team_member_cubit.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:emergex/data/model/investigation/member_incident_timer.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/generated/assets.dart';

class InvestigationTeamMemberTasksScreen extends StatefulWidget {
  final String incidentId;

  const InvestigationTeamMemberTasksScreen({
    super.key,
    required this.incidentId,
  });

  @override
  State<InvestigationTeamMemberTasksScreen> createState() =>
      _InvestigationTeamMemberTasksScreenState();
}

class _InvestigationTeamMemberTasksScreenState
    extends State<InvestigationTeamMemberTasksScreen> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.incidentId.isNotEmpty) {
        // AppDI not configured for investigation team member cubit yet. Assuming it's in the route tree or provided via DI.
        // We will mock this or provide it locally if not present in DI. Let's assume it's added to DI.
        // Wait, for safety, since we might read it from context if it's there.
        try {
          getIt<InvestigationTeamMemberCubit>().loadTasks(
            incidentId: widget.incidentId,
          );
        } catch (e) {}
      }
    });
    return BlocProvider.value(
      value: getIt<InvestigationTeamMemberCubit>(),
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: BlocBuilder<InvestigationTeamMemberCubit, InvestigationTeamMemberState>(
          builder: (context, state) {
            if (state.processState == ProcessState.error &&
                state.tasks == null) {
              return Center(
                child: Text(state.errorMessage ?? 'Failed to load tasks'),
              );
            }

            final tasks = state.tasks ?? [];
            final completedTasks = tasks
                .where((t) => t.status.toLowerCase() == 'completed')
                .length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: ColorHelper.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ColorHelper.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.arrow_back_ios_new,
                                        size: 16,
                                        color: ColorHelper.black,
                                      ),
                                      onPressed: () => openScreen(
                                        Routes.investigationTeamMemberDashboardScreen,
                                        clearOldStacks: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            widget.incidentId.isNotEmpty
                                                ? 'Incident #${widget.incidentId}'
                                                : 'Incident',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: ColorHelper.black,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildIncidentTimerWidget(
                                          context,
                                          state.incidentTimer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (PermissionHelper.hasFullAccessPermission(
                              moduleName: "ERT Team Member",
                              featureName: "ER Team Communication",
                            )) // TODO change permission check to Investigation
                              GestureDetector(
                                onTap: () {
                                  context.push(
                                    '${Routes.chatScreen}?incidentId=${widget.incidentId}',
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF3DA229),
                                        Color(0xFF147B00),
                                      ],
                                    ),
                                  ),
                                  child: Image.asset(
                                    Assets.chat,
                                    width: 18,
                                    height: 18,
                                    color: ColorHelper.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          TextHelper.selectTaskList,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ColorHelper.black5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ColorHelper.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: ColorHelper.white),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Task Completed',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$completedTasks/${tasks.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: 10,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCDCEC9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: tasks.isEmpty
                                        ? 0
                                        : completedTasks / tasks.length,
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3DA229),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (tasks.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => GestureDetector(
                          onTap: () {
                            openScreen(
                              Routes.investigationTeamMemberTaskDetailsScreen,
                              args: {
                                'taskId': tasks[index].taskId,
                                'incidentId': widget.incidentId,
                              },
                            );
                          },
                          child: InvestigationTeamMemberTaskCardWidget(
                            task: tasks[index],
                          ),
                        ),
                        childCount: tasks.length,
                      ),
                    ),
                  if (tasks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No tasks available')),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIncidentTimerWidget(
    BuildContext context,
    MemberIncidentTimer? timer,
  ) {
    const timerColor = Color(0xFF005B8B);

    if (timer == null || timer.startTime == null) {
      return _buildStaticIncidentTimer(context, '00:00:00', timerColor);
    }

    final timerValue = DateTimeFormatter.formatIncidentTimer(
      startTime: timer.startTime,
      endTime: timer.endTime,
      timeTaken: timer.timeTaken,
    );

    if (timerValue == null) {
      return _buildStaticIncidentTimer(context, 'N/A', timerColor);
    }

    if (DateTimeFormatter.isIncidentTimerActive(timer.endTime)) {
      try {
        final start = DateTime.parse(timer.startTime!).toLocal();
        final initialDuration = DateTime.now().difference(start);

        return TimerWidget(
          key: const ValueKey('incident_timer'),
          startDuration: initialDuration.isNegative
              ? Duration.zero
              : initialDuration,
          timerColor: timerColor,
          shouldRun: true,
          iconAsset: Assets.tasktime,
          iconSize: 8,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          borderRadius: 24,
          borderWidth: 1,
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: timerColor,
          ),
        );
      } catch (_) {
        return _buildStaticIncidentTimer(context, timerValue, timerColor);
      }
    }

    return _buildStaticIncidentTimer(context, timerValue, timerColor);
  }

  Widget _buildStaticIncidentTimer(
    BuildContext context,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(Assets.tasktime, width: 8, height: 8, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
