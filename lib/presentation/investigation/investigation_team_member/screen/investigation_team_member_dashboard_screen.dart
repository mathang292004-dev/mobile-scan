import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import '../cubit/investigation_team_member_cubit.dart';
import '../widgets/investigation_team_member_dashboard_header.dart';
import '../widgets/investigation_team_member_metrics_widget.dart';
import '../widgets/investigation_team_member_incident_item_widget.dart';
import '../widgets/investigation_team_member_pagination_controls.dart';

class InvestigationTeamMemberDashboardScreen extends StatelessWidget {
  const InvestigationTeamMemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<InvestigationTeamMemberCubit>()..loadDashboard(),
      child: const _InvestigationTeamMemberDashboardView(),
    );
  }
}

class _InvestigationTeamMemberDashboardView extends StatefulWidget {
  const _InvestigationTeamMemberDashboardView();

  @override
  State<_InvestigationTeamMemberDashboardView> createState() =>
      _InvestigationTeamMemberDashboardViewState();
}

class _InvestigationTeamMemberDashboardViewState
    extends State<_InvestigationTeamMemberDashboardView> {
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  DateTime? _getFromDateFromFilters(InvestigationTeamMemberState state) {
    if (state.filters?.daterange == null) return null;
    final fromStr = state.filters!.daterange!['from'];
    if (fromStr == null || fromStr.isEmpty) return null;
    try {
      return DateTime.parse(fromStr);
    } catch (e) {
      return null;
    }
  }

  DateTime? _getToDateFromFilters(InvestigationTeamMemberState state) {
    if (state.filters?.daterange == null) return null;
    final toStr = state.filters!.daterange!['to'];
    if (toStr == null || toStr.isEmpty) return null;
    try {
      return DateTime.parse(toStr);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      showDrawer: false,
      appBar: const AppBarWidget(hasNotifications: true),
      showBottomNav: false,
      child: BlocConsumer<InvestigationTeamMemberCubit, InvestigationTeamMemberState>(
        listener: (context, state) {
          if (state.processState == ProcessState.loading) {
            loaderService.showLoader();
          } else if (state.processState == ProcessState.done ||
              state.processState == ProcessState.error) {
            loaderService.hideLoader();

            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              showSnackBar(context, state.errorMessage!, isSuccess: false);
            }
          }
        },
        builder: (context, state) {
          if (state.processState == ProcessState.none && !state.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<InvestigationTeamMemberCubit>().loadDashboard();
            });
          }

          if (state.isLoading && state.incidents == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.processState == ProcessState.error &&
              state.incidents == null) {
            return Center(
              child: Text(
                'Error: ${state.errorMessage ?? "Failed to load dashboard"}',
              ),
            );
          }

          if (state.incidents != null &&
              state.totalActive != null &&
              state.resolved != null) {
            final totalActive = state.totalActive ?? 0;
            final resolved = state.resolved ?? 0;
            final inProgress = state.inProgress ?? (totalActive - resolved);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: InvestigationTeamMemberDashboardHeader(
                    searchBarKey: searchBarKey,
                    initialFromDate:
                        _getFromDateFromFilters(state) ??
                        DateTime.now().subtract(const Duration(days: 30)),
                    initialToDate:
                        _getToDateFromFilters(state) ?? DateTime.now(),
                    onDateRangeSelected: (dateRange, searchText) async {
                      await context
                          .read<InvestigationTeamMemberCubit>()
                          .applyFilters(
                            search: searchText,
                            daterange: dateRange,
                          );
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final cubit = context
                          .read<InvestigationTeamMemberCubit>();
                      await cubit.refreshDashboard();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InvestigationTeamMemberMetricsWidget(
                            totalActiveCount: totalActive.toString(),
                            inProgressCount: inProgress.toString(),
                            resolvedCount: resolved.toString(),
                            selectedMetricIndex: state.selectedMetricIndex,
                            onTotalActiveTap: () {
                              final cubit = context
                                  .read<InvestigationTeamMemberCubit>();
                              cubit.updateSelectedMetricIndex(0);
                              cubit.applyFilters(page: 0, clearStatus: true);
                            },
                            onInProgressTap: () {
                              final cubit = context
                                  .read<InvestigationTeamMemberCubit>();
                              cubit.updateSelectedMetricIndex(1);
                              cubit.applyFilters(page: 0, status: 'inprogress');
                            },
                            onResolvedTap: () {
                              final cubit = context
                                  .read<InvestigationTeamMemberCubit>();
                              cubit.updateSelectedMetricIndex(2);
                              cubit.applyFilters(page: 0, status: 'resolved');
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: ColorHelper.white.withValues(alpha: 0.3),
                              border: Border.all(
                                color: ColorHelper.white,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        TextHelper.emergexCase,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: ColorHelper.black5,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: SearchBarWidget(
                                        key: searchBarKey,
                                        width: 50,
                                        height: 20,
                                        prefixIcon: Icons.search_rounded,
                                        hintText:
                                            "${TextHelper.search} Incidents",
                                        onChanged: (value) {
                                          final cubit = context
                                              .read<
                                                InvestigationTeamMemberCubit
                                              >();
                                          cubit.applyFilters(search: value);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        showSnackBar(
                                          context,
                                          'Filters not implemented for Investigation dummy yet.',
                                        );
                                      },
                                      child: Container(
                                        height: 45,
                                        width: 45,
                                        decoration: BoxDecoration(
                                          color: ColorHelper.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: ColorHelper.primaryColor
                                                .withValues(alpha: 0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.asset(
                                            Assets.funnelIcon,
                                            width: 22,
                                            color: ColorHelper.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (state.incidents != null &&
                                    state.incidents!.isNotEmpty)
                                  ListView.builder(
                                    itemCount: state.incidents!.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final incident = state.incidents![index];
                                      return InvestigationTeamMemberIncidentItemWidget(
                                        incident: incident,
                                        onTap: () {
                                          if (incident.id.isNotEmpty) {
                                            openScreen(
                                              Routes
                                                  .investigationTeamMemberTasksScreen,
                                              args: {'incidentId': incident.id},
                                            );
                                          }
                                        },
                                      );
                                    },
                                  )
                                else
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'No incidents found',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: ColorHelper.black5,
                                            ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Center(
                                  child:
                                      InvestigationTeamMemberPaginationControls(
                                        totalPages: state.totalPages,
                                        currentPage: state.currentPage + 1,
                                        onPageChanged: (page) {
                                          final cubit = context
                                              .read<
                                                InvestigationTeamMemberCubit
                                              >();
                                          cubit.loadDashboard(page: page - 1);
                                        },
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
