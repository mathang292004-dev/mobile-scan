import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/dashboard/app_dashboard_header.dart';
import 'package:emergex/helpers/widgets/dashboard/app_metric_card.dart';
import 'package:emergex/helpers/widgets/dashboard/app_pagination_controls.dart';
import 'package:emergex/helpers/widgets/dashboard/case_list_section_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/case_overview_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/case_severity_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/cases_increased_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/audit_log_bottom_sheet.dart';
import 'package:emergex/helpers/widgets/dashboard/high_risk_card_widget.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/incident_card_helper.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/widgets/er_leader_funnel_dialog_box.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/cubit/er_team_leader_dashboard_cubit.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';

class ErTeamLeader extends StatelessWidget {
  ErTeamLeader({super.key});

  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.erTeamLeaderDashboardCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child:
            BlocConsumer<
              ErTeamLeaderDashboardCubit,
              ErTeamLeaderDashboardState
            >(
              listener: (context, state) {
                if (state.processState == ProcessState.loading &&
                    state.data == null) {
                  loaderService.showLoader();
                } else {
                  loaderService.hideLoader();
                  if (state.errorMessage != null &&
                      state.errorMessage!.isNotEmpty) {
                    showSnackBar(
                      context,
                      state.errorMessage!,
                      isSuccess: false,
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state.isLoading && state.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = state.data ?? DashboardResponse();
                final counts = state.overallCounts;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AppDashboardHeader(
                        title: TextHelper.tLdashboard,
                        searchBarKey: searchBarKey,
                        initialFromDate: data.startDate,
                        initialToDate: data.endDate,
                        onDateRangeChanged: (newText) {
                          if (newText == TextHelper.allDates) {
                            final f = AppDI.erTeamLeaderDashboardCubit.state.filters;
                            AppDI.erTeamLeaderDashboardCubit.loadDashboard(
                              page: 0,
                              project: f?.project,
                              title: f?.title,
                              status: f?.status,
                              severityLevels: f?.severityLevels,
                              priority: f?.priority,
                              search: f?.search,
                              daterange: null,
                              isRefresh: true,
                            );
                          }
                        },
                        onDateRangeSelected: (dateRange, searchText) async {
                          await AppDI.erTeamLeaderDashboardCubit.loadDashboard(
                            daterange: dateRange,
                            search: searchText,
                            page: 0,
                            isRefresh: true,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: state.viewType == DashboardViewType.graph
                          ? _buildGraphContent(context, state, data, counts)
                          : _buildNormalContent(context, state, data, counts),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _buildMetricCards(
    BuildContext context,
    ErTeamLeaderDashboardState state,
    dynamic counts,
  ) {
    return AppMetricCard(
      titles: const [
        'Total EmergeX Case',
        TextHelper.ertTeamAssigned,
        TextHelper.ertTasksAssigned,
        TextHelper.ertTaskCompleted,
      ],
      selectedIndex: state.selectedMetricIndex,
      counts: [
        (counts?.total ?? 0).toString(),
        (counts?.ertTeamAssigned ?? 0).toString(),
        (counts?.inProgress ?? 0).toString(),
        (counts?.resolved ?? 0).toString(),
      ],
      icons: [
        Image.asset(
          Assets.dashboardIconTotalIncidents,
          width: 22,
          height: 22,
          color: ColorHelper.primaryColor,
        ),
        Image.asset(
          Assets.dashboardIconApproved,
          width: 22,
          height: 22,
          color: ColorHelper.primaryColor,
        ),
        Image.asset(
          Assets.dashboardIconTLResolved,
          width: 22,
          height: 22,
          color: ColorHelper.primaryColor,
        ),
        Image.asset(
          Assets.dashboardIconResolved,
          width: 22,
          height: 22,
          color: ColorHelper.primaryColor,
        ),
      ],
      onTaps: [
        () => AppDI.erTeamLeaderDashboardCubit.handleMetricTap(0, null),
        () => AppDI.erTeamLeaderDashboardCubit.handleMetricTap(
          1,
          TextHelper.ertTeamAssigned,
        ),
        () => AppDI.erTeamLeaderDashboardCubit.handleMetricTap(
          2,
          TextHelper.ertTasksAssigned,
        ),
        () => AppDI.erTeamLeaderDashboardCubit.handleMetricTap(
          3,
          TextHelper.ertTaskCompleted,
        ),
      ],
    );
  }

  Widget _buildGraphContent(
    BuildContext context,
    ErTeamLeaderDashboardState state,
    DashboardResponse data,
    dynamic counts,
  ) {
    return SafeArea(
      child: RefreshIndicator(
      onRefresh: () async =>
          await AppDI.erTeamLeaderDashboardCubit.loadDashboard(isRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(context, state, counts),
            const SizedBox(height: 10),
            CaseOverviewChartWidget(
              title: TextHelper.caseOverview,
              series: const [
                BarChartSeriesData(
                  label: TextHelper.inProgress,
                  color: ColorHelper.chartInProgress,
                ),
                BarChartSeriesData(
                  label: TextHelper.pending,
                  color: ColorHelper.chartPending,
                ),
                BarChartSeriesData(
                  label: TextHelper.closed,
                  color: ColorHelper.chartClosed,
                ),
              ],
              categories: (data.dashboardStats?.caseOverview ?? [])
                  .map(
                    (e) => BarChartCategoryData(
                      label: e.caseType,
                      values: [
                        e.inprogress.toDouble(),
                        e.pending.toDouble(),
                        e.closed.toDouble(),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            CaseSeverityChartWidget(
              title: TextHelper.caseSeverityAnalysis,
              severities: [
                SeverityData(
                  label: TextHelper.high,
                  caseCount: data.dashboardStats?.caseSeverityAnalysis?.high.count ?? 0,
                  percentage: (data.dashboardStats?.caseSeverityAnalysis?.high.percentage ?? 0).toDouble(),
                  color: ColorHelper.severityHigh,
                ),
                SeverityData(
                  label: TextHelper.medium,
                  caseCount: data.dashboardStats?.caseSeverityAnalysis?.medium.count ?? 0,
                  percentage: (data.dashboardStats?.caseSeverityAnalysis?.medium.percentage ?? 0).toDouble(),
                  color: ColorHelper.severityMedium,
                ),
                SeverityData(
                  label: TextHelper.low,
                  caseCount: data.dashboardStats?.caseSeverityAnalysis?.low.count ?? 0,
                  percentage: (data.dashboardStats?.caseSeverityAnalysis?.low.percentage ?? 0).toDouble(),
                  color: ColorHelper.severityLow,
                ),
              ],
            ),
            const SizedBox(height: 10),
            HighRiskCardWidget(
              riskCount: data.dashboardStats?.highRiskCases?.percentage ?? 0,
              actionNeededCount: data.dashboardStats?.highRiskCases?.immediateActionRequired ?? 0,
              icon: Image.asset(
                Assets.dashboardIconTotalIncidents,
                width: 20,
                height: 20,
                color: ColorHelper.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            CasesIncreasedWidget(
              percentage: (data.dashboardStats?.casesIncreasedThisMonth ?? 0).toDouble(),
            ),
            const SizedBox(height: 10),
            CaseListSectionWidget(
              title: TextHelper.emergexCase,
              searchBarKey: searchBarKey,
              onActionTap: () =>
                  AppDI.erTeamLeaderDashboardCubit.toggleViewType(),
              items: (data.result ?? [])
                  .map<CaseListItem>(
                    (incident) => CaseListItem(
                      caseId: IncidentCardHelper.getIncidentId(incident),
                      status: IncidentCardHelper.getStatus(incident),
                      severityLevel: IncidentCardHelper.getSeverity(incident),
                      caseType: incident.type,
                      date:
                          incident.reportedDate != null &&
                              incident.reportedDate!.isNotEmpty
                          ? AppDateUtils.formatDate(incident.reportedDate!)
                          : null,
                    ),
                  )
                  .toList(),
              onSearchChanged: (value) {
                AppDI.erTeamLeaderDashboardCubit.onSearchChanged(value);
              },
              onFilterTap: () {
                ErLeaderFunnelDialogBox.show(
                  context,
                  onApplyFilters:
                      ({project, title, status, severityLevels, priority}) {
                        AppDI.erTeamLeaderDashboardCubit.applyFilters(
                          project: project,
                          title: title,
                          status: status,
                          severityLevels: severityLevels,
                          priority: priority,
                        );
                      },
                );
              },
              onItemTap: (index) {
                final incident = data.result![index];
                final id = incident.incidentId ?? incident.sId ?? '';
                if (id.isNotEmpty) {
                  openScreen(
                    Routes.erTeamOverviewScreen,
                    args: {'incidentId': id},
                  );
                }
              },
              onAuditTap: (index) {
                final incident = data.result![index];
                final id = incident.incidentId ?? incident.sId ?? '';
                if (id.isNotEmpty) {
                  showAuditLogBottomSheet(context, id);
                }
              },
              paginationWidget: AppPaginationControls(
                totalPages: AppDI.erTeamLeaderDashboardCubit.getTotalPages(),
                currentPage: (state.filters?.page ?? 0) + 1,
                onPageChanged: (page) {
                  AppDI.erTeamLeaderDashboardCubit.loadDashboard(
                    page: page - 1,
                    isRefresh: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildNormalContent(
    BuildContext context,
    ErTeamLeaderDashboardState state,
    DashboardResponse data,
    dynamic counts,
  ) {
    return SafeArea(
      child: RefreshIndicator(
      onRefresh: () async =>
          await AppDI.erTeamLeaderDashboardCubit.loadDashboard(isRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(context, state, counts),
            const SizedBox(height: 16),
            CaseListSectionWidget(
              isExpanded: true,
              title: TextHelper.emergexCase,
              searchBarKey: searchBarKey,
              onActionTap: () =>
                  AppDI.erTeamLeaderDashboardCubit.toggleViewType(),
              items: (data.result ?? [])
                  .map<CaseListItem>(
                    (incident) => CaseListItem(
                      caseId: IncidentCardHelper.getIncidentId(incident),
                      status: IncidentCardHelper.getStatus(incident),
                      severityLevel: IncidentCardHelper.getSeverity(incident),
                      caseType: incident.type,
                      date:
                          incident.reportedDate != null &&
                              incident.reportedDate!.isNotEmpty
                          ? AppDateUtils.formatDate(incident.reportedDate!)
                          : null,
                    ),
                  )
                  .toList(),
              onSearchChanged: (value) {
                AppDI.erTeamLeaderDashboardCubit.onSearchChanged(value);
              },
              onFilterTap: () {
                ErLeaderFunnelDialogBox.show(
                  context,
                  onApplyFilters:
                      ({project, title, status, severityLevels, priority}) {
                        AppDI.erTeamLeaderDashboardCubit.applyFilters(
                          project: project,
                          title: title,
                          status: status,
                          severityLevels: severityLevels,
                          priority: priority,
                        );
                      },
                );
              },
              onItemTap: (index) {
                final incident = data.result![index];
                final id = incident.incidentId ?? incident.sId ?? '';
                if (id.isNotEmpty) {
                  openScreen(
                    Routes.erTeamOverviewScreen,
                    args: {'incidentId': id},
                  );
                }
              },
              onAuditTap: (index) {
                final incident = data.result![index];
                final id = incident.incidentId ?? incident.sId ?? '';
                if (id.isNotEmpty) {
                  showAuditLogBottomSheet(context, id);
                }
              },
              paginationWidget: AppPaginationControls(
                totalPages: AppDI.erTeamLeaderDashboardCubit.getTotalPages(),
                currentPage: (state.filters?.page ?? 0) + 1,
                onPageChanged: (page) {
                  AppDI.erTeamLeaderDashboardCubit.loadDashboard(
                    page: page - 1,
                    isRefresh: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
