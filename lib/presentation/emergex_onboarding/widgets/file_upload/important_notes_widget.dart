import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

/// Important Notes Widget
class ImportantNotesWidget extends StatelessWidget {
  const ImportantNotesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE8).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ColorHelper.importantNoteRound, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TextHelper.importantNotesTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorHelper.importantNoteRound,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            TextHelper.importantNotes,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: ColorHelper.importantNoteDescription,
            ),
          ),
        ],
      ),
    );
  }
}

