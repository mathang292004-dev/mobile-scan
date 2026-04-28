import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:flutter/material.dart';

class IncidentSummaryCard extends StatelessWidget {
  final String? summary;
  final bool isEditing;
  final TextEditingController? controller;
  final VoidCallback? onChanged;

  const IncidentSummaryCard({
    super.key,
    this.summary,
    this.isEditing = false,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: isEditing ? _buildEditView(context) : _buildDisplayView(context),
    );
  }

  Widget _buildDisplayView(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Icon(Icons.circle, size: 6, color: ColorHelper.black4),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            controller?.text ?? summary ?? 'No Summary Available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorHelper.black4,
                  fontSize: 14,
                  height: 1.7, // 24/14
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditView(BuildContext context) {
    return AppTextField(
      controller: controller,
      maxLines: 4,
      minLines: 2,
      hint: 'Enter incident summary...',
      fillColor: ColorHelper.white,
      onChanged: (value) {
        onChanged?.call();
      },
    );
  }
}
