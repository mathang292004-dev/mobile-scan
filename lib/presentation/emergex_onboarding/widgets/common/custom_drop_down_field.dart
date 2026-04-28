import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String hintText;
  final T? value;
  final List<T> items;
  final Function(T?) onChanged;
  final double borderRadius;
  final Color? fillColor;
  final Color? iconColor;
  final double fieldHeight;

  /// Optional override for the display label of each item.
  /// The item value is unchanged — only what the user sees is affected.
  final String Function(T)? labelBuilder;

  const CustomDropdownField({
    super.key,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.borderRadius = 50,
    this.fillColor,
    this.iconColor,
    this.fieldHeight = 30,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return DropdownButtonHideUnderline(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: fillColor ?? ColorHelper.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              icon: Icon(
                Icons.keyboard_arrow_down_sharp,
                color: iconColor ?? ColorHelper.primaryColor,
              ),
              hint: Text(
                hintText,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: ColorHelper.grey),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth - 60),
                        child: Text(
                          labelBuilder != null ? labelBuilder!(item) : item.toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              borderRadius: BorderRadius.all(Radius.circular(16)),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
