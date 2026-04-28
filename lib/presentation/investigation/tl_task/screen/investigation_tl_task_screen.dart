import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
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
import 'package:emergex/presentation/investigation/tl_task/cubit/investigation_tl_task_cubit.dart';
import 'package:emergex/presentation/investigation/common/widgets/investigation_dashboard_header.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvestigationTlTaskScreen extends StatefulWidget {
  const InvestigationTlTaskScreen({super.key});

  @override
  State<InvestigationTlTaskScreen> createState() =>
      _InvestigationTlTaskScreenState();
}

class _InvestigationTlTaskScreenState extends State<InvestigationTlTaskScreen> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final cubit = AppDI.investigationTlTaskCubit;
    if (cubit.state.data == null) {
      cubit.loadDashboard();
    }
  }

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
        child: BlocConsumer<InvestigationTlTaskCubit, InvestigationTlTaskState>(
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
            final assigned = counts?.approved ?? 0;
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
                    title: TextHelper.investigationTlTasks,
                    searchBarKey: searchBarKey,
                    initialFromDate: data.startDate,
                    initialToDate: data.endDate,
                    onDateRangeSelected: (dateRange, searchText) async {
                      await AppDI.investigationTlTaskCubit
                          .loadDashboard(page: 1);
                    },
                  ),
                ),
                Expanded(
                  child: state.viewType == DashboardViewType.graph
                      ? _buildGraphContent(context, state, data, totalTasks,
                          assigned, inProgress, completed)
                      : _buildNormalContent(context, state, data, totalTasks,
                          assigned, inProgress, completed),
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
    InvestigationTlTaskState state,
    int totalTasks,
    int assigned,
    int inProgress,
    int completed,
  ) {
    return AppMetricCard(
      titles: const [
        TextHelper.totalTasks,
        TextHelper.assigned,
        TextHelper.inProgress,
        TextHelper.completed,
      ],
      selectedIndex: state.selectedMetricIndex,
      counts: [
        totalTasks.toString(),
        assigned.toString(),
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
        Image.asset(Assets.dashboardApproveIconReject,
            width: 22, height: 22, color: ColorHelper.primaryColor),
      ],
      onTaps: [
        () => AppDI.investigationTlTaskCubit.onMetricTap(0),
        () => AppDI.investigationTlTaskCubit.onMetricTap(1),
        () => AppDI.investigationTlTaskCubit.onMetricTap(2),
        () => AppDI.investigationTlTaskCubit.onMetricTap(3),
      ],
    );
  }

  Widget _buildGraphContent(
    BuildContext context,
    InvestigationTlTaskState state,
    dynamic data,
    int totalTasks,
    int assigned,
    int inProgress,
    int completed,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.investigationTlTaskCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, totalTasks, assigned, inProgress, completed),
            const SizedBox(height: 10),
            CaseOverviewChartWidget(
              title: TextHelper.investigationTlTasks,
              series: const [
                BarChartSeriesData(
                    label: TextHelper.assigned, color: Color(0xFFC8EEBF)),
                BarChartSeriesData(
                    label: TextHelper.inProgress, color: Color(0xFF3DA229)),
                BarChartSeriesData(
                    label: TextHelper.completed, color: Color(0xFF9EDC8F)),
              ],
              categories: const [
                BarChartCategoryData(
                    label: 'Incident', values: [45, 120, 75]),
                BarChartCategoryData(
                    label: 'Near Miss', values: [65, 90, 110]),
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
    InvestigationTlTaskState state,
    dynamic data,
    int totalTasks,
    int assigned,
    int inProgress,
    int completed,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.investigationTlTaskCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, totalTasks, assigned, inProgress, completed),
            const SizedBox(height: 10),
            _buildCaseListSection(context, state, data, isExpanded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseListSection(
    BuildContext context,
    InvestigationTlTaskState state,
    dynamic data, {
    bool isExpanded = false,
  }) {
    final incidents = data.result ?? [];
    return CaseListSectionWidget(
      isExpanded: isExpanded,
      title: TextHelper.investigationTlTasks,
      searchBarKey: searchBarKey,
      onActionTap: () => AppDI.investigationTlTaskCubit.toggleViewType(),
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
      onItemTap: (index) {
        final incident = incidents[index];
        openScreen(
          Routes.investigationTlTaskListScreen,
          args: {
            'incidentId': incident.incidentId ?? 'INC118',
            'incidentType': incident.type ?? 'Incident',
          },
        );
      },
      onSearchChanged: (value) {
        AppDI.investigationTlTaskCubit.onSearchChanged(value);
      },
      paginationWidget: AppPaginationControls(
        totalPages: AppDI.investigationTlTaskCubit.getTotalPages(),
        currentPage: state.currentPage,
        onPageChanged: (page) {
          AppDI.investigationTlTaskCubit.goToPage(page);
        },
      ),
    );
  }
}
