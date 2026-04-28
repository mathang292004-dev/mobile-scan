import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';

class PrimaryInvestigatorDetailScreen extends StatelessWidget {
  final String incidentId;

  const PrimaryInvestigatorDetailScreen({
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
        title: TextHelper.investigationDetails,
        showBackButton: true,
        hasNotifications: true,
      ),
      showBottomNav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Overview
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.incidentOverview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, TextHelper.incidentId, incidentId),
                  _buildInfoRow(context, TextHelper.status,
                      TextHelper.underInvestigation),
                  _buildInfoRow(context, TextHelper.dateReported, '15 Jan 2025'),
                  _buildInfoRow(
                      context, TextHelper.severityLevel, TextHelper.severityLevelHigh),
                  _buildInfoRow(
                      context, TextHelper.reportedBy, 'Jane Wilson'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Checklist
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.checklist,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildChecklistItem(context, 'Scene documented', true),
                  _buildChecklistItem(context, 'Witnesses interviewed', true),
                  _buildChecklistItem(context, 'Evidence collected', false),
                  _buildChecklistItem(
                      context, 'Root cause analysis completed', false),
                  _buildChecklistItem(
                      context, 'Corrective actions identified', false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Findings
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.investigationFindings,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preliminary findings indicate that the incident was caused by a combination of equipment malfunction and insufficient safety protocols. Further investigation is needed to confirm root cause.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Evidence
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.evidence,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildEvidenceItem(context, 'Scene_photo_01.jpg', '2.3 MB'),
                  const SizedBox(height: 8),
                  _buildEvidenceItem(
                      context, 'Witness_statement.pdf', '1.1 MB'),
                  const SizedBox(height: 8),
                  _buildEvidenceItem(
                      context, 'Equipment_log.xlsx', '0.8 MB'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: EmergexButton(
                text: TextHelper.submitForApproval,
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
            width: 130,
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

  Widget _buildChecklistItem(
      BuildContext context, String title, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isChecked
                  ? ColorHelper.primaryColor
                  : ColorHelper.transparent,
              border: Border.all(
                color: isChecked
                    ? ColorHelper.primaryColor
                    : ColorHelper.textSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 14, color: ColorHelper.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isChecked
                        ? ColorHelper.textPrimary
                        : ColorHelper.textSecondary,
                    decoration:
                        isChecked ? TextDecoration.lineThrough : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(
      BuildContext context, String fileName, String fileSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorHelper.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ColorHelper.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: ColorHelper.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            fileSize,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorHelper.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
