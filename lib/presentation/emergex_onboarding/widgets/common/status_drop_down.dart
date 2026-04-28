import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class StatusDropdownField extends StatefulWidget {
  final List<String> statusOptions;
  final String? selectedStatus;
  final ValueChanged<String?> onChanged;

  const StatusDropdownField({
    super.key,
    required this.statusOptions,
    this.selectedStatus,
    required this.onChanged,
  });

  @override
  State<StatusDropdownField> createState() => _StatusDropdownFieldState();
}

class _StatusDropdownFieldState extends State<StatusDropdownField> {
  late String? selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
            color: ColorHelper.dateStatusColor,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          readOnly: true,
          controller: TextEditingController(text: selectedStatus ?? ''),
          decoration: InputDecoration(
            hintText: "Select Status",
            suffixIcon: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                icon: const Icon(
                  Icons.keyboard_arrow_down_sharp,
                  color: ColorHelper.primaryColor,
                ),
                value: selectedStatus,
                items: widget.statusOptions
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                  widget.onChanged(value);
                },
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
