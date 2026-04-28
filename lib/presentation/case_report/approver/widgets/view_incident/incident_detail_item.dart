import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class DetailItem extends StatelessWidget {
  final String icon;
  final String value;
  final Color? valueColor;

  const DetailItem({
    super.key,
    required this.icon,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          icon,
          width: 14,
          height: 14,
          color: ColorHelper.textTertiary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColorHelper.textTertiary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
