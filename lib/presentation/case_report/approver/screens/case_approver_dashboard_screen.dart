import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/case_report/widgets/dashboard_filter_dialog.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/dashboard/app_metric_card.dart';
import 'package:emergex/helpers/widgets/dashboard/app_pagination_controls.dart';
import 'package:emergex/helpers/widgets/dashboard/audit_log_bottom_sheet.dart';
import 'package:emergex/helpers/widgets/dashboard/case_list_section_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/case_overview_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/case_severity_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/cases_increased_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/high_risk_card_widget.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/case_report/approver/cubit/case_approver_dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/approver/widgets/case_approver_dashboard_header.dart';
import 'package:emergex/presentation/case_report/member/widgets/incident_error_state.dart';
import 'package:emergex/presentation/case_report/utils/case_report_dashboard_utils.dart';
import 'package:emergex/role/role_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Case Approver Dashboard.
///
/// Same visual design as the Member dashboard, but backed by
/// `CaseApproverDashboardCubit` which always calls
/// `/api/incident/approver-dashboard?type=admin`.
class CaseApproverDashboardScreen extends StatefulWidget {
  const CaseApproverDashboardScreen({super.key});

  @override
  State<CaseApproverDashboardScreen> createState() =>
      _CaseApproverDashboardScreenState();
}

class _CaseApproverDashboardScreenState
    extends State<CaseApproverDashboardScreen> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final currentProjectId = AppDI.emergexAppCubit.state.selectedProjectId;
    final cubitState = AppDI.caseApproverDashboardCubit.state;
    if (cubitState is CaseApproverDashboardLoaded) {
      if (cubitState.projectId != currentProjectId) {
        AppDI.caseApproverDashboardCubit.loadInitialData();
      }
    } else {
      AppDI.caseApproverDashboardCubit.loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.caseApproverDashboardCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        appBar: AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CaseApproverDashboardHeader(searchBarKey: searchBarKey),
            ),
            Expanded(
              child:
                  BlocConsumer<
                    CaseApproverDashboardCubit,
                    CaseApproverDashboardState
                  >(
                    listener: (context, state) {
                      if (state is CaseApproverDashboardLoaded) {
                        if (state.processState == ProcessState.loading) {
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
                      } else if (state is CaseApproverDashboardError) {
                        loaderService.hideLoader();
                      }
                    },
                    builder: (context, state) {
                      if (state is CaseApproverDashboardLoaded &&
                          !state.isOnline) {
                        return const IncidentErrorState(
                          errorMessage: 'No internet connection',
                        );
                      }
                      if (state is CaseApproverDashboardError) {
                        return IncidentErrorState(errorMessage: state.message);
                      }
                      if (state is CaseApproverDashboardLoaded) {
                        return _buildContent(context, state);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CaseApproverDashboardLoaded state,
  ) {
    return state.viewType == DashboardViewType.graph
        ? _buildGraphContent(context, state)
        : _buildNormalContent(context, state);
  }

  Widget _buildGraphContent(
    BuildContext context,
    CaseApproverDashboardLoaded state,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => CaseReportDashboardUtils.reloadApproverDashboard(searchBarKey),
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
                categories: (state.dashboardStats?.caseOverview ?? const [])
                    .map(
                      (e) => BarChartCategoryData(
                        label: e.caseType.isEmpty ? '-' : e.caseType,
                        values: [
                          e.pending.toDouble(),
                          e.inprogress.toDouble(),
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
                    caseCount:
                        state
                            .dashboardStats
                            ?.caseSeverityAnalysis
                            ?.high
                            .count ??
                        0,
                    percentage:
                        (state
                                    .dashboardStats
                                    ?.caseSeverityAnalysis
                                    ?.high
                                    .percentage ??
                                0)
                            .toDouble(),
                    color: ColorHelper.severityHigh,
                  ),
                  SeverityData(
                    label: TextHelper.medium,
                    caseCount:
                        state
                            .dashboardStats
                            ?.caseSeverityAnalysis
                            ?.medium
                            .count ??
                        0,
                    percentage:
                        (state
                                    .dashboardStats
                                    ?.caseSeverityAnalysis
                                    ?.medium
                                    .percentage ??
                                0)
                            .toDouble(),
                    color: ColorHelper.severityMedium,
                  ),
                  SeverityData(
                    label: TextHelper.low,
                    caseCount:
                        state.dashboardStats?.caseSeverityAnalysis?.low.count ??
                        0,
                    percentage:
                        (state
                                    .dashboardStats
                                    ?.caseSeverityAnalysis
                                    ?.low
                                    .percentage ??
                                0)
                            .toDouble(),
                    color: ColorHelper.severityLow,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HighRiskCardWidget(
                riskCount: state.dashboardStats?.highRiskCases?.percentage ?? 0,
                actionNeededCount:
                    state
                        .dashboardStats
                        ?.highRiskCases
                        ?.immediateActionRequired ??
                    0,
                icon: Image.asset(
                  Assets.dashboardIconTotalIncidents,
                  width: 20,
                  height: 20,
                  color: ColorHelper.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              CasesIncreasedWidget(
                percentage: (state.dashboardStats?.casesIncreasedThisMonth ?? 0)
                    .toDouble(),
              ),
              const SizedBox(height: 10),
              _buildCaseListSection(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContent(
    BuildContext context,
    CaseApproverDashboardLoaded state,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => CaseReportDashboardUtils.reloadApproverDashboard(searchBarKey),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricCards(context, state),
              const SizedBox(height: 24),
              _buildCaseListSection(context, state, isExpanded: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards(
    BuildContext context,
    CaseApproverDashboardLoaded state,
  ) {
    final summary = state.dashboardStats?.statusSummary;
    return AppMetricCard(
      titles: const [
        TextHelper.totalEmergexCase,
        TextHelper.inprogressLabel,
        TextHelper.approvalPending,
        TextHelper.caseClosed,
      ],
      counts: [
        (summary?.totalEmergexCase ?? 0).toString(),
        (summary?.inprogress ?? 0).toString(),
        (summary?.approvalPending ?? 0).toString(),
        (summary?.closed ?? 0).toString(),
      ],
      icons: [
        Image.asset(
          Assets.dashboardIconTotalIncidents,
          width: 22,
          height: 22,
          color: ColorHelper.primaryColor,
        ),
        Image.asset(
          Assets.dashboardapproveIconPending,
          width: 22,
          height: 22,
          color: ColorHelper.primaryColor,
        ),
        Image.asset(
          Assets.dashboardIconPending,
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
      selectedIndex: state.selectedMetricIndex,
      onTaps: [
        () => CaseReportDashboardUtils.handleApproverMetricTap(0, null),
        () => CaseReportDashboardUtils.handleApproverMetricTap(1, 'inprogress'),
        () => CaseReportDashboardUtils.handleApproverMetricTap(2, 'Pending Review'),
        () => CaseReportDashboardUtils.handleApproverMetricTap(3, 'closed'),
      ],
    );
  }

  Widget _buildCaseListSection(
    BuildContext context,
    CaseApproverDashboardLoaded state, {
    bool isExpanded = false,
  }) {
    final cubit = AppDI.caseApproverDashboardCubit;
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
        cubit.loadIncidents(
          page: 1,
          limit: 10,
          search: value.isNotEmpty ? value : null,
          incidentStatus: state.incidentStatus,
          selectedMetricIndex: state.selectedMetricIndex,
        );
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
          isApprover: true,
        );
      },
      onAuditTap: (index) =>
          showAuditLogBottomSheet(context, incidents[index].id),
      paginationWidget: AppPaginationControls(
        totalPages: cubit.getTotalPages(),
        currentPage: state.currentPage ?? 1,
        onPageChanged: (page) => AppDI.caseApproverDashboardCubit.loadIncidents(
          page: page,
          limit: 10,
          incidentStatus: state.incidentStatus,
          search: state.searchQuery?.isNotEmpty == true
              ? state.searchQuery
              : null,
          selectedMetricIndex: state.selectedMetricIndex,
        ),
      ),
    );
  }

}
