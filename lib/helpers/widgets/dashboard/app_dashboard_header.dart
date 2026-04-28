import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/case_report/member/widgets/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/generated/color_helper.dart';

class AppDashboardHeader extends StatelessWidget {
  final String title;
  final GlobalKey<SearchBarWidgetState> searchBarKey;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final Function(String)? onDateRangeChanged;
  final DateRangeCallback? onDateRangeSelected;

  const AppDashboardHeader({
    super.key,
    required this.title,
    required this.searchBarKey,
    this.initialFromDate,
    this.initialToDate,
    this.onDateRangeChanged,
    this.onDateRangeSelected,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeText;
    if (initialFromDate != null && initialToDate != null) {
      dateRangeText =
          '${TextHelper.showingResultsFrom} ${_formatDate(initialFromDate!)} - ${_formatDate(initialToDate!)}';
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
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            DateRangePicker(
              searchBarKey: searchBarKey,
              initialFromDate: initialFromDate,
              initialToDate: initialToDate,
              onDateRangeChanged: onDateRangeChanged,
              onDateRangeSelected: onDateRangeSelected ??
                  (dateRange, searchText) async {},
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
  }
}
