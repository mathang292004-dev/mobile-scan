import 'package:emergex/generated/assets.dart';
import 'package:flutter/material.dart';
class StatusSelector extends StatelessWidget {
  final bool isClickable;
  final VoidCallback? onPressed;

  const StatusSelector({
    super.key,
    this.isClickable = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      Assets.reportApEdit,
      width: 24,
      height: 24,
    );

    return isClickable
        ? GestureDetector(
      onTap: onPressed,
      child: image,
    )
        : image;
  }
}
