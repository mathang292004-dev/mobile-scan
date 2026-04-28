import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/case_report/member/widgets/date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:emergex/presentation/case_report/member/widgets/date_range_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import '../cubit/investigation_team_member_cubit.dart';

class InvestigationTeamMemberDashboardHeader extends StatelessWidget {
  final GlobalKey<SearchBarWidgetState> searchBarKey;
  final DateRangeCallback? onDateRangeSelected;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const InvestigationTeamMemberDashboardHeader({
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
    return BlocBuilder<
      InvestigationTeamMemberCubit,
      InvestigationTeamMemberState
    >(
      builder: (context, state) {
        String dateRangeText;

        final fromDate = state.fromDate ?? initialFromDate;
        final toDate = state.toDate ?? initialToDate;

        if (fromDate != null && toDate != null) {
          final formattedDateRange =
              '${_formatDate(fromDate)} - ${_formatDate(toDate)}';
          dateRangeText =
              '${TextHelper.showingResultsFrom} $formattedDateRange';
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
                  'Investigation Team Member',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                DateRangePicker(
                  searchBarKey: searchBarKey,
                  initialFromDate: fromDate,
                  initialToDate: toDate,
                  onDateRangeChanged: (newText) {},
                  onDateRangeSelected:
                      onDateRangeSelected ?? (dateRange, searchText) async {},
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateRangeText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorHelper.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
