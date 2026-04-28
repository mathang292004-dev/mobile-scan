import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import '../cubit/investigation_team_member_cubit.dart';

class InvestigationTeamMemberIncidentItemWidget extends StatelessWidget {
  final InvestigationMemberIncident incident;
  final VoidCallback? onTap;

  const InvestigationTeamMemberIncidentItemWidget({
    super.key,
    required this.incident,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
      case 'inprogress':
        return const Color(0xFF2F50D1);
      case 'resolved':
      case 'approved':
        return const Color(0xFF109352);
      case 'rejected':
        return const Color(0xFFD32F2F);
      default:
        return ColorHelper.primaryColor;
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
      case 'inprogress':
        return const Color(0xFF2F50D1).withValues(alpha: 0.32);
      case 'resolved':
      case 'approved':
        return const Color(0xFF048746).withValues(alpha: 0.32);
      case 'rejected':
        return const Color(0xFFD32F2F).withValues(alpha: 0.32);
      default:
        return ColorHelper.primaryColor.withValues(alpha: 0.32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(incident.status);
    final statusBorderColor = _getStatusBorderColor(incident.status);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorHelper.white, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.id,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorHelper.black5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident.projectId,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: ColorHelper.black5,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusBorderColor, width: 1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  incident.status,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            incident.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: ColorHelper.black4,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          Assets.severity,
                          height: 12,
                          width: 12,
                          color: ColorHelper.tertiaryColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Severity Level :',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ColorHelper.tertiaryColor,
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          incident.severity,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ColorHelper.tertiaryColor,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Image.asset(
                          Assets.priority,
                          height: 12,
                          width: 12,
                          color: ColorHelper.tertiaryColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Priority:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ColorHelper.tertiaryColor,
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          incident.priority,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ColorHelper.tertiaryColor,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorHelper.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'View Details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
