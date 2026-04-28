import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class AppContainer extends StatelessWidget {
  final Widget child;

  /// Outer margin. Defaults to none.
  final EdgeInsetsGeometry? margin;

  /// Override width. Defaults to `double.infinity`.
  final double? width;

  /// Override padding. Defaults to `EdgeInsets.symmetric(vertical: 24, horizontal: 16)`.
  final EdgeInsetsGeometry? padding;

  /// Provide a fully-computed color to override `surfaceColor.withValues(alpha: alpha)`.
  final Color? color;

  /// Alpha applied to `ColorHelper.surfaceColor` when [color] is null. Defaults to `0.5`.
  final double alpha;

  /// Border radius. Defaults to `24`.
  final double radius;

  /// Border width. Defaults to `1`.
  final double borderWidth;

  const AppContainer({
    super.key,
    required this.child,
    this.margin,
    this.width,
    this.padding,
    this.color,
    this.alpha = 0.5,
    this.radius = 24,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      margin: margin,
      padding: padding ??
          const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: color ?? ColorHelper.surfaceColor.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: ColorHelper.surfaceColor,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}
