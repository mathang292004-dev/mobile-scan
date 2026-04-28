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
import 'package:emergex/presentation/investigation/investigation_member/cubit/investigation_member_cubit.dart';
import 'package:emergex/presentation/investigation/common/widgets/investigation_dashboard_header.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvestigationMemberDashboardScreen extends StatefulWidget {
  const InvestigationMemberDashboardScreen({super.key});

  @override
  State<InvestigationMemberDashboardScreen> createState() =>
      _InvestigationMemberDashboardScreenState();
}

class _InvestigationMemberDashboardScreenState
    extends State<InvestigationMemberDashboardScreen> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final cubit = AppDI.investigationMemberCubit;
    if (cubit.state.data == null) {
      cubit.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.investigationMemberCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: BlocConsumer<InvestigationMemberCubit,
            InvestigationMemberState>(
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
            final totalTasks = counts?.total ?? 0;
            final inProgress = counts?.inProgress ?? 0;
            final completed = counts?.resolved ?? 0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: InvestigationDashboardHeader(
                    title: TextHelper.investigationMember,
                    searchBarKey: searchBarKey,
                    initialFromDate: data.startDate,
                    initialToDate: data.endDate,
                    onDateRangeSelected: (dateRange, searchText) async {
                      await AppDI.investigationMemberCubit
                          .loadDashboard(page: 1);
                    },
                  ),
                ),
                Expanded(
                  child: state.viewType == DashboardViewType.graph
                      ? _buildGraphContent(
                          context, state, data, totalTasks, inProgress,
                          completed)
                      : _buildNormalContent(
                          context, state, data, totalTasks, inProgress,
                          completed),
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
    InvestigationMemberState state,
    int totalTasks,
    int inProgress,
    int completed,
  ) {
    return AppMetricCard(
      titles: const [
        TextHelper.totalTasks,
        TextHelper.inProgress,
        TextHelper.completed,
      ],
      selectedIndex: state.selectedMetricIndex,
      counts: [
        totalTasks.toString(),
        inProgress.toString(),
        completed.toString(),
      ],
      icons: [
        Image.asset(Assets.dashboardIconTotalIncidents,
            width: 22, height: 22, color: ColorHelper.primaryColor),
        Image.asset(Assets.dashboardIconApproved,
            width: 22, height: 22, color: ColorHelper.primaryColor),
        Image.asset(Assets.dashboardapproveIconPending,
            width: 22, height: 22, color: ColorHelper.primaryColor),
      ],
      onTaps: [
        () => AppDI.investigationMemberCubit.onMetricTap(0),
        () => AppDI.investigationMemberCubit.onMetricTap(1),
        () => AppDI.investigationMemberCubit.onMetricTap(2),
      ],
    );
  }

  Widget _buildGraphContent(
    BuildContext context,
    InvestigationMemberState state,
    dynamic data,
    int totalTasks,
    int inProgress,
    int completed,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.investigationMemberCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, totalTasks, inProgress, completed),
            const SizedBox(height: 10),
            CaseOverviewChartWidget(
              title: TextHelper.investigationMember,
              series: const [
                BarChartSeriesData(
                    label: TextHelper.inProgress, color: Color(0xFFC8EEBF)),
                BarChartSeriesData(
                    label: TextHelper.completed, color: Color(0xFF3DA229)),
              ],
              categories: const [
                BarChartCategoryData(label: 'Incident', values: [50, 30]),
                BarChartCategoryData(label: 'Near Miss', values: [35, 20]),
                BarChartCategoryData(label: 'Observation', values: [25, 15]),
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
    InvestigationMemberState state,
    dynamic data,
    int totalTasks,
    int inProgress,
    int completed,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.investigationMemberCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, totalTasks, inProgress, completed),
            const SizedBox(height: 10),
            _buildCaseListSection(context, state, data, isExpanded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseListSection(
    BuildContext context,
    InvestigationMemberState state,
    dynamic data, {
    bool isExpanded = false,
  }) {
    final incidents = data.result ?? [];
    return CaseListSectionWidget(
      isExpanded: isExpanded,
      title: TextHelper.investigationMember,
      searchBarKey: searchBarKey,
      onActionTap: () => AppDI.investigationMemberCubit.toggleViewType(),
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
        AppDI.investigationMemberCubit.onSearchChanged(value);
      },
      paginationWidget: AppPaginationControls(
        totalPages: AppDI.investigationMemberCubit.getTotalPages(),
        currentPage: state.currentPage,
        onPageChanged: (page) {
          AppDI.investigationMemberCubit.goToPage(page);
        },
      ),
    );
  }
}
