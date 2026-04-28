import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';

class ActionButtonsRow extends StatelessWidget {
  final String leftText;
  final String rightText;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;
  final Color leftTextColor;
  final List<Color> leftButtonColors;
  final List<Color> rightButtonColors;
  final Color rightTextColor;
  final bool isEnabled;

  const ActionButtonsRow({
    super.key,
    required this.leftText,
    required this.rightText,
    this.onLeftPressed,
    this.onRightPressed,
    this.leftTextColor = ColorHelper.primaryColor,
    this.rightTextColor = Colors.white,
    this.isEnabled = true,
    this.leftButtonColors = const [
      ColorHelper.surfaceColor,
      ColorHelper.surfaceColor,
    ],
    this.rightButtonColors = const [
      ColorHelper.primaryColor,
      ColorHelper.buttonColor,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        color: ColorHelper.surfaceColor.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: EmergexButton(
              onPressed: onLeftPressed,
              text: leftText,
              colors: leftButtonColors,
              textColor: leftTextColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5, // blur effect
              child: IgnorePointer(
                ignoring: !isEnabled, // disable interaction
                child: EmergexButton(
                  onPressed: onRightPressed,
                  text: rightText,
                  colors: rightButtonColors,
                  textColor: rightTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
