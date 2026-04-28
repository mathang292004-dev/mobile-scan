import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';

class InvestigationApproverDetailScreen extends StatelessWidget {
  final String incidentId;

  const InvestigationApproverDetailScreen({
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
        title: TextHelper.reviewInvestigation,
        showBackButton: true,
        hasNotifications: true,
      ),
      showBottomNav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Investigation Summary
            AppContainer(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.investigationSummary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, TextHelper.incidentId, incidentId),
                  _buildInfoRow(context, TextHelper.status,
                      TextHelper.pendingReview),
                  _buildInfoRow(
                      context, TextHelper.primaryInvestigator, 'John Smith'),
                  _buildInfoRow(context, TextHelper.dateReported, '15 Jan 2025'),
                  _buildInfoRow(
                      context, TextHelper.severityLevel, TextHelper.severityLevelHigh),
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
                    'The investigation has determined that the incident occurred due to a failure in the safety interlock system on Machine #47. Contributing factors include:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildFindingPoint(context,
                      'Maintenance schedule was overdue by 2 weeks'),
                  _buildFindingPoint(
                      context, 'Safety sensor was partially obstructed'),
                  _buildFindingPoint(context,
                      'Operator training records were not up to date'),
                  _buildFindingPoint(context,
                      'Standard operating procedure needs revision'),
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
                  _buildEvidenceItem(
                      context, 'Investigation_Report.pdf', '4.2 MB'),
                  const SizedBox(height: 8),
                  _buildEvidenceItem(
                      context, 'Scene_photos.zip', '12.5 MB'),
                  const SizedBox(height: 8),
                  _buildEvidenceItem(
                      context, 'Witness_statements.pdf', '2.1 MB'),
                  const SizedBox(height: 8),
                  _buildEvidenceItem(
                      context, 'Equipment_inspection.pdf', '1.8 MB'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: EmergexButton(
                    text: TextHelper.approve,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EmergexButton(
                    text: TextHelper.reject,
                    onPressed: () {},
                    colors: const [ColorHelper.errorColor, ColorHelper.errorColor],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: EmergexButton(
                text: TextHelper.sendBack,
                onPressed: () {},
                colors: const [ColorHelper.warningColor, ColorHelper.warningColor],
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
            width: 140,
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

  Widget _buildFindingPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ColorHelper.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.textSecondary,
                    height: 1.4,
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
