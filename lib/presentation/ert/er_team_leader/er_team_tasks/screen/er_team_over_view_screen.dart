import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/helpers/widgets/inputs/toggle_button.dart';
import 'package:emergex/presentation/case_report/approver/cubit/teams_tab_data_cubit.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_gantt_widget.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_teams.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_overview_details.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/ai_insights_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';

class ErTeamOverViewScreen extends StatefulWidget {
  final String? incidentId;

  const ErTeamOverViewScreen({super.key, this.incidentId});

  @override
  State<ErTeamOverViewScreen> createState() => _ErTeamOverViewScreenState();
}

class _ErTeamOverViewScreenState extends State<ErTeamOverViewScreen> {
  final _isGanttView = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.incidentId != null && widget.incidentId!.isNotEmpty) {
        AppDI.incidentDetailsCubit.getIncidentById(widget.incidentId!);
      }
    });
  }

  @override
  void dispose() {
    _isGanttView.dispose();
    super.dispose();
  }

  Widget _buildBottomActions(
    BuildContext context,
    dynamic incidentData,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: EmergexButton(
              text: TextHelper.cancel,
              onPressed: () => back(),
              colors: [ColorHelper.white, ColorHelper.white],
              textColor: ColorHelper.primaryColor,
              borderColor: ColorHelper.primaryColor,
              borderRadius: 8,
              buttonHeight: 48,
              textSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: EmergexButton(
              text: TextHelper.submitSetup,
              onPressed: () => _handleSubmitSetup(incidentData),
              colors: [ColorHelper.primaryColor, ColorHelper.buttonColor],
              textColor: ColorHelper.white,
              borderColor: ColorHelper.primaryColor,
              borderRadius: 8,
              buttonHeight: 48,
              textSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitSetup(dynamic incidentData) async {
    final incidentId = incidentData.incidentId ?? '';
    if (incidentId.isEmpty) return;

    final success = await AppDI.incidentDetailsCubit.submitSetup(
      incidentId,
      'ert',
    );
    if (success) {
      showSuccessDialog(
        null,
        () {
          AppDI.incidentDetailsCubit.getIncidentById(incidentId);
          back();
        },
        incidentId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.incidentDetailsCubit,
      child: BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
        builder: (context, state) {
          // Show loading state
          if (state is IncidentDetailsInitial) {
            return AppScaffold(
              useGradient: true,
              gradientBegin: Alignment.topCenter,
              gradientEnd: Alignment.bottomCenter,
              showDrawer: false,
              appBar: const AppBarWidget(hasNotifications: true),
              showBottomNav: false,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          // Show error state
          if (state is IncidentDetailsError) {
            return AppScaffold(
              useGradient: true,
              gradientBegin: Alignment.topCenter,
              gradientEnd: Alignment.bottomCenter,
              showDrawer: false,
              appBar: const AppBarWidget(hasNotifications: true),
              showBottomNav: false,
              child: Center(
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
                        if (widget.incidentId != null &&
                            widget.incidentId!.isNotEmpty) {
                          AppDI.incidentDetailsCubit.getIncidentById(
                            widget.incidentId!,
                          );
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show content only when data is loaded and matches
          if (state is IncidentDetailsLoaded) {
            final loadedIncidentId =
                state.incident.incidentId ?? state.incident.sId ?? '';
            if (loadedIncidentId == widget.incidentId &&
                widget.incidentId != null &&
                widget.incidentId!.isNotEmpty) {
              final incidentData = state.incident;
              final String incidentTitle =
                  (state.incident.incidentId ?? '').replaceFirst('#', '');

              final bool showToggle = !(incidentData.adminStatus ==
                      'ERT Assigned' &&
                  true /* isTeamLeaderView */);

              return Stack(
                children: [
                  AppScaffold(
                    useGradient: true,
                    gradientBegin: Alignment.topCenter,
                    gradientEnd: Alignment.bottomCenter,
                    showDrawer: false,
                    appBar: const AppBarWidget(hasNotifications: true),
                    showBottomNav: false,
                    child: RefreshIndicator(
                      onRefresh: () => AppDI.incidentDetailsCubit
                          .getIncidentById(widget.incidentId!),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  width: 35,
                                  decoration: BoxDecoration(
                                    color: ColorHelper.white
                                        .withValues(alpha: 0.4),
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
                                Text(
                                  incidentTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: ColorHelper.black),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    if (widget.incidentId == null ||
                                        widget.incidentId!.isEmpty) {
                                      return;
                                    }
                                    context.pushNamed(
                                      Routes.chatScreen,
                                      queryParameters: {
                                        'incidentId': widget.incidentId!,
                                      },
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 16),
                                    padding: const EdgeInsets.all(10),
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
                            const SizedBox(height: 8),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: IncidentOverviewDetails(
                                incident: incidentData,
                                title: 'EmergeX Case Overview',
                                isEditRequired: false,
                                rowSize: 1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Toggle pill
                            if (showToggle)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ColorHelper.white
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(TextHelper.cardView),
                                        const SizedBox(width: 8),
                                        ValueListenableBuilder<bool>(
                                          valueListenable: _isGanttView,
                                          builder: (_, v, __) => ToggleButton(
                                            handleToggle: (val) =>
                                                _isGanttView.value = val,
                                            checked: v,
                                            innerCircleColor: ColorHelper.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(TextHelper.ganttView),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Card or Gantt view
                            BlocProvider<TeamsTabDataCubit>(
                              create: (context) => TeamsTabDataCubit(
                                GetIt.instance<GetIncidentByIdUseCase>(),
                              ),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _isGanttView,
                                builder: (_, isGantt, __) {
                                  final bool isEditMode =
                              //    true;
                                      incidentData.adminStatus == 'Inprogress' ||
                                      incidentData.adminStatus == 'ERT Assigned';
                                  return isGantt  
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: IncidentGanttWidget(
                                            incident: incidentData,
                                          ),
                                        )
                                      : MemberAssignCard(
                                          incident: incidentData,
                                          isEditMode: isEditMode,
                                        );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildBottomActions(
                      context,
                      incidentData,
                    ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  MovableFloatingButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        isDismissible: true,
                        enableDrag: true,
                        builder: (context) {
                          return AiInsightsCard(
                            showIncidentInsights: true,
                            incident: incidentData,
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            }
          }

          // Fallback: Show loading if no data matches
          return AppScaffold(
            useGradient: true,
            gradientBegin: Alignment.topCenter,
            gradientEnd: Alignment.bottomCenter,
            showDrawer: false,
            appBar: const AppBarWidget(hasNotifications: true),
            showBottomNav: false,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
