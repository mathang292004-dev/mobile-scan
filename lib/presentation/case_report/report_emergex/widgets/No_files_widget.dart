import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';

class NoFilesWidget extends StatelessWidget {
  final String? message;
  final String title;
  const NoFilesWidget({super.key, this.message, required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.white, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: ColorHelper.textSecondary),
          ),

          const SizedBox(height: 24),
          Image.asset(Assets.noFiles, height: 80, width: 80),
          Text(
            message ?? TextHelper.noFiles,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          message != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64.0,
                    vertical: 12,
                  ),
                  child: EmergexButton(
                    onPressed: () {},
                    text: TextHelper.recordAudio,
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}
