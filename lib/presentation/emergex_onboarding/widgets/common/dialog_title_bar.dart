import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class DialogTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const DialogTitleBar({super.key, required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: ColorHelper.black4,
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              border: Border.all(color: ColorHelper.primaryColor, width: 1.5),
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(
              Icons.close,
              color: ColorHelper.primaryColor,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
