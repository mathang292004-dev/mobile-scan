import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class EmergexButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? width;
  final double height = 40;
  final String? text;
  final List<Color>? colors;
  final Color? textColor;
  final double? borderRadius;
  final int? textSize;
  final FontWeight? fontWeight;
  final Widget? leadingIcon;
  final double? buttonHeight;
  final bool? disabled;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double? borderWidth;

  const EmergexButton({
    super.key,
    this.onPressed,
    this.width,
    this.text,
    this.colors,
    this.textColor,
    this.borderRadius,
    this.textSize = 12,
    this.fontWeight,
    this.leadingIcon,
    this.buttonHeight,
    this.disabled,
    this.borderColor,
    this.boxShadow,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? 12);

    return Container(
      width: width,
      height: buttonHeight ?? height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: disabled == true
              ? [
                  ColorHelper.buttonColor.withValues(alpha: 0.3),
                  ColorHelper.buttonColor.withValues(alpha: 0.3),
                ]
              : colors ??
                  [ColorHelper.primaryColor, ColorHelper.buttonColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: boxShadow,
        border: Border.all(
          color: disabled == true
              ? (borderColor ?? ColorHelper.primaryColor)
                  .withValues(alpha: 0.3)
              : (borderColor ?? ColorHelper.primaryColor),
          width: borderWidth ?? 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled == true ? null : onPressed,
          borderRadius: radius,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) leadingIcon!,
                  if (leadingIcon != null) const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor ?? Colors.white,
                            fontSize: textSize?.toDouble(),
                            fontWeight:
                                fontWeight ?? FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

