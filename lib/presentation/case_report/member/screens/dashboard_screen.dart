import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/presentation/case_report/widgets/dashboard_filter_dialog.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/dashboard/app_pagination_controls.dart';
import 'package:emergex/helpers/widgets/dashboard/audit_log_bottom_sheet.dart';
import 'package:emergex/helpers/widgets/dashboard/case_list_section_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/case_overview_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/case_severity_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/cases_increased_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/high_risk_card_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/app_metric_card.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';

import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/member/widgets/dashboard_header.dart';
import 'package:emergex/presentation/case_report/member/widgets/incident_error_state.dart';
import 'package:emergex/presentation/case_report/utils/case_report_dashboard_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/role/role_config.dart';

class DashboardScreen extends StatefulWidget {
  final String? userName;

  const DashboardScreen({super.key, this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    // Check if data needs to be reloaded for current project
    final currentProjectId = AppDI.emergexAppCubit.state.selectedProjectId;
    final dashboardState = AppDI.dashboardCubit.state;

    if (dashboardState is DashboardLoaded) {
      if (dashboardState.projectId != currentProjectId) {
        AppDI.dashboardCubit.loadInitialData();
      }
    } else {
      AppDI.dashboardCubit.loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      appBar: AppBarWidget(hasNotifications: true),
      showBottomNav: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DashboardHeader(searchBarKey: searchBarKey),
          ),
          Expanded(
            child: BlocConsumer<DashboardCubit, DashboardState>(
              listener: (context, state) {
                if (state is DashboardLoaded) {
                  if (state.processState == ProcessState.loading) {
                    loaderService.showLoader();
                  } else if (state.processState == ProcessState.done ||
                      state.processState == ProcessState.error) {
                    loaderService.hideLoader();

                    // Show toast if there's an error message from API
                    if (state.errorMessage != null &&
                        state.errorMessage!.isNotEmpty) {
                      showSnackBar(
                        context,
                        state.errorMessage!,
                        isSuccess: false,
                      );
                    }
                  }
                } else if (state is DashboardError) {
                  loaderService.hideLoader();
                }
              },
              builder: (context, state) {
                // Show error screen if offline or if there's an error
                if (state is DashboardLoaded && !state.isOnline) {
                  return const IncidentErrorState(
                    errorMessage: 'No internet connection',
                  );
                } else if (state is DashboardError) {
                  return IncidentErrorState(errorMessage: state.message);
                } else if (state is DashboardLoaded &&
                    state.processState == ProcessState.error) {
                  return IncidentErrorState(
                    errorMessage: "Failed to load dashboard data",
                  );
                } else if (state is DashboardLoaded) {
                  return _buildDashboardContent(context, searchBarKey, state);
                }
                return _buildLoadingState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: Container());
  }

  Widget _buildDashboardContent(
    BuildContext context,
    searchBarKey,
    DashboardLoaded state,
  ) {
    if (state.viewType == DashboardViewType.graph) {
      return _buildGraphContent(context, state);
    }
    return _buildNormalContent(context, searchBarKey, state);
  }

  Widget _buildGraphContent(BuildContext context, DashboardLoaded state) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => CaseReportDashboardUtils.reloadMemberIncidents(searchBarKey),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricCards(context, state),
              const SizedBox(height: 10),
              CaseOverviewChartWidget(
                title: TextHelper.caseOverview,
                series: const [
                  BarChartSeriesData(
                    label: TextHelper.pending,
                    color: ColorHelper.chartPending,
                  ),
                  BarChartSeriesData(
                    label: TextHelper.inProgress,
                    color: ColorHelper.chartInProgress,
                  ),
                  BarChartSeriesData(
                    label: TextHelper.closed,
                    color: ColorHelper.chartClosed,
                  ),
                ],
                categories: (state.dashboardStats?.caseOverview ?? [])
                    .map((e) => BarChartCategoryData(
                        label: e.caseType,
                        values: [
                          e.pending.toDouble(),
                          e.inprogress.toDouble(),
                          e.closed.toDouble(),
                        ],
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              CaseSeverityChartWidget(
                title: TextHelper.caseSeverityAnalysis,
                severities: [
                  SeverityData(
                    label: TextHelper.high,
                    caseCount: state.dashboardStats?.caseSeverityAnalysis?.high.count ?? 0,
                    percentage: (state.dashboardStats?.caseSeverityAnalysis?.high.percentage ?? 0).toDouble(),
                    color: ColorHelper.severityHigh,
                  ),
                  SeverityData(
                    label: TextHelper.medium,
                    caseCount: state.dashboardStats?.caseSeverityAnalysis?.medium.count ?? 0,
                    percentage: (state.dashboardStats?.caseSeverityAnalysis?.medium.percentage ?? 0).toDouble(),
                    color: ColorHelper.severityMedium,
                  ),
                  SeverityData(
                    label: TextHelper.low,
                    caseCount: state.dashboardStats?.caseSeverityAnalysis?.low.count ?? 0,
                    percentage: (state.dashboardStats?.caseSeverityAnalysis?.low.percentage ?? 0).toDouble(),
                    color: ColorHelper.severityLow,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HighRiskCardWidget(
                riskCount: state.dashboardStats?.highRiskCases?.percentage ?? 0,
                actionNeededCount: state.dashboardStats?.highRiskCases?.immediateActionRequired ?? 0,
                icon: Image.asset(
                  Assets.dashboardIconTotalIncidents,
                  width: 20,
                  height: 20,
                  color: ColorHelper.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              CasesIncreasedWidget(
                percentage: (state.dashboardStats?.casesIncreasedThisMonth ?? 0).toDouble(),
              ),
              const SizedBox(height: 10),
              _buildCaseListSection(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseListSection(
    BuildContext context,
    DashboardLoaded state, {
    bool isExpanded = false,
  }) {
    final cubit = AppDI.dashboardCubit;
    final incidents = cubit.incidents;
    return CaseListSectionWidget(
      isExpanded: isExpanded,
      title: TextHelper.emergexCase,
      searchBarKey: searchBarKey,
      items: incidents
          .map(
            (i) => CaseListItem(
              caseId: i.id,
              status: i.status,
              severityLevel: i.severityLevel,
              caseType: i.type,
              date: i.dateReported,
            ),
          )
          .toList(),
      onActionTap: () => cubit.toggleViewType(),
      onSearchChanged: (value) {
        cubit.updateSearchQuery(value);
        cubit.setSearchQuery(value);
        CaseReportDashboardUtils.performMemberSearch(cubit, value);
      },
      onFilterTap: () => DashboardFilterDialog.show(
        context,
        currentStatus: state.incidentStatus,
        currentFromDate: state.fromDate,
        currentToDate: state.toDate,
        onApply: (status, daterange) => cubit.loadIncidents(
          page: 1,
          limit: 10,
          incidentStatus: status,
          search: state.searchQuery?.isNotEmpty == true ? state.searchQuery : null,
          daterange: daterange,
          selectedMetricIndex: state.selectedMetricIndex,
        ),
        onReset: () => cubit.loadIncidents(
          page: 1,
          limit: 10,
          selectedMetricIndex: state.selectedMetricIndex,
        ),
      ),
      onItemTap: (index) {
        RoleConfig().handleIncidentCardNavigationAction(
          incidents[index],
          context,
        );
      },
      onAuditTap: (index) =>
          showAuditLogBottomSheet(context, incidents[index].id),
      paginationWidget: AppPaginationControls(
        totalPages: cubit.getTotalPages(),
        currentPage: state.currentPage ?? 1,
        onPageChanged: (page) => CaseReportDashboardUtils.performMemberPageChange(state, page),
      ),
    );
  }

  Widget _buildNormalContent(
    BuildContext context,
    searchBarKey,
    DashboardLoaded state,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => CaseReportDashboardUtils.reloadMemberIncidents(searchBarKey),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricCards(context, state),
              const SizedBox(height: 16),
              _buildCaseListSection(context, state, isExpanded: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context, DashboardLoaded state) {
    final items = RoleConfig().getMetricItems(state);
    return AppMetricCard(
      titles: items
          .map(
            (e) => e.title == TextHelper.totalIncidents
                ? TextHelper.emergexCase
                : e.title,
          )
          .toList(),
      counts: items.map((e) => e.getValue(state)).toList(),
      icons: items
          .map(
            (e) => Opacity(
              opacity: e.iconAsset == Assets.caseTypeIcon ? 0.5 : 1.0,
              child: Image.asset(
                e.iconAsset,
                width: 22,
                height: 22,
                color: ColorHelper.primaryColor,
              ),
            ),
          )
          .toList(),
      selectedIndex: state.selectedMetricIndex,
      onTaps: List.generate(
        items.length,
        (i) => () {
          FocusScope.of(context).unfocus();
          CaseReportDashboardUtils.handleMemberMetricTap(state, items[i], i);
        },
      ),
    );
  }

}
