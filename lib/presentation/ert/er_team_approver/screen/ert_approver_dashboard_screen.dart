import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
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
import 'package:emergex/presentation/case_report/member/widgets/date_range_picker.dart';
import 'package:emergex/presentation/case_report/utils/case_report_formatter_utils.dart';
import 'package:emergex/presentation/case_report/widgets/dashboard_filter_dialog.dart';
import 'package:emergex/presentation/ert/er_team_approver/cubit/er_team_approver_dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ERT Approver Dashboard — lists all ERT cases assigned to the approver.
///
/// API: GET /incident/approver-dashboard?type=ert&filters={...}
/// Cubit: [ErTeamApproverDashboardCubit]
/// Tapping a case navigates to [Routes.erTeamApproverDetailScreen].
class ErtApproverDashboardScreen extends StatefulWidget {
  const ErtApproverDashboardScreen({super.key});

  @override
  State<ErtApproverDashboardScreen> createState() =>
      _ErtApproverDashboardScreenState();
}

class _ErtApproverDashboardScreenState
    extends State<ErtApproverDashboardScreen> {
  final GlobalKey<SearchBarWidgetState> _searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final cubit = AppDI.erTeamApproverDashboardCubit;
    if (cubit.state.data == null || cubit.state.filters == null) {
      cubit.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.erTeamApproverDashboardCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        appBar: AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHeader(),
            ),
            Expanded(
              child: BlocConsumer<ErTeamApproverDashboardCubit,
                  ErTeamApproverDashboardState>(
                listener: (context, state) {
                  if (state.processState == ProcessState.loading) {
                    loaderService.showLoader();
                  } else if (state.processState == ProcessState.done ||
                      state.processState == ProcessState.error) {
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
                  if (state.data == null &&
                      state.processState != ProcessState.done) {
                    return const SizedBox.shrink();
                  }
                  return state.viewType == DashboardViewType.graph
                      ? _buildGraphContent(context, state)
                      : _buildNormalContent(context, state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (title + date picker + date range label) ───────────────────────

  Widget _buildHeader() {
    return BlocBuilder<ErTeamApproverDashboardCubit,
        ErTeamApproverDashboardState>(
      builder: (context, state) {
        // Build "Showing results from …" label
        final daterange = state.filters?.daterange;
        String dateRangeText;
        final from = daterange?['from'];
        final to = daterange?['to'];
        if (from != null &&
            from.isNotEmpty &&
            to != null &&
            to.isNotEmpty) {
          final fromDt = DateTime.tryParse(from);
          final toDt = DateTime.tryParse(to);
          if (fromDt != null && toDt != null) {
            dateRangeText =
                '${TextHelper.showingResultsFrom} ${CaseReportFormatterUtils.formatDate(fromDt)} - ${CaseReportFormatterUtils.formatDate(toDt)}';
          } else {
            dateRangeText =
                '${TextHelper.showingResultsFrom} ${TextHelper.allDates}';
          }
        } else {
          dateRangeText =
              '${TextHelper.showingResultsFrom} ${TextHelper.allDates}';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  TextHelper.dashboard,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                DateRangePicker(
                  searchBarKey: _searchBarKey,
                  initialFromDate: from != null && from.isNotEmpty
                      ? DateTime.tryParse(from)
                      : null,
                  initialToDate: to != null && to.isNotEmpty
                      ? DateTime.tryParse(to)
                      : null,
                  onDateRangeChanged: (newText) {
                    if (newText == TextHelper.allDates ||
                        newText == 'All Data') {
                      AppDI.erTeamApproverDashboardCubit.applyDateRange(
                        null,
                        _searchBarKey.currentState?.getSearchBarText(),
                      );
                    }
                  },
                  onDateRangeSelected: (dateRange, searchText) async {
                    await AppDI.erTeamApproverDashboardCubit.applyDateRange(
                      dateRange,
                      searchText,
                    );
                  },
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateRangeText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorHelper.textSecondary,
                      fontSize: 14,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Graph view ────────────────────────────────────────────────────────────

  Widget _buildGraphContent(
    BuildContext context,
    ErTeamApproverDashboardState state,
  ) {
    final stats = state.data?.dashboardStats;
    return SafeArea(
      child: RefreshIndicator(
        color: ColorHelper.primaryColor,
        onRefresh: () => AppDI.erTeamApproverDashboardCubit.loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricCards(context, state),
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
                categories: (stats?.caseOverview ?? const [])
                    .map(
                      (e) => BarChartCategoryData(
                        label: e.caseType.isEmpty ? '-' : e.caseType,
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
                    caseCount: stats?.caseSeverityAnalysis?.high.count ?? 0,
                    percentage:
                        (stats?.caseSeverityAnalysis?.high.percentage ?? 0)
                            .toDouble(),
                    color: ColorHelper.severityHigh,
                  ),
                  SeverityData(
                    label: TextHelper.medium,
                    caseCount: stats?.caseSeverityAnalysis?.medium.count ?? 0,
                    percentage:
                        (stats?.caseSeverityAnalysis?.medium.percentage ?? 0)
                            .toDouble(),
                    color: ColorHelper.severityMedium,
                  ),
                  SeverityData(
                    label: TextHelper.low,
                    caseCount: stats?.caseSeverityAnalysis?.low.count ?? 0,
                    percentage:
                        (stats?.caseSeverityAnalysis?.low.percentage ?? 0)
                            .toDouble(),
                    color: ColorHelper.severityLow,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HighRiskCardWidget(
                riskCount: stats?.highRiskCases?.percentage ?? 0,
                actionNeededCount:
                    stats?.highRiskCases?.immediateActionRequired ?? 0,
                icon: Image.asset(
                  Assets.dashboardIconTotalIncidents,
                  width: 20,
                  height: 20,
                  color: ColorHelper.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              CasesIncreasedWidget(
                percentage:
                    (stats?.casesIncreasedThisMonth ?? 0).toDouble(),
              ),
              const SizedBox(height: 10),
              _buildCaseListSection(context, state),
            ],
          ),
        ),
      ),
    );
  }

  // ── Normal view ───────────────────────────────────────────────────────────

  Widget _buildNormalContent(
    BuildContext context,
    ErTeamApproverDashboardState state,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        color: ColorHelper.primaryColor,
        onRefresh: () => AppDI.erTeamApproverDashboardCubit.loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
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

  // ── Metric cards ──────────────────────────────────────────────────────────

  Widget _buildMetricCards(
    BuildContext context,
    ErTeamApproverDashboardState state,
  ) {
    final summary = state.data?.dashboardStats?.statusSummary;
    final cubit = AppDI.erTeamApproverDashboardCubit;
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
        () => cubit.handleMetricTap(0, null),
        () => cubit.handleMetricTap(1, 'inprogress'),
        () => cubit.handleMetricTap(2, 'Pending Review'),
        () => cubit.handleMetricTap(3, 'closed'),
      ],
    );
  }

  // ── Case list section ─────────────────────────────────────────────────────

  Widget _buildCaseListSection(
    BuildContext context,
    ErTeamApproverDashboardState state, {
    bool isExpanded = false,
  }) {
    final cubit = AppDI.erTeamApproverDashboardCubit;
    final incidents = state.data?.result ?? [];

    return CaseListSectionWidget(
      isExpanded: isExpanded,
      title: TextHelper.emergexCase,
      searchBarKey: _searchBarKey,
      items: incidents
          .map(
            (i) => CaseListItem(
              caseId: i.incidentId ?? '--',
              status: i.incidentStatus ?? '--',
              severityLevel: i.incidentLevel?.value ?? i.severityLevel,
              caseType: i.type,
              date: i.reportedDate,
            ),
          )
          .toList(),
      onActionTap: () => cubit.toggleViewType(),
      onSearchChanged: (value) {
        cubit.applyFilters(
          search: value.isNotEmpty ? value : null,
          clearSearch: value.isEmpty,
        );
      },
      onFilterTap: () {
        final filters = state.filters;
        DashboardFilterDialog.show(
          context,
          currentStatus: filters?.status,
          currentFromDate: filters?.daterange?['from'] != null &&
                  filters!.daterange!['from']!.isNotEmpty
              ? DateTime.tryParse(filters.daterange!['from']!)
              : null,
          currentToDate: filters?.daterange?['to'] != null &&
                  filters!.daterange!['to']!.isNotEmpty
              ? DateTime.tryParse(filters.daterange!['to']!)
              : null,
          onApply: (status, daterange) => cubit.applyFilters(
            status: status,
            daterange: daterange,
            clearStatus: status == null,
            clearDaterange: daterange == null,
          ),
          onReset: () => cubit.resetFilters(),
        );
      },
      onItemTap: (index) {
        if (index < incidents.length) {
          openScreen(
            Routes.erTeamApproverDetailScreen,
            args: {'incidentId': incidents[index].incidentId ?? ''},
          );
        }
      },
      onAuditTap: (index) {
        if (index < incidents.length) {
          showAuditLogBottomSheet(
            context,
            incidents[index].incidentId ?? '',
          );
        }
      },
      paginationWidget: AppPaginationControls(
        totalPages: cubit.getTotalPages(),
        currentPage: (state.data?.page ?? 0) + 1,
        onPageChanged: (page) => cubit.goToPage(page - 1),
      ),
    );
  }
}
