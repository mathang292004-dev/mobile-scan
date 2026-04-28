import 'package:flutter/material.dart';

/// A small circular indicator showing online/offline status
/// Green dot for online, red dot for offline
class OnlineStatusIndicator extends StatelessWidget {
  /// Whether the user is online
  final bool isOnline;

  /// Size of the indicator dot (default: 8.0)
  final double size;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF51EB5C) : const Color(0xFFFF3C56),
        shape: BoxShape.circle,
      ),
    );
  }
}
