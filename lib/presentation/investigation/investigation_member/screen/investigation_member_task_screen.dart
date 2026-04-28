import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';

class InvestigationMemberTaskScreen extends StatelessWidget {
  final String incidentId;

  const InvestigationMemberTaskScreen({
    super.key,
    required this.incidentId,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      showDrawer: false,
      appBar: const AppBarWidget(
        title: TextHelper.taskDetails,
        showBackButton: true,
        hasNotifications: true,
      ),
      showBottomNav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.taskInfo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, TextHelper.incidentId, incidentId),
                  _buildInfoRow(context, TextHelper.taskDetailsLabel,
                      'Collect witness statements and document physical evidence at incident location.'),
                  _buildInfoRow(context, TextHelper.assignedTo, 'Michael Brown'),
                  _buildInfoRow(context, TextHelper.status, TextHelper.inProgress),
                  _buildInfoRow(context, TextHelper.dateReported, '17 Jan 2025'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Update
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.statusUpdate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ColorHelper.textSecondary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TextHelper.selectStatus,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: ColorHelper.textSecondary,
                                  ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: ColorHelper.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes Section
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.notes,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ColorHelper.textSecondary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      TextHelper.typeYourNotesHere,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColorHelper.textSecondary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Previous notes
                  _buildNoteItem(
                    context,
                    'Michael Brown',
                    '17 Jan 2025, 10:30 AM',
                    'Started evidence collection at the site. Initial photographs taken.',
                  ),
                  const SizedBox(height: 8),
                  _buildNoteItem(
                    context,
                    'Michael Brown',
                    '18 Jan 2025, 2:15 PM',
                    'Completed witness interviews. Two key witnesses provided written statements.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: EmergexButton(
                text: TextHelper.save,
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(
      BuildContext context, String author, String date, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorHelper.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                author,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.primaryColor,
                    ),
              ),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.textSecondary,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorHelper.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
