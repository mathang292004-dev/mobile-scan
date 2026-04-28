import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/screens/task_details_screen.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/screen/team_leader_task_overview/emerge_x_section_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/screen/team_leader_task_overview/department_section_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/screen/team_leader_task_overview/user_section_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/widgets/task_card_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/task_data_mapper.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/base/cubit/emergex_app_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:go_router/go_router.dart';

class OverviewScreen extends StatelessWidget {
  final String? incidentId;
  final String? userId;

  const OverviewScreen({super.key, this.incidentId, this.userId});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (incidentId != null && incidentId!.isNotEmpty) {
        AppDI.incidentDetailsCubit.getIncidentById(incidentId!);
      }
    });

    return BlocProvider.value(
      value: AppDI.incidentDetailsCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        showBottomNav: false,
        appBar: const AppBarWidget(hasNotifications: false),
        child: BlocConsumer<IncidentDetailsCubit, IncidentDetailsState>(
          listener: (context, state) {
            if (state is IncidentDetailsLoaded && state.errorMessage != null) {
              showSnackBar(context, state.errorMessage!, isSuccess: false);
            }
          },
          builder: (context, state) {
            if (state is IncidentDetailsInitial ||
                (state is IncidentDetailsLoading)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is IncidentDetailsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (incidentId != null && incidentId!.isNotEmpty) {
                          AppDI.incidentDetailsCubit.getIncidentById(
                            incidentId!,
                          );
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is! IncidentDetailsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final incident = state.incident;

            // Filter tasks by userId if provided
            final userTasks = TaskDataMapper.extractUserTasks(incident.task, userId);

            // Get user info
            String userName = 'User';
            String resolvedUserId = userId ?? '';

            if (userTasks.isNotEmpty &&
                userId != null &&
                userId!.isNotEmpty) {
              final firstTask = userTasks.first;
              final user = firstTask['user'] as Map<String, dynamic>?;
              if (user != null) {
                userName = user['name']?.toString() ?? 'User';
              }
            } else {
              final userProfile = context.read<EmergexAppCubit>().state.profile;
              userName = userProfile?.userName ?? 'User';
              resolvedUserId = userProfile?.id ?? '';
            }

            // Calculate task progress
            final completedTasks = userTasks.where((t) {
              final status = t['status']?.toString().toLowerCase();
              return status == 'completed' || status == 'verified';
            }).length;
            final totalTasks = userTasks.length;
            final progressText = totalTasks > 0
                ? '$completedTasks/$totalTasks Complete'
                : '0/0 Complete';
            final progressValue = totalTasks > 0
                ? completedTasks / totalTasks
                : 0.0;

            // Get incident details
            final department = incident.department ?? 'ER Team';
            final reportedDate = incident.reportedDate ?? '-';
            final location = incident.branch ?? incident.country ?? '-';
            final caseDescription = TaskDataMapper.extractCaseDescription(incident);

            // Map tasks to UI tasks
            final uiTasks = userTasks.map(TaskDataMapper.mapToUiTask).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              decoration: BoxDecoration(
                                color: ColorHelper.white.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorHelper.white,
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: ColorHelper.black,
                                  size: 18,
                                ),
                                onPressed: () => back(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                TextHelper.teamMemberTaskOverVIew,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: 16,
                                      color: ColorHelper.organizationStructure,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (incidentId == null || incidentId!.isEmpty) return;
                          context.pushNamed(
                            Routes.chatScreen,
                            queryParameters: {'incidentId': incidentId!},
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                ColorHelper.primaryColor,
                                ColorHelper.buttonColor,
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ColorHelper.primaryColor,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              Assets.chat,
                              width: 22,
                              height: 22,
                              color: ColorHelper.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ColorHelper.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: ColorHelper.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              UserSectionWidget(
                                userName: userName,
                                userId: resolvedUserId,
                                progressText: progressText,
                                progressValue: progressValue,
                              ),
                              const SizedBox(height: 10),
                              DepartmentSectionWidget(
                                department: department,
                                assignedDate: reportedDate,
                                location: location,
                                totalTasks: totalTasks,
                              ),
                            ],
                          ),
                        ),
                        EmergeXSectionWidget(description: caseDescription),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          child: Text(
                            'Tasks List',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ColorHelper.black,
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (uiTasks.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'No tasks available',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: ColorHelper.black4),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            itemCount: uiTasks.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final rawTaskData = userTasks[index];
                              final apiTask = TaskDataMapper.mapToApiTask(
                                rawTaskData,
                                incident.projectId ?? '',
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ErTeamLeaderTaskDetailsScreen(
                                              task: apiTask,
                                              incidentId: incident.incidentId,
                                              isReadOnly: true,
                                            ),
                                      ),
                                    );
                                  },
                                  child: TaskCardWidget(task: uiTasks[index]),
                                ),
                              );
                            },
                          ),
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
