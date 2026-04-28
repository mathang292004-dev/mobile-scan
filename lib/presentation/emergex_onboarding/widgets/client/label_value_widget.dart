import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class LabelValueWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool addColonToLabel;
  final Color? labelColor;
  final Color? valueColor;
  final TextStyle? valueTextStyle;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const LabelValueWidget({
    super.key,
    required this.label,
    required this.value,
    this.addColonToLabel = false,
    this.labelColor,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
    this.valueTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = addColonToLabel ? '$label:' : label;
    final defaultLabelColor = labelColor ?? ColorHelper.black;
    final defaultValueColor = valueColor ?? ColorHelper.black4;
    final defaultValueTextStyle = valueTextStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: defaultValueColor,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: defaultLabelColor,
          ),
        ),
        Text(
          value,
          style: defaultValueTextStyle,
        ),
      ],
    );
  }
}

