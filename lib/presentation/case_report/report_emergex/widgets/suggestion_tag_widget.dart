import 'package:flutter/material.dart';

class SuggestionTagWidget extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const SuggestionTagWidget({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
        ),
      ),
    );
  }
}
