import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

class ImmediateActionsWidget extends StatefulWidget {
  final Color? backgroundColor;

  const ImmediateActionsWidget({super.key, this.backgroundColor});

  @override
  State<ImmediateActionsWidget> createState() => _ImmediateActionsWidgetState();
}

class _ImmediateActionsWidgetState extends State<ImmediateActionsWidget> {
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _isExpanded.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    FocusScope.of(context).unfocus();
    _isExpanded.value = !_isExpanded.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? ColorHelper.surfaceColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorHelper.white),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _toggleExpansion,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          TextHelper.immediateActionsTaken,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: ColorHelper.textSecondary,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          TextHelper.optional,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColorHelper.tertiaryColor,
                                    fontSize: 14,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isExpanded,
                    builder: (context, isExpanded, child) {
                      return AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: ColorHelper.tertiaryColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isExpanded,
              builder: (context, isExpanded, child) {
                return AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorHelper.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextFormField(
                        controller: _controller,
                        maxLines: 8,
                        minLines: 6,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          AppDI.incidentFileHandleCubit
                              .updateImmediateActions(value);
                        },
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: ColorHelper.textSecondary,
                              fontSize: 12,
                            ),
                        decoration: InputDecoration(
                          hintText: TextHelper.describeImmediateActions,
                          hintStyle:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColorHelper.tertiaryColor,
                                    fontSize: 12,
                                  ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: ColorHelper.primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                  sizeCurve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
