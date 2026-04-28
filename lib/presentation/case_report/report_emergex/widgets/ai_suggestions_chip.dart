import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/suggestion_tag_widget.dart';
import 'package:flutter/material.dart';

class AISuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;

  const AISuggestionsWidget({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TextHelper.aiSuggestions,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: ColorHelper.textPrimary),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 16,
              children: suggestions.map((suggestion) {
                Color backgroundColor;
                Color textColor;

                if (suggestion.contains(TextHelper.urgent)) {
                  backgroundColor = ColorHelper.urgentColor.withValues(
                    alpha: 0.6,
                  );
                  textColor = ColorHelper.urgentTextColor.withValues(
                    alpha: 0.76,
                  );
                } else if (suggestion.contains(TextHelper.tone)) {
                  backgroundColor = ColorHelper.toneColor.withValues(
                    alpha: 0.6,
                  );
                  textColor = ColorHelper.toneTextColor.withValues(alpha: 0.76);
                } else {
                  backgroundColor = ColorHelper.categoryColor.withValues(
                    alpha: 0.6,
                  );
                  textColor = ColorHelper.categoryTextColor;
                }
                return SuggestionTagWidget(
                  text: suggestion,
                  backgroundColor: backgroundColor,
                  textColor: textColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
