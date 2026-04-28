import 'dart:ui';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';

class AiInsightsOverlay extends StatelessWidget {
  final IncidentDetails? incident;
  final bool showIncidentDetails;

  const AiInsightsOverlay({
    super.key,
    this.incident,
    this.showIncidentDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent, // Make scaffold transparent
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          color: ColorHelper.white.withValues(
            alpha: 0.2,
          ), // Semi-transparent overlay
          child: Stack(
            children: [
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.75,
                        maxWidth: 400,
                      ),
                      child: Container(
                        width: screenWidth * 0.8, // Responsive width
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.0),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ColorHelper.primaryColor,
                              ColorHelper.primaryDark,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                Assets.cardBackgroundPattern,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 24.0,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTitleSection(context),
                                    const SizedBox(height: 20),
                                    if (showIncidentDetails &&
                                        incident != null) ...[
                                      _buildIncidentDetailsSection(context),
                                      const SizedBox(height: 20),
                                    ],
                                    _buildTaskProgressSection(context),
                                    const SizedBox(height: 24),
                                    Text(
                                      incident?.incidentLevel?.value == 'low'
                                          ? TextHelper.aiInsightsLow
                                          : incident?.incidentLevel?.value ==
                                                'medium'
                                          ? TextHelper.aiInsightsMedium
                                          : incident?.incidentLevel?.value ==
                                                'high'
                                          ? TextHelper.aiInsightsHigh
                                          : '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: ColorHelper.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Floating Close Button
              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton(
                  onPressed: () => back(),
                  backgroundColor: ColorHelper.successColor,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentDetailsSection(BuildContext context) {
    final i = incident;
    if (i == null) return const SizedBox.shrink();

    final details = <(String, String)>[
      (TextHelper.incidentId, (i.incidentId ?? '').trim()),
      (TextHelper.incidentLabel, (i.title ?? '').trim()),
      (TextHelper.reportedBy, (i.reportedBy ?? '').trim()),
      (TextHelper.dateReported, (i.reportedDate ?? '').trim()),
      (TextHelper.department, (i.department ?? '').trim()),
      (TextHelper.projectName, (i.projectName ?? '').trim()),
      (TextHelper.country, (i.country ?? '').trim()),
      (TextHelper.branch, (i.branch ?? '').trim()),
      (TextHelper.status, (i.adminStatus ?? i.incidentStatus ?? '').trim()),
    ].where((e) => e.$2.isNotEmpty).toList();

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorHelper.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incident Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ColorHelper.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          ...details.map((e) => _buildDetailRow(context, e.$1, e.$2)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TextHelper.aiInsightsTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          incident?.aiInsights.toString() ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: ColorHelper.white),
        ),
      ],
    );
  }

  Widget _buildTaskProgressSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.dateRangeGreen.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TextHelper.severityLevelTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Color(0xFF5D4037), // Border color
                width: 3, // Border thickness
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: incident?.incidentLevel?.value?.toLowerCase() == 'low'
                    ? 0.25
                    : incident?.incidentLevel?.value?.toLowerCase() == 'medium'
                    ? 0.5
                    : incident?.incidentLevel?.value?.toLowerCase() == 'high'
                    ? 1
                    : 0,
                minHeight: 10,
                backgroundColor: Color(0xFF5D4037),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 224, 204, 16),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TextHelper.severityLevelLow,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ColorHelper.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                TextHelper.severityLevelMedium,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ColorHelper.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                TextHelper.severityLevelHigh,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ColorHelper.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

