import 'package:flutter/material.dart';

class UnfocusOnScrollWrapper extends StatefulWidget {
  final Widget child;

  const UnfocusOnScrollWrapper({
    super.key,
    required this.child,
  });

  @override
  State<UnfocusOnScrollWrapper> createState() => _UnfocusOnScrollWrapperState();
}

class _UnfocusOnScrollWrapperState extends State<UnfocusOnScrollWrapper> {
  bool _hasUnfocused = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollUpdateNotification) {
          final isUserScrolling = scrollNotification.dragDetails != null;

          if (isUserScrolling &&
              !_hasUnfocused &&
              scrollNotification.scrollDelta != null &&
              scrollNotification.scrollDelta!.abs() > 3.0) {
            final FocusScopeNode currentFocus = FocusScope.of(context);
            if (currentFocus.hasFocus && currentFocus.focusedChild != null) {
              _hasUnfocused = true;
              currentFocus.unfocus();
            }
          }
        } else if (scrollNotification is ScrollEndNotification) {
          _hasUnfocused = false;
        }
        return false;
      },
      child: widget.child,
    );
  }
}
