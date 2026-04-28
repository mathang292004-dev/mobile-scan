import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

/// Custom Checkbox Widget
/// Three states: unchecked, checked, and partial (minus icon)
enum CheckboxState { unchecked, checked, partial }

class CustomCheckboxWidget extends StatelessWidget {
  final CheckboxState state;
  final ValueChanged<CheckboxState>? onChanged;

  const CustomCheckboxWidget({
    super.key,
    required this.state,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          // Cycle through states: unchecked -> checked -> partial -> unchecked
          CheckboxState newState;
          switch (state) {
            case CheckboxState.unchecked:
              newState = CheckboxState.checked;
              break;
            case CheckboxState.checked:
              newState = CheckboxState.unchecked;
              break;
            case CheckboxState.partial:
              newState = CheckboxState.unchecked;
              break;
          }
          onChanged!(newState);
        }
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(
            color: _getBorderColor(),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _getIcon(),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (state) {
      case CheckboxState.checked:
        return ColorHelper.primaryColor;
      case CheckboxState.partial:
        return const Color(0xFFFFF9FA);
      case CheckboxState.unchecked:
        return Colors.transparent;
    }
  }

  Color _getBorderColor() {
    switch (state) {
      case CheckboxState.checked:
        return ColorHelper.primaryColor;
      case CheckboxState.partial:
      case CheckboxState.unchecked:
        return const Color(0xFFFF3C56);
    }
  }

  Widget? _getIcon() {
    switch (state) {
      case CheckboxState.checked:
        return const Icon(
          Icons.check,
          size: 14,
          color: Colors.white,
        );
      case CheckboxState.partial:
        return const Icon(
          Icons.remove,
          size: 14,
          color: Color(0xFFFF3C56),
        );
      case CheckboxState.unchecked:
        return null;
    }
  }
}
