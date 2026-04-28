import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget {
  final ValueChanged<bool> handleToggle;
  final bool checked;
  final Color? knobColor;
  final Color innerCircleColor;
  final double size;
  final bool isEnabled;

  const ToggleButton({
    super.key,
    required this.handleToggle,
    required this.checked,
    this.knobColor,
    required this.innerCircleColor,
    this.size = 40.0, // Default size in logical pixels
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final double toggleWidth = size;
    final double toggleHeight = size / 2.0;

    final double knobSize = toggleWidth * 0.4;

    final double knobTranslate = toggleWidth - knobSize - 4.0;

    return GestureDetector(
      onTap: isEnabled ? () => handleToggle(!checked) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: toggleWidth,
        height: toggleHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(toggleHeight / 2),
          color: checked
              ? ColorHelper.primaryColor
              : ColorHelper.toggleUnchecked,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: checked ? knobTranslate : 2.0,
              top: (toggleHeight - knobSize) / 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checked
                      ? knobColor ?? ColorHelper.white
                      : ColorHelper.toggleBackground,
                  boxShadow: isEnabled
                      ? const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.2),
                            blurRadius: 3,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 1,
                          ),
                        ],
                ),
                child: Center(
                  child: Container(
                    width: knobSize * 0.5,
                    height: knobSize * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checked
                          ? innerCircleColor
                          : ColorHelper.toggleUnchecked,
                    ),
                  ),
                ),
              ),
            ),
            // Disabled overlay
            if (!isEnabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(toggleHeight / 2),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
