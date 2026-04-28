import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/case_report/member/widgets/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/hse/cubit/hse_dashboard_cubit.dart';
import 'package:emergex/di/app_di.dart';

class HseDashboardHeader extends StatelessWidget {
  final GlobalKey<SearchBarWidgetState> searchBarKey;
  final DateRangeCallback? onDateRangeSelected;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const HseDashboardHeader({
    super.key,
    required this.searchBarKey,
    this.onDateRangeSelected,
    this.initialFromDate,
    this.initialToDate,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HseDashboardCubit, HseDashboardState>(
      builder: (context, state) {
        final fromDate = initialFromDate ?? state.data?.startDate;
        final toDate = initialToDate ?? state.data?.endDate;

        String dateRangeText;
        if (fromDate != null && toDate != null) {
          dateRangeText =
              '${TextHelper.showingResultsFrom} ${_formatDate(fromDate)} - ${_formatDate(toDate)}';
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
                  TextHelper.closerDashboard,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                DateRangePicker(
                  searchBarKey: searchBarKey,
                  initialFromDate: fromDate,
                  initialToDate: toDate,
                  onDateRangeChanged: (newText) {
                    if (newText == TextHelper.allDates) {
                      AppDI.hseDashboardCubit.loadDashboard(page: 1);
                    }
                  },
                  onDateRangeSelected: onDateRangeSelected ??
                      (dateRange, searchText) async {
                        await AppDI.hseDashboardCubit
                            .applyDateRange(dateRange, searchText);
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
