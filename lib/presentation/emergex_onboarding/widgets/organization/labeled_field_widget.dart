import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:flutter/material.dart';

/// Reusable labeled field widget for forms
class LabeledFieldWidget extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const LabeledFieldWidget({
    super.key,
    required this.label,
    required this.isRequired,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.suffixIcon,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.black4,
              ),
            ),
            if (isRequired)
              Text(
                "*",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorHelper.starColor,
                  fontSize: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        AppTextField(
          hint: hint,
          maxLines: maxLines,
          controller: controller,
          fillColor: ColorHelper.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: errorText != null
                  ? ColorHelper.starColor
                  : ColorHelper.surfaceColor,
            ),
          ),
          suffixIcon: suffixIcon,
          onChanged: onChanged,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColorHelper.starColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

