import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/app_metric_card.dart';
import 'package:emergex/helpers/widgets/dashboard/case_list_section_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/case_overview_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/app_pagination_controls.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/investigation/investigation_approver/cubit/investigation_approver_cubit.dart';
import 'package:emergex/presentation/investigation/common/widgets/investigation_dashboard_header.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvestigationApproverDashboardScreen extends StatefulWidget {
  const InvestigationApproverDashboardScreen({super.key});

  @override
  State<InvestigationApproverDashboardScreen> createState() =>
      _InvestigationApproverDashboardScreenState();
}

class _InvestigationApproverDashboardScreenState
    extends State<InvestigationApproverDashboardScreen> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final cubit = AppDI.investigationApproverCubit;
    if (cubit.state.data == null) {
      cubit.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.investigationApproverCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: BlocConsumer<InvestigationApproverCubit,
            InvestigationApproverState>(
          listener: (context, state) {
            if (state.processState == ProcessState.error &&
                state.errorMessage != null &&
                state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            if (state.data == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ColorHelper.primaryColor,
                ),
              );
            }

            final data = state.data!;
            final counts = data.statusCount;
            final total = counts?.total ?? 0;
            final pendingReview = counts?.ertToBeAssigned ?? 0;
            final approved = counts?.approved ?? 0;
            final rejected = counts?.rejected ?? 0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: InvestigationDashboardHeader(
                    title: TextHelper.investigationApprover,
                    searchBarKey: searchBarKey,
                    initialFromDate: data.startDate,
                    initialToDate: data.endDate,
                    onDateRangeSelected: (dateRange, searchText) async {
                      await AppDI.investigationApproverCubit
                          .loadDashboard(page: 1);
                    },
                  ),
                ),
                Expanded(
                  child: state.viewType == DashboardViewType.graph
                      ? _buildGraphContent(context, state, data, total,
                          pendingReview, approved, rejected)
                      : _buildNormalContent(context, state, data, total,
                          pendingReview, approved, rejected),
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
    InvestigationApproverState state,
    int total,
    int pendingReview,
    int approved,
    int rejected,
  ) {
    return AppMetricCard(
      titles: const [
        TextHelper.total,
        TextHelper.pendingReview,
        TextHelper.approved,
        TextHelper.rejected,
      ],
      selectedIndex: state.selectedMetricIndex,
      counts: [
        total.toString(),
        pendingReview.toString(),
        approved.toString(),
        rejected.toString(),
      ],
      icons: [
        Image.asset(Assets.dashboardIconTotalIncidents,
            width: 22, height: 22, color: ColorHelper.primaryColor),
        Image.asset(Assets.dashboardIconApproved,
            width: 22, height: 22, color: ColorHelper.primaryColor),
        Image.asset(Assets.dashboardapproveIconPending,
            width: 22, height: 22, color: ColorHelper.primaryColor),
        Image.asset(Assets.dashboardApproveIconReject,
            width: 22, height: 22, color: ColorHelper.primaryColor),
      ],
      onTaps: [
        () => AppDI.investigationApproverCubit.onMetricTap(0),
        () => AppDI.investigationApproverCubit.onMetricTap(1),
        () => AppDI.investigationApproverCubit.onMetricTap(2),
        () => AppDI.investigationApproverCubit.onMetricTap(3),
      ],
    );
  }

  Widget _buildGraphContent(
    BuildContext context,
    InvestigationApproverState state,
    dynamic data,
    int total,
    int pendingReview,
    int approved,
    int rejected,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.investigationApproverCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, total, pendingReview, approved, rejected),
            const SizedBox(height: 10),
            CaseOverviewChartWidget(
              title: TextHelper.investigationApprover,
              series: const [
                BarChartSeriesData(
                    label: TextHelper.pendingReview,
                    color: Color(0xFFC8EEBF)),
                BarChartSeriesData(
                    label: TextHelper.approved, color: Color(0xFF3DA229)),
                BarChartSeriesData(
                    label: TextHelper.rejected, color: Color(0xFFE74B48)),
              ],
              categories: const [
                BarChartCategoryData(
                    label: 'Incident', values: [40, 60, 20]),
                BarChartCategoryData(
                    label: 'Near Miss', values: [30, 45, 15]),
                BarChartCategoryData(
                    label: 'Observation', values: [25, 35, 10]),
              ],
            ),
            const SizedBox(height: 10),
            _buildCaseListSection(context, state, data),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalContent(
    BuildContext context,
    InvestigationApproverState state,
    dynamic data,
    int total,
    int pendingReview,
    int approved,
    int rejected,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.investigationApproverCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, total, pendingReview, approved, rejected),
            const SizedBox(height: 10),
            _buildCaseListSection(context, state, data, isExpanded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseListSection(
    BuildContext context,
    InvestigationApproverState state,
    dynamic data, {
    bool isExpanded = false,
  }) {
    final incidents = data.result ?? [];
    return CaseListSectionWidget(
      isExpanded: isExpanded,
      title: TextHelper.investigationApprover,
      searchBarKey: searchBarKey,
      onActionTap: () => AppDI.investigationApproverCubit.toggleViewType(),
      items: incidents
          .map<CaseListItem>((incident) => CaseListItem(
                caseId: incident.incidentId ?? '',
                status: incident.incidentStatus ?? '',
                caseType: incident.type,
                date: incident.reportedDate != null &&
                        incident.reportedDate!.isNotEmpty
                    ? AppDateUtils.formatDate(incident.reportedDate!)
                    : null,
              ))
          .toList(),
      onSearchChanged: (value) {
        AppDI.investigationApproverCubit.onSearchChanged(value);
      },
      paginationWidget: AppPaginationControls(
        totalPages: AppDI.investigationApproverCubit.getTotalPages(),
        currentPage: state.currentPage,
        onPageChanged: (page) {
          AppDI.investigationApproverCubit.goToPage(page);
        },
      ),
    );
  }
}
