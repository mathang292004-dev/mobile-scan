import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';

class ClientActionButtons extends StatelessWidget {
  final String primaryText;
  final String secondaryText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool? isPrimaryDisabled;
  final bool showPrimaryButton;
  final bool showSecondaryButton;

  const ClientActionButtons({
    super.key,
    required this.primaryText,
    required this.secondaryText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.isPrimaryDisabled,
    this.showPrimaryButton = true,
    this.showSecondaryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showPrimaryButton)
          EmergexButton(
            onPressed: onPrimaryPressed,
            disabled: isPrimaryDisabled ?? false,
            text: primaryText,
            leadingIcon: primaryText != 'Edit'
                ? Image.asset(Assets.reuplaodIcon, height: 24, width: 24)
                : null,
            borderRadius: 24,
            textColor: ColorHelper.primaryColor,
            fontWeight: FontWeight.w600,
            colors: [
              ColorHelper.surfaceColor.withValues(alpha: 0.1),
              ColorHelper.surfaceColor.withValues(alpha: 0.1),
            ],
          ),
        if (showPrimaryButton && showSecondaryButton) const SizedBox(width: 10),
        if (showSecondaryButton)
          EmergexButton(
            onPressed: onSecondaryPressed,
            text: secondaryText,
            disabled: primaryText == TextHelper.reupload,
            textColor: ColorHelper.white,
            fontWeight: FontWeight.w600,
            borderRadius: 24,
          ),
      ],
    );
  }
}
