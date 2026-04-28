import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:flutter/material.dart';

class InvestigationTaskCard extends StatelessWidget {
  final String incidentId;
  final String title;
  final String status;
  final String assignedTo;
  final String date;
  final VoidCallback? onTap;

  const InvestigationTaskCard({
    super.key,
    required this.incidentId,
    required this.title,
    required this.status,
    required this.assignedTo,
    required this.date,
    this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
      case 'verified':
        return ColorHelper.successColor;
      case 'in progress':
      case 'under investigation':
        return ColorHelper.primaryColor;
      case 'assigned':
      case 'pending review':
      case 'pending':
        return ColorHelper.warningColor;
      case 'rejected':
        return ColorHelper.errorColor;
      default:
        return ColorHelper.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppContainer(
        radius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  incidentId,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ColorHelper.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: ColorHelper.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${TextHelper.assignedTo}: $assignedTo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.textSecondary,
                      ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: ColorHelper.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
