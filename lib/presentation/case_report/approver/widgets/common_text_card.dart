import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/toggle_button.dart';
import 'package:emergex/utils/map_utils.dart';
import 'package:emergex/utils/text_format.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class CommentsCard extends StatefulWidget {
  final TextEditingController controller;
  final bool isCommon;
  final String? title;
  final String? hint;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Color? color;
  final bool isEditRequired;
  final ValueChanged<bool>? onToggle;
  final bool isRecording;
  final bool reportIncident;
  final Map<String, dynamic>? othersMap;
  final bool? isOther;

  const CommentsCard({
    required this.controller,
    required this.isCommon,
    this.color,
    this.title,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.othersMap,
    this.isEditRequired = true,
    this.onToggle,
    this.isRecording = false,
    this.reportIncident = false,
    this.isOther = false,
    super.key,
  });

  @override
  State<CommentsCard> createState() => _CommentsCardState();
}

class _CommentsCardState extends State<CommentsCard> {
  late final ValueNotifier<bool> _switchNotifier;
  final ScrollController _scrollController = ScrollController();
  String? derivedKeyName;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();

    bool initialSwitchValue = false;

    if (widget.othersMap != null && widget.othersMap!.isNotEmpty) {
      derivedKeyName = widget.othersMap!.keys.first;

      final currentItem = MapUtils.getMap(
        widget.othersMap,
        key: derivedKeyName,
      );

      final actionTaken = currentItem['ActionTaken'];
      if (actionTaken is bool) {
        initialSwitchValue = actionTaken;
      }

      final description =
          currentItem['DescriptionOfIntervention']?.toString() ??
          currentItem['Description']?.toString() ??
          currentItem['Comment']?.toString() ??
          '';
      widget.controller.text = description;
    }

    _switchNotifier = ValueNotifier<bool>(initialSwitchValue);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _switchNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommentsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start auto-scroll when recording starts
    if (widget.isRecording && !oldWidget.isRecording) {
      _startAutoScroll();
    }
    // Stop auto-scroll when recording stops
    else if (!widget.isRecording && oldWidget.isRecording) {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();

    // Start a periodic timer that scrolls every 5 seconds
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.isRecording && mounted) {
        _scrollToEnd();
      } else {
        timer.cancel();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _scrollToEnd() {
    if (!mounted || !_scrollController.hasClients) return;

    try {
      // Animate to the bottom of the scroll view
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Also move cursor to end of text
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    } catch (e) {
      debugPrint('Scroll error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBackgroundColor = ColorHelper.surfaceColor;

    final String nonCommonTitleText =
        widget.title ?? derivedKeyName ?? 'Comments';
    final String commonTitleText = widget.title ?? 'Additional Comments';

    return AppContainer(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: widget.color ?? cardBackgroundColor.withValues(alpha: 0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.isCommon) ...[
            Text(
               commonTitleText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ColorHelper.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    TextFormat.getTextFormt(nonCommonTitleText),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColorHelper.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        'No',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ValueListenableBuilder<bool>(
                        valueListenable: _switchNotifier,
                        builder: (context, isSwitchEnabled, _) {
                          return ToggleButton(
                            isEnabled: widget.isEditRequired,
                            checked: isSwitchEnabled,
                            innerCircleColor: ColorHelper.successColor,
                            handleToggle: (value) {
                              _switchNotifier.value = value;
                              widget.onToggle?.call(value);
                            },
                            size: 55.0,
                          );
                        },
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Yes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
          ],
          !widget.isOther! ? AppTextField(
            readOnly: !widget.isEditRequired,
            controller: widget.controller,
            scrollController: _scrollController,
            maxLines: 5,
            minLines: 5,
            maxLength: widget.reportIncident ? 30000 : 250,
            hint: widget.hint,
            keyboardType: TextInputType.multiline,
            fillColor: Colors.white.withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.all(12.0),
            initialValue: widget.initialValue,
            onChanged: widget.onChanged,
          ):
           AppTextField(
            readOnly: !widget.isEditRequired,
            controller: widget.controller,
            maxLines: 5,
            minLines: 5,
            maxLength: widget.reportIncident ? 30000 : 250,
            hint: widget.hint,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.all(12.0),
            initialValue: widget.initialValue,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}
