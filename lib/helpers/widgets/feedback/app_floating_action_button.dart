import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget? child;
  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,

      backgroundColor: ColorHelper.successColor,
      shape: CircleBorder(),
      child: child ?? Image.asset(Assets.floatingActionButtonImage),
    );
  }
}
