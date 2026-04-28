import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';

class MovableFloatingButton extends StatefulWidget {
  final VoidCallback onPressed;

  const MovableFloatingButton({super.key, required this.onPressed});

  @override
  State<MovableFloatingButton> createState() => _MovableFloatingButtonState();
}

class _MovableFloatingButtonState extends State<MovableFloatingButton> {
  Offset position = Offset(0, 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = MediaQuery.of(context).size;

    if (position == Offset(0, 0)) {
      position = Offset(screenSize.width - 70, screenSize.height - 170);
    }
  }

  void _snapToEdge() {
    const double horizontalPadding = 10.0;
    const double fabSize = 50.0;
    final screenWidth = MediaQuery.of(context).size.width;

    double middle = screenWidth / 2;
    double targetX;

    if (position.dx + fabSize / 2 < middle) {
      targetX = horizontalPadding;
    } else {
      targetX = screenWidth - fabSize - horizontalPadding;
    }

    setState(() {
      position = Offset(targetX, position.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double topLimit =
        MediaQuery.of(context).padding.top + 60; // 10 px padding
    final double bottomLimit = screenSize.height - 70 - 100; // 70 = FAB size

    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                position += details.delta;

                // Clamp the vertical movement between topLimit and bottomLimit
                position = Offset(
                  position.dx,
                  position.dy.clamp(topLimit, bottomLimit),
                );
              });
            },

            onPanEnd: (details) {
              _snapToEdge();
            },
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: ColorHelper.successColor,
              shape: const CircleBorder(),
              child: Image.asset(Assets.floatingActionButtonImage),
            ),
          ),
        ),
      ],
    );
  }
}
