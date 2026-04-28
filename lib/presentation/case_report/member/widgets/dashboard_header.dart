import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:emergex/helpers/text_helper.dart';
import '../../../../generated/color_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'date_range_picker.dart';
import 'package:emergex/di/app_di.dart';

class DashboardHeader extends StatelessWidget {
  final GlobalKey<SearchBarWidgetState> searchBarKey;
  final bool? isTaskButton;
  final Function()? onTaskButtonPressed;
  final DateRangeCallback? onDateRangeSelected;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const DashboardHeader({
    super.key,
    required this.searchBarKey,
    this.isTaskButton,
    this.onTaskButtonPressed,
    this.onDateRangeSelected,
    this.initialFromDate,
    this.initialToDate,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _updateDateRangeText(BuildContext context, String newText) {
    // This will trigger a rebuild of the BlocBuilder with the updated state
    final cubit = AppDI.dashboardCubit;

    if (newText == TextHelper.allDates) {
      // Clear date range filter
      cubit.loadIncidents(
        page: 1,
        limit: 10,
        incidentStatus: cubit.state is DashboardLoaded
            ? (cubit.state as DashboardLoaded).incidentStatus
            : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        String dateRangeText;

        if (state is DashboardLoaded) {
          if (state.fromDate != null && state.toDate != null) {
            final formattedDateRange =
                '${_formatDate(state.fromDate!)} - ${_formatDate(state.toDate!)}';
            dateRangeText =
                '${TextHelper.showingResultsFrom} $formattedDateRange';
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
                Row(
                  children: [
                    DateRangePicker(
                      searchBarKey: searchBarKey,
                      initialFromDate:
                          initialFromDate ??
                          (state is DashboardLoaded ? state.fromDate : null),
                      initialToDate:
                          initialToDate ??
                          (state is DashboardLoaded ? state.toDate : null),
                      onDateRangeChanged: (newText) =>
                          _updateDateRangeText(context, newText),
                      onDateRangeSelected:
                          onDateRangeSelected ??
                          (dateRange, searchText) async {
                            final cubit = AppDI.dashboardCubit;
                            String? currentIncidentStatus;
                            int selectedMetricIndex = 0;

                            if (cubit.state is DashboardLoaded) {
                              final currentState =
                                  cubit.state as DashboardLoaded;
                              currentIncidentStatus =
                                  currentState.incidentStatus;
                              selectedMetricIndex =
                                  currentState.selectedMetricIndex;
                            }

                            // Call API with date range
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
                    const SizedBox(width: 5),
                    if (isTaskButton ?? false)
                      EmergexButton(
                        text: TextHelper.myTask,
                        textColor: ColorHelper.white,
                        colors: [ColorHelper.green, ColorHelper.green],
                        buttonHeight: 34,
                        borderRadius: 25,
                        onPressed: onTaskButtonPressed,
                      ),
                  ],
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
