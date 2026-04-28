import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final TextStyle? textStyle;
  final bool? isEditable;
  final String? initialValue;
  final bool enabled;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final Widget? suffixIcon;
  final ScrollController? scrollController;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int minLines;
  final int? maxLength;
  final VoidCallback? onTap;
  final bool numericOnly;
  final bool readOnly;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final OutlineInputBorder? border;
  final bool dismissKeyboardOnTapOutside;

  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.textStyle,
    this.isEditable,
    this.initialValue,
    this.enabled = true,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffixIcon,
    this.scrollController,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength = 250,
    this.onTap,
    this.numericOnly = false,
    this.readOnly = false,
    this.contentPadding,
    this.fillColor,
    this.border,
    this.dismissKeyboardOnTapOutside = true,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController effectiveController =
        controller ?? TextEditingController(text: initialValue);

    return TextFormField(
      scrollController: scrollController,
      focusNode: focusNode,
      // selectionControls: NoHandleTextSelectionControls(),
      controller: effectiveController,
      enabled: isEditable ?? enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: null, // Set to null to hide counter
      onTap: onTap,
      onTapOutside: (event) {
        if (dismissKeyboardOnTapOutside) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      readOnly: readOnly,
      style: Theme.of(context).textTheme.bodyMedium,
      validator: validator,
      inputFormatters: [
        // Limit to maxLength characters
        LengthLimitingTextInputFormatter(maxLength),
        // Apply numeric-only filter if enabled
        if (numericOnly)
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*$'))
        else
          // Allow all Unicode characters including international languages
          FilteringTextInputFormatter.allow(
            RegExp(r'[\p{L}\p{N}\p{P}\p{S}\p{Z}]', unicode: true),
          ),
      ],
      onChanged: (value) {
        // Prevent space as first character (for non-numeric fields)
        if (!numericOnly && value.startsWith(" ")) {
          final cursorPosition = effectiveController.selection.baseOffset;
          final newText = value.trimLeft();
          effectiveController.text = newText;

          // Maintain cursor position, adjusting for removed spaces
          final newPosition = cursorPosition - (value.length - newText.length);
          effectiveController.selection = TextSelection.fromPosition(
            TextPosition(offset: newPosition.clamp(0, newText.length)),
          );
          return;
        }

        // Pass change to parent
        if (onChanged != null) {
          onChanged!(value);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: ColorHelper.grey),
        prefix: prefix,
        suffix: suffix,
        prefixIcon: prefixIcon,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        suffixIcon: suffixIcon,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: fillColor != null,
        fillColor: fillColor,
        border:
            border ??
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder:
            border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: ColorHelper.surfaceColor),
            ),
        focusedBorder:
            border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: ColorHelper.dateRangeGreen),
            ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ColorHelper.errorColor),
        ),
        errorStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: ColorHelper.errorColor),
        errorMaxLines: 3,
      ),
    );
  }
}

class NoHandleTextSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textHeight, [
    VoidCallback? onTap,
  ]) {
    return const SizedBox.shrink();
  }
}
