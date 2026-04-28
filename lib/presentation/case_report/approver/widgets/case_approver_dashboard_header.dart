import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/case_report/approver/cubit/case_approver_dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/member/widgets/date_range_picker.dart';
import 'package:emergex/presentation/case_report/utils/case_report_formatter_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Header for the Case Approver Dashboard.
/// Mirrors the member [DashboardHeader] but is bound to
/// [CaseApproverDashboardCubit] so it never leaks state across roles.
class CaseApproverDashboardHeader extends StatelessWidget {
  final GlobalKey<SearchBarWidgetState> searchBarKey;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const CaseApproverDashboardHeader({
    super.key,
    required this.searchBarKey,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaseApproverDashboardCubit, CaseApproverDashboardState>(
      builder: (context, state) {
        String dateRangeText;
        if (state is CaseApproverDashboardLoaded &&
            state.fromDate != null &&
            state.toDate != null) {
          dateRangeText =
              '${TextHelper.showingResultsFrom} ${CaseReportFormatterUtils.formatDate(state.fromDate!)} - ${CaseReportFormatterUtils.formatDate(state.toDate!)}';
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
                  searchBarKey: searchBarKey,
                  initialFromDate: initialFromDate ??
                      (state is CaseApproverDashboardLoaded
                          ? state.fromDate
                          : null),
                  initialToDate: initialToDate ??
                      (state is CaseApproverDashboardLoaded
                          ? state.toDate
                          : null),
                  onDateRangeChanged: (newText) {
                    if (newText == TextHelper.allDates) {
                      AppDI.caseApproverDashboardCubit.loadIncidents(
                        page: 1,
                        limit: 10,
                        incidentStatus:
                            state is CaseApproverDashboardLoaded
                                ? state.incidentStatus
                                : null,
                      );
                    }
                  },
                  onDateRangeSelected: (dateRange, searchText) async {
                    final cubit = AppDI.caseApproverDashboardCubit;
                    String? currentIncidentStatus;
                    int selectedMetricIndex = 0;
                    if (cubit.state is CaseApproverDashboardLoaded) {
                      final s = cubit.state as CaseApproverDashboardLoaded;
                      currentIncidentStatus = s.incidentStatus;
                      selectedMetricIndex = s.selectedMetricIndex;
                    }
                    cubit.loadIncidents(
                      page: 1,
                      limit: 10,
                      search: searchText ?? '',
                      incidentStatus: currentIncidentStatus,
                      daterange: dateRange,
                      selectedMetricIndex: selectedMetricIndex,
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
}
