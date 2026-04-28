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
import 'package:emergex/presentation/investigation/primary_investigator/cubit/primary_investigator_cubit.dart';
import 'package:emergex/presentation/investigation/common/widgets/investigation_dashboard_header.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PrimaryInvestigatorDashboardScreen extends StatefulWidget {
  const PrimaryInvestigatorDashboardScreen({super.key});

  @override
  State<PrimaryInvestigatorDashboardScreen> createState() =>
      _PrimaryInvestigatorDashboardScreenState();
}

class _PrimaryInvestigatorDashboardScreenState
    extends State<PrimaryInvestigatorDashboardScreen> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final cubit = AppDI.primaryInvestigatorCubit;
    if (cubit.state.data == null) {
      cubit.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.primaryInvestigatorCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child:
            BlocConsumer<PrimaryInvestigatorCubit, PrimaryInvestigatorState>(
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
            final totalCases = counts?.total ?? 0;
            final underInvestigation = counts?.inProgress ?? 0;
            final findingsSubmitted = counts?.approved ?? 0;
            final awaitingApproval = counts?.ertToBeAssigned ?? 0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: InvestigationDashboardHeader(
                    title: TextHelper.primaryInvestigator,
                    searchBarKey: searchBarKey,
                    initialFromDate: data.startDate,
                    initialToDate: data.endDate,
                    onDateRangeSelected: (dateRange, searchText) async {
                      await AppDI.primaryInvestigatorCubit
                          .loadDashboard(page: 1);
                    },
                  ),
                ),
                Expanded(
                  child: state.viewType == DashboardViewType.graph
                      ? _buildGraphContent(context, state, data, totalCases,
                          underInvestigation, findingsSubmitted,
                          awaitingApproval)
                      : _buildNormalContent(context, state, data, totalCases,
                          underInvestigation, findingsSubmitted,
                          awaitingApproval),
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
    PrimaryInvestigatorState state,
    int totalCases,
    int underInvestigation,
    int findingsSubmitted,
    int awaitingApproval,
  ) {
    return AppMetricCard(
      titles: const [
        TextHelper.totalCases,
        TextHelper.underInvestigation,
        TextHelper.findingsSubmitted,
        TextHelper.awaitingApproval,
      ],
      selectedIndex: state.selectedMetricIndex,
      counts: [
        totalCases.toString(),
        underInvestigation.toString(),
        findingsSubmitted.toString(),
        awaitingApproval.toString(),
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
        () => AppDI.primaryInvestigatorCubit.onMetricTap(0),
        () => AppDI.primaryInvestigatorCubit.onMetricTap(1),
        () => AppDI.primaryInvestigatorCubit.onMetricTap(2),
        () => AppDI.primaryInvestigatorCubit.onMetricTap(3),
      ],
    );
  }

  Widget _buildGraphContent(
    BuildContext context,
    PrimaryInvestigatorState state,
    dynamic data,
    int totalCases,
    int underInvestigation,
    int findingsSubmitted,
    int awaitingApproval,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.primaryInvestigatorCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(context, state, totalCases, underInvestigation,
                findingsSubmitted, awaitingApproval),
            const SizedBox(height: 10),
            CaseOverviewChartWidget(
              title: TextHelper.primaryInvestigator,
              series: const [
                BarChartSeriesData(
                    label: TextHelper.underInvestigation,
                    color: Color(0xFFC8EEBF)),
                BarChartSeriesData(
                    label: TextHelper.findingsSubmitted,
                    color: Color(0xFF3DA229)),
                BarChartSeriesData(
                    label: TextHelper.awaitingApproval,
                    color: Color(0xFF9EDC8F)),
              ],
              categories: const [
                BarChartCategoryData(
                    label: 'Incident', values: [30, 80, 50]),
                BarChartCategoryData(
                    label: 'Near Miss', values: [45, 60, 70]),
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
    PrimaryInvestigatorState state,
    dynamic data,
    int totalCases,
    int underInvestigation,
    int findingsSubmitted,
    int awaitingApproval,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.primaryInvestigatorCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(context, state, totalCases, underInvestigation,
                findingsSubmitted, awaitingApproval),
            const SizedBox(height: 10),
            _buildCaseListSection(context, state, data, isExpanded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseListSection(
    BuildContext context,
    PrimaryInvestigatorState state,
    dynamic data, {
    bool isExpanded = false,
  }) {
    final incidents = data.result ?? [];
    return CaseListSectionWidget(
      isExpanded: isExpanded,
      title: TextHelper.primaryInvestigator,
      searchBarKey: searchBarKey,
      onActionTap: () => AppDI.primaryInvestigatorCubit.toggleViewType(),
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
          Routes.primaryInvestigatorDetailScreen,
          args: {'incidentId': incident.incidentId ?? ''},
        );
      },
      onSearchChanged: (value) {
        AppDI.primaryInvestigatorCubit.onSearchChanged(value);
      },
      paginationWidget: AppPaginationControls(
        totalPages: AppDI.primaryInvestigatorCubit.getTotalPages(),
        currentPage: state.currentPage,
        onPageChanged: (page) {
          AppDI.primaryInvestigatorCubit.goToPage(page);
        },
      ),
    );
  }
}
