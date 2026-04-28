import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class PageNumberButton extends StatelessWidget {
  final int pageNumber;
  final bool isActive;
  final VoidCallback onTap;

  const PageNumberButton({
    super.key,
    required this.pageNumber,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ColorHelper.white : ColorHelper.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$pageNumber',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColorHelper.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}