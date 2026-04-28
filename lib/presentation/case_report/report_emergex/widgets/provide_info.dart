import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

class IncidentReportWidget extends StatelessWidget {
  final int totalQuestion;
  final int unansweredQuestion;
  final List<String> incidentPoints;
  final List<String> examples;

  const IncidentReportWidget({
    super.key,
    required this.totalQuestion,
    required this.unansweredQuestion,
    required this.incidentPoints,
    required this.examples,
  });

  @override
  Widget build(BuildContext context) {
    final double confidenceLevel =
        ((totalQuestion - unansweredQuestion) / totalQuestion) * 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: ColorHelper.appBarDark.withValues(alpha: 0.8)),
        ],
        borderRadius: BorderRadius.circular(15.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorHelper.red,
            ColorHelper.gradientColortop,
            ColorHelper.gradientColorbottom,
            ColorHelper.gradientColormiddle,
          ],
          stops: const [0.0, 0.45, 0.82, 1.0],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: ColorHelper.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TextHelper.provideInfoToReportAnIncident,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ColorHelper.textTertiary,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  color: ColorHelper.primaryLight.withValues(alpha: 0.3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TextHelper.confidenceLevel,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.textTertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                        Text(
                          '${confidenceLevel.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ColorHelper.textTertiary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: confidenceLevel / 100,
                      backgroundColor: ColorHelper.grey.withValues(alpha: 0.3),
                      color: ColorHelper.green,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unansweredQuestion == 0 
                        ? TextHelper.allPointsHaveBeenMentioned 
                        : '$unansweredQuestion ${TextHelper.questionNotAnswered}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: unansweredQuestion == 0 
                          ? ColorHelper.textTertiary 
                          : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              ...List.generate(incidentPoints.length, (index) {
                final point = incidentPoints[index];
                final example = examples.length > index ? examples[index] : "";

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              example,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: ColorHelper.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
