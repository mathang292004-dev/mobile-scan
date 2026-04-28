import 'dart:async';
import 'package:flutter/material.dart';

/// A reusable timer widget that displays elapsed time in HH:MM:SS format
/// and updates every second when shouldRun is true
class TimerWidget extends StatefulWidget {
  /// The initial duration to start the timer from
  final Duration startDuration;

  /// The color for the timer icon and text
  final Color timerColor;

  /// Whether the timer should actively run (increment every second)
  /// Set to false for paused tasks to show static time
  final bool shouldRun;

  /// Optional icon to display (defaults to Icons.hourglass_bottom)
  final String? iconAsset;

  /// Optional icon size (defaults to 16)
  final double? iconSize;

  /// Optional padding for the container
  final EdgeInsetsGeometry? padding;

  /// Optional border radius for the container (defaults to 20)
  final double? borderRadius;

  /// Optional border width (defaults to 1)
  final double? borderWidth;

  /// Optional background color for the container
  final Color? backgroundColor;

  /// Optional text style
  final TextStyle? textStyle;

  final bool showBorder;

  const TimerWidget({
    super.key,
    required this.startDuration,
    required this.timerColor,
    this.showBorder = true,
    this.shouldRun = true,
    this.iconAsset,
    this.iconSize,
    this.padding,
    this.borderRadius,
    this.borderWidth,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with AutomaticKeepAliveClientMixin {
  late Duration _duration;
  Timer? _timer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _duration = widget.startDuration;
    // Only start timer if shouldRun is true
    if (widget.shouldRun) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle shouldRun state changes
    if (widget.shouldRun != oldWidget.shouldRun) {
      if (widget.shouldRun) {
        // Resume timer
        _startTimer();
      } else {
        // Pause timer
        _stopTimer();
      }
    }

    // Update duration if startDuration changed
    if (widget.startDuration != oldWidget.startDuration) {
      setState(() {
        _duration = widget.startDuration;
      });
    }
  }

  void _startTimer() {
    // Cancel existing timer if any
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _duration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String get _formattedTime {
    final h = _twoDigits(_duration.inHours);
    final m = _twoDigits(_duration.inMinutes.remainder(60));
    final s = _twoDigits(_duration.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 20),
        border: widget.showBorder
            ? Border.all(
                color: widget.timerColor,
                width: widget.borderWidth ?? 1,
              )
            : null,
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
         widget.iconAsset != null
    ? Image.asset(
        widget.iconAsset!,
        width: widget.iconSize ?? 16,
        height: widget.iconSize ?? 16,
        color: widget.timerColor,
      )
    : Icon(
        Icons.hourglass_bottom,
        size: widget.iconSize ?? 16,
        color: widget.timerColor,
      ),

          const SizedBox(width: 6),
          Text(
            _formattedTime,
            style:
                widget.textStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.timerColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
