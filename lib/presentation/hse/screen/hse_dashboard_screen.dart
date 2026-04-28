import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/enums/dashboard_view_type.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/app_metric_card.dart';
import 'package:emergex/helpers/widgets/dashboard/case_list_section_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/hse_case_overview_chart_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/app_pagination_controls.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/hse/cubit/hse_dashboard_cubit.dart';
import 'package:emergex/presentation/hse/widgets/hse_dashboard_header.dart';
import 'package:emergex/presentation/hse/widgets/behaviour_insights_widget.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HseDashboardScreen extends StatefulWidget {
  const HseDashboardScreen({super.key});

  @override
  State<HseDashboardScreen> createState() => _HseDashboardScreenState();
}

class _HseDashboardScreenState extends State<HseDashboardScreen> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final cubit = AppDI.hseDashboardCubit;
    if (cubit.state.data == null) {
      cubit.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.hseDashboardCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(hasNotifications: true),
        showBottomNav: false,
        child: BlocConsumer<HseDashboardCubit, HseDashboardState>(
          listener: (context, state) {
            if (state.processState == ProcessState.loading &&
                state.data == null) {
              loaderService.showLoader();
            } else {
              loaderService.hideLoader();
              if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) {
                showSnackBar(context, state.errorMessage!, isSuccess: false);
              }
            }
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
            final totalActive = counts?.total ?? 0;
            final approved = counts?.approved ?? counts?.verified ?? 0;
            final pending = counts?.notVerified ?? 0;
            final rejected = counts?.rejected ?? 0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: HseDashboardHeader(
                    searchBarKey: searchBarKey,
                    initialFromDate: data.startDate,
                    initialToDate: data.endDate,
                    onDateRangeSelected: (dateRange, searchText) async {
                      await AppDI.hseDashboardCubit.applyDateRange(
                        dateRange,
                        searchText,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: state.viewType == DashboardViewType.graph
                      ? _buildGraphContent(context, state, data, totalActive,
                          approved, pending, rejected)
                      : _buildNormalContent(context, state, data, totalActive,
                          approved, pending, rejected),
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
    HseDashboardState state,
    int totalActive,
    int approved,
    int pending,
    int rejected,
  ) {
    return AppMetricCard(
      titles: const [
        TextHelper.emergexCase,
        TextHelper.approved,
        TextHelper.pending,
        TextHelper.rejected,
      ],
      selectedIndex: state.selectedMetricIndex,
      counts: [
        totalActive.toString(),
        approved.toString(),
        pending.toString(),
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
        () => AppDI.hseDashboardCubit.onMetricTap(0),
        () => AppDI.hseDashboardCubit.onMetricTap(1),
        () => AppDI.hseDashboardCubit.onMetricTap(2),
        () => AppDI.hseDashboardCubit.onMetricTap(3),
      ],
    );
  }

  Widget _buildGraphContent(
    BuildContext context,
    HseDashboardState state,
    dynamic data,
    int totalActive,
    int approved,
    int pending,
    int rejected,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.hseDashboardCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, totalActive, approved, pending, rejected),
            const SizedBox(height: 10),
            const HseCaseOverviewChartWidget(
              data: [
                HseBarData('Incident', 45, 75),
                HseBarData('Line of..', 60, 75),
                HseBarData('Use of..', 65, 100),
                HseBarData('Pinch..', 15, 30),
                HseBarData('3 point..', 55, 75),
                HseBarData('Commu..', 20, 65),
                HseBarData('House..', 15, 65),
                HseBarData('Pre job..', 65, 65),
                HseBarData('Assist..', 35, 65),
                HseBarData('Walkin..', 65, 90),
                HseBarData('Eyes..', 30, 60),
                HseBarData('Hot..', 30, 60),
                HseBarData('Manua..', 30, 65),
                HseBarData('Lock..', 30, 50),
              ],
            ),
            const SizedBox(height: 10),
            const BehaviourInsightsWidget(
              safePercentage: 80,
              atRiskPercentage: 20,
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
    HseDashboardState state,
    dynamic data,
    int totalActive,
    int approved,
    int pending,
    int rejected,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        searchBarKey.currentState?.clearSearchBar();
        await AppDI.hseDashboardCubit.refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCards(
                context, state, totalActive, approved, pending, rejected),
            const SizedBox(height: 10),
            _buildCaseListSection(context, state, data, isExpanded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseListSection(
    BuildContext context,
    HseDashboardState state,
    dynamic data, {
    bool isExpanded = false,
  }) {
    final incidents = data.result ?? [];
    return CaseListSectionWidget(
      isExpanded: isExpanded,
      title: TextHelper.emergexCase,
      searchBarKey: searchBarKey,
      onActionTap: () => AppDI.hseDashboardCubit.toggleViewType(),
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
        AppDI.hseDashboardCubit.onSearchChanged(value);
      },
      paginationWidget: AppPaginationControls(
        totalPages: AppDI.hseDashboardCubit.getTotalPages(),
        currentPage: state.currentPage,
        onPageChanged: (page) {
          AppDI.hseDashboardCubit.goToPage(page);
        },
      ),
    );
  }
}
