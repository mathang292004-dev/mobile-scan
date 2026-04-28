import 'package:flutter/material.dart';

/// WhatsApp-style typing indicator with animated dots
/// Displays "User is typing..." with animated bouncing dots
class TypingIndicatorWidget extends StatefulWidget {
  /// Map of userId -> userName for users currently typing
  final Map<String, String> typingUsers;

  const TypingIndicatorWidget({
    super.key,
    required this.typingUsers,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Create staggered animations for each dot
    _dot1Animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _dot2Animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _dot3Animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTypingText() {
    final users = widget.typingUsers.values.toList();

    if (users.isEmpty) return '';

    if (users.length == 1) {
      return '${users[0]} is typing';
    } else if (users.length == 2) {
      return '${users[0]} and ${users[1]} are typing';
    } else if (users.length == 3) {
      return '${users[0]}, ${users[1]}, and ${users[2]} are typing';
    } else {
      return '${users.length} people are typing';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Typing bubble with dots
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated dots
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDot(_dot1Animation.value),
                        const SizedBox(width: 3),
                        _buildDot(_dot2Animation.value),
                        const SizedBox(width: 3),
                        _buildDot(_dot3Animation.value),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Typing text
          Flexible(
            child: Text(
              _getTypingText(),
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double animationValue) {
    // Calculate bounce effect - goes up then down
    final bounceValue = animationValue <= 0.5
        ? animationValue * 2 // Going up (0 to 1)
        : 2 - (animationValue * 2); // Going down (1 to 0)

    final opacity = 0.6 + (0.4 * bounceValue);
    return Transform.translate(
      offset: Offset(0, -4 * bounceValue),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF3DA229).withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Simple typing indicator that shows just the text with animated dots
class SimpleTypingIndicator extends StatefulWidget {
  final String typingUserName;

  const SimpleTypingIndicator({
    super.key,
    required this.typingUserName,
  });

  @override
  State<SimpleTypingIndicator> createState() => _SimpleTypingIndicatorState();
}

class _SimpleTypingIndicatorState extends State<SimpleTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _dotCount = (_dotCount % 3) + 1;
          });
          _controller.reset();
          _controller.forward();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.typingUserName} is typing',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(
            width: 20,
            child: Text(
              '.' * _dotCount,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
