import 'dart:ui';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/data/model/er_team_leader/my_task_response.dart';
import 'package:emergex/generated/assets.dart';

class AiInsightsCard extends StatelessWidget {
  final String? description;
  final String? severityLevel; // 'low', 'medium', or 'high'
  final VoidCallback? onClose;
  final bool showAlternateContent; // New boolean connector
  final bool? isTaskDetails;
  final bool? showIncidentInsights; // New boolean for incident insights view
  final IncidentDetails? incident; // Optional incident data
  final AiInsights? aiInsights; // AI insights data for role assessment (legacy)
  final AIAnalysis? aiAnalysis; // AI Analysis data for role assessment
  final AiAnalysis? taskAiAnalysis; // AI Analysis data from task API

  const AiInsightsCard({
    super.key,
    this.description,
    this.severityLevel,
    this.onClose,
    this.showAlternateContent = false, // Default to false
    this.isTaskDetails = false,
    this.showIncidentInsights = false,
    this.incident,
    this.aiInsights,
    this.aiAnalysis,
    this.taskAiAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorHelper.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          color: ColorHelper.white.withValues(alpha: 0.2),
          child: Stack(
            children: [
              // Main card centered
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (isTaskDetails ?? false) ? 16.0 : 32.0,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: (isTaskDetails ?? false) ? 900 : 600,
                    ),
                    padding: (isTaskDetails ?? false)
                        ? EdgeInsets.zero
                        : const EdgeInsets.all(24),
                    decoration: (isTaskDetails ?? false)
                        ? null
                        : BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                ColorHelper.aiInsightsLightGreen,
                                ColorHelper.aiInsightsLightGreen,
                                ColorHelper.aiInsightsLightGreen,
                                ColorHelper.aiInsightsLightGreen,
                                ColorHelper.aiInsightsLightGreen,
                                ColorHelper.aiInsightsLightGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ColorHelper.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            image: (showIncidentInsights ?? false)
                                ? DecorationImage(
                                    image: AssetImage(Assets.aiInsightsBg),
                                    fit: BoxFit.cover,
                                    opacity: 0.6,
                                  )
                                : null,
                          ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background pattern - only show if not task details and not incident insights
                        if (!(isTaskDetails ?? false) &&
                            !(showIncidentInsights ?? false))
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.5,
                                child: Image.asset(
                                  Assets.cardBackgroundPattern,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),

                        // Content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!(isTaskDetails ?? false))
                              const SizedBox(height: 8),

                            // Title - changes based on boolean (only show if not task details)
                            if (!(isTaskDetails ?? false))
                              Text(
                                showAlternateContent
                                    ? 'AI Role Assessment'
                                    : TextHelper.aiInsightsTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: ColorHelper.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),

                            // Subtitle - only shown for alternate content
                            if (showAlternateContent &&
                                !(isTaskDetails ?? false)) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Concerns on-the-ground safety management in critical situations.',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: ColorHelper.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                              ),
                            ],

                            // Content block
                            if (isTaskDetails ?? false)
                              _buildTaskDetailsContent(context)
                            else if (showIncidentInsights ?? false)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16.0,
                                  bottom: 8.0,
                                ),
                                child: _buildIncidentInsightsContent(context),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16.0,
                                  bottom: 8.0,
                                ),
                                child: Container(
                                  decoration:
                                      !(showAlternateContent &&
                                          aiAnalysis != null)
                                      ? BoxDecoration(
                                          color: ColorHelper.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        )
                                      : null,
                                  padding:
                                      !showAlternateContent ||
                                          aiInsights != null ||
                                          aiAnalysis != null
                                      ? const EdgeInsets.all(24)
                                      : null,
                                  child:
                                      showAlternateContent && aiAnalysis != null
                                      ? _buildAlternateContent(context)
                                      : _buildDefaultContent(context),
                                ),
                              ),

                            if (!(isTaskDetails ?? false))
                              const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Close button at bottom right
              Positioned(
                bottom: 40,
                right: 40,
                child: GestureDetector(
                  onTap: onClose ?? () => back(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: ColorHelper.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorHelper.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        Assets.floatingActionButtonclose,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Default content with progress bars
  Widget _buildDefaultContent(BuildContext context) {
    // Use aiInsights data if available, otherwise use default values
    final roleMatch = aiInsights?.roleMatch ?? 92;
    final hierarchyMatch = aiInsights?.hierarchyMatch ?? 85;
    final responsibilityOverlap = aiInsights?.responsibilityOverlap ?? 78;
    final documentContext = aiInsights?.documentContext ?? 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightItem(TextHelper.roleMatch, roleMatch, context),
        const SizedBox(height: 22),
        _buildInsightItem(
          TextHelper.hierarchyPosition,
          hierarchyMatch,
          context,
        ),
        const SizedBox(height: 22),
        _buildInsightItem(
          TextHelper.responsibilityOverlap,
          responsibilityOverlap,
          context,
        ),
        const SizedBox(height: 22),
        _buildInsightItem(TextHelper.documentContext, documentContext, context),
      ],
    );
  }

  // Alternate content with text blocks (matching the image)
  Widget _buildAlternateContent(BuildContext context) {
    // Use AIAnalysis data if available, otherwise use default content
    final integrationAnalysis =
        aiAnalysis?.integrationAnalysis ??
        'High compatibility with the current Emergency Operations structure.';
    final responsibilityOverlap =
        aiAnalysis?.responsibilityOverlap ??
        'Has a 65% duty overlap with the \'Field Safety Supervisor\' position.';
    final desc = aiAnalysis?.desc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desc != null && desc.isNotEmpty) ...[
          _buildTextBlock('Description', desc, context),
          const SizedBox(height: 20),
        ],
        _buildTextBlock('Integration Analysis', integrationAnalysis, context),
        const SizedBox(height: 20),
        _buildTextBlock(
          'Responsibility Overlap',
          responsibilityOverlap,
          context,
        ),
      ],
    );
  }

  // Text block for alternate content
  Widget _buildTextBlock(
    String title,
    String description,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorHelper.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: ColorHelper.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Task details content
  Widget _buildTaskDetailsContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDFF3DF), Color(0xFFBFE5BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(width: 6),
              Image.asset(
                Assets.aiIcon, // 👈 use your asset here
                width: 18,
                height: 18,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // AI Summary
          _aiFilledCard(
            title: 'AI Generated Summary',
            titleColor: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFEAF8EA),
            description:
                taskAiAnalysis?.aiSummary ??
                'Update the emergency patient assessment protocol with the latest guidelines from the medical board.',
          ),

          const SizedBox(height: 14),

          // Delay Risk
          if (taskAiAnalysis?.delayRiskDetected?.isNotEmpty ?? false)
            _aiBorderCard(
              title: 'Delay Risk Detected',
              titleColor: const Color(0xFFB57A00),
              borderColor: const Color(0xFFB57A00),
              description: taskAiAnalysis!.delayRiskDetected!,
            ),

          const SizedBox(height: 14),

          // Recommendation
          if (taskAiAnalysis?.aiRecommendations?.isNotEmpty ?? false)
            _aiFilledCard(
              title: 'AI Recommendations',
              titleColor: const Color(0xFF0D47A1),
              bgColor: const Color(0xFFEAF2FF),
              description: taskAiAnalysis!.aiRecommendations!,
            ),
        ],
      ),
    );
  }

  Widget _aiFilledCard({
    required String title,
    required String description,
    required Color titleColor,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF5F5F5F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiBorderCard({
    required String title,
    required String description,
    required Color titleColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7EF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF5F5F5F),
            ),
          ),
        ],
      ),
    );
  }

  // Incident insights content (matching the image design)
  Widget _buildIncidentInsightsContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final aiInsightsText = incident?.aiInsights ?? description ?? '';
    final incidentLevelValue =
        incident?.incidentLevel?.value?.toLowerCase() ??
        severityLevel?.toLowerCase() ??
        'low';

    // Calculate progress value based on incident level
    double progressValue = 0.25; // Default to low
    if (incidentLevelValue == 'medium') {
      progressValue = 0.5;
    } else if (incidentLevelValue == 'high') {
      progressValue = 1.0;
    }

    // Get risk assessment text based on level
    String riskAssessmentText = '';
    if (incidentLevelValue == 'low') {
      riskAssessmentText = TextHelper.aiInsightsLow;
    } else if (incidentLevelValue == 'medium') {
      riskAssessmentText = TextHelper.aiInsightsMedium;
    } else if (incidentLevelValue == 'high') {
      riskAssessmentText = TextHelper.aiInsightsHigh;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Insights description text
        Text(
          aiInsightsText,
          style: textTheme.bodyMedium?.copyWith(
            color: ColorHelper.white,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),

        // Severity Level section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorHelper.surfaceColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TextHelper.severityLevelTitle,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorHelper.white,
                ),
              ),
              const SizedBox(height: 8),
              // Progress bar container
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ColorHelper.importantNoteRound,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 10,
                    backgroundColor: ColorHelper.importantNoteRound,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ColorHelper.yellowColor,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Labels: Low, Medium, High
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TextHelper.severityLevelLow,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.white,
                    ),
                  ),
                  Text(
                    TextHelper.severityLevelMedium,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.white,
                    ),
                  ),
                  Text(
                    TextHelper.severityLevelHigh,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Risk Assessment section
        if (riskAssessmentText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorHelper.black.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              riskAssessmentText,
              style: textTheme.bodyMedium?.copyWith(color: ColorHelper.white),
            ),
          ),
        ],
      ],
    );
  }

  // Progress bar insight item (original)
  Widget _buildInsightItem(String title, int value, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: ColorHelper.white,
              ),
            ),
            Text(
              "$value%",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: ColorHelper.resolvedColor.withValues(alpha: 0.67),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorHelper.resolvedColor.withValues(alpha: 0.67),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: ColorHelper.resolvedColor.withValues(alpha: 0.67),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value / 100,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: ColorHelper.yellowColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
