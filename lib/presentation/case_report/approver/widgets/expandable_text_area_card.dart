import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:flutter/material.dart';

import '../../../../generated/color_helper.dart';
import '../../../../helpers/text_helper.dart';

class ExpandableTextAreaCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? initialText;
  final String? originalText;
  final bool isEditing;
  final VoidCallback? onChanged;
  final bool? isIncidentReport;
  final IncidentDetails? incidentDetails;
  final int index;

  const ExpandableTextAreaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.initialText,
    this.originalText,
    this.isEditing = false,
    this.onChanged,
    this.isIncidentReport = false,
    this.incidentDetails,
    required this.index,
  });

  @override
  State<ExpandableTextAreaCard> createState() => ExpandableTextAreaCardState();
}

class ExpandableTextAreaCardState extends State<ExpandableTextAreaCard> {
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant ExpandableTextAreaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText) {
      _textEditingController.text = widget.initialText ?? '';
    }
  }

  @override
  void dispose() {
    _isExpanded.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    FocusScope.of(context).unfocus();
    _isExpanded.value = !_isExpanded.value;
  }

  String getText() {
    return _textEditingController.text;
  }

  void resetToOriginalData() {
    _textEditingController.text = widget.originalText ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorHelper.surfaceColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleExpansion,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontSize: 14),
                        ),
                    ],
                  ),
                ),
                if (widget.isIncidentReport!) _buildViewDeleteButton(),
                ValueListenableBuilder<bool>(
                  valueListenable: _isExpanded,
                  builder: (context, isExpanded, child) {
                    return AnimatedRotation(
                      turns: isExpanded ? 0.0 : 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_up,
                        size: 28,
                        color: Colors.black54,
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
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _buildTextArea(),
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
    );
  }

  Widget _buildViewDeleteButton() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final infoId = widget
                .incidentDetails
                ?.emergeXCaseInformations?[widget.index]
                .infoId;
            final fileType = widget
                .incidentDetails
                ?.emergeXCaseInformations?[widget.index]
                .text;
            bool isAudioAvailable =
                widget.incidentDetails?.uploadedFiles?.audio.any(
                  (audio) => audio.infoId == infoId,
                ) ??
                false;
            if (infoId != null && fileType != null) {
              showErrorDialog(
                context,
                () {
                  AppDI.incidentFileHandleCubit.deleteFileFromServer(
                    infoId,
                    fileType,
                    false,
                  );
                  back();
                },
                () {
                  back();
                },
                TextHelper.areYouSure,
                isAudioAvailable
                    ? TextHelper
                          .deletingThisEmergeXCaseInformationWillAlsoRemoveItsLinkedAudioFile
                    : TextHelper.areYouSureYouWantToDeleteThisFile,
                TextHelper.yes,
                TextHelper.no,
              );
            }
          },
          icon: Image.asset(
            Assets.reportIncidentRecycleBin,
            height: 20,
            width: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: _textEditingController,
        enabled: widget.isEditing,
        maxLines: !widget.isEditing ? null : 5,
        minLines: 5,
        keyboardType: TextInputType.multiline,
        onChanged: (value) {
          widget.onChanged?.call();
        },
        decoration: InputDecoration(
          hintText: TextHelper.enterDetailsHere,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: ColorHelper.primaryColor),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
