import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:flutter/material.dart';


class DepartmentSectionWidget extends StatelessWidget {
  final String department;
  final String assignedDate;
  final String location;
  final int totalTasks;

  const DepartmentSectionWidget({
    super.key,
    required this.department,
    required this.assignedDate,
    required this.location,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMetricRow('Department', department, context: context),
        _buildMetricRow('Assigned Date',
          DateTimeFormatter.formatDate(DateTime.tryParse(assignedDate)),
          context: context,
        ),
        _buildMetricRow('Location:', location, context: context),
        _buildMetricRow('Total Tasks:', totalTasks.toString(), isLast: true, context: context),
      ],
    );
  }

  Widget _buildMetricRow(
    String label,
    String value, {
    bool isLast = false,
    required BuildContext context,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorHelper.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: ColorHelper.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
