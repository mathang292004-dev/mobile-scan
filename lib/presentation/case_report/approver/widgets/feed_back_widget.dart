import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/case_report/approver/widgets/expandable_text_area_card.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/no_files_widget.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import '../../../../generated/assets.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeedbackWidget extends StatefulWidget {
  final dynamic feedback;
  final String? title;
  final IncidentDetails incidentDetails;
  final String parentPath;
  final String feedbackKey;
  final bool? isExpandable;
  final bool isEditRequired;
  final bool? isIncidentReport;

  const FeedbackWidget({
    super.key,
    required this.feedback,
    this.title,
    required this.incidentDetails,
    required this.parentPath,
    required this.feedbackKey,
    this.isExpandable,
    this.isEditRequired = true,
    this.isIncidentReport,
  });

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget>
    with AutomaticKeepAliveClientMixin {
  late IncidentDetails _localIncidentData;
  final Map<String, GlobalKey<ExpandableTextAreaCardState>> _cardKeys = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeLocalData();
    _initializeCardKeys();
  }

  @override
  void didUpdateWidget(covariant FeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = AppDI.incidentDetailsCubit.state;
    final isEditing = state is IncidentDetailsLoaded
        ? (state.feedbackWidgetEdit ?? false)
        : false;
    if (isEditing) {
      return;
    }

    final currentFeedback = _getCurrentFeedbackData();
    final oldFeedback = oldWidget.feedback;

    if (widget.feedbackKey != oldWidget.feedbackKey ||
        widget.parentPath != oldWidget.parentPath ||
        _hasFeedbackDataChanged(currentFeedback, oldFeedback)) {
      _initializeLocalData();
      _initializeCardKeys();
    } else if (widget.incidentDetails != oldWidget.incidentDetails) {
      _initializeLocalData();
    }
  }

  bool _hasFeedbackDataChanged(dynamic current, dynamic old) {
    if (current == null && old == null) return false;
    if (current == null || old == null) return true;

    if (current is Map && old is Map) {
      if (current.length != old.length) return true;
      for (var key in current.keys) {
        if (current[key]?.toString() != old[key]?.toString()) {
          return true;
        }
      }
      return false;
    } else if (current is List && old is List) {
      if (current.length != old.length) return true;
      for (int i = 0; i < current.length; i++) {
        final currentItem = current[i];
        final oldItem = old[i];
        if (currentItem is String && oldItem is String) {
          if (currentItem != oldItem) return true;
        } else if (currentItem is EmergeXCaseInformation &&
            oldItem is EmergeXCaseInformation) {
          if (currentItem.text != oldItem.text) return true;
        } else if (currentItem?.toString() != oldItem?.toString()) {
          return true;
        }
      }
      return false;
    }

    return current.toString() != old.toString();
  }

  void _initializeLocalData() {
    _localIncidentData = deepCopyIncident(widget.incidentDetails);
  }

  void _initializeCardKeys() {
    _cardKeys.clear();
    final feedbackData = _getCurrentFeedbackData();

    if (feedbackData is Map<String, dynamic>) {
      for (String key in feedbackData.keys) {
        _cardKeys[key] = GlobalKey<ExpandableTextAreaCardState>();
      }
    } else if (feedbackData is List) {
      for (int i = 0; i < feedbackData.length; i++) {
        _cardKeys['item_$i'] = GlobalKey<ExpandableTextAreaCardState>();
      }
    }
  }

  dynamic _getCurrentFeedbackData() {
    final parentData = _getParentData();
    return parentData[widget.feedbackKey];
  }

  Map<String, dynamic> _getParentData() {
    switch (widget.parentPath) {
      case 'intervention':
        return _localIncidentData.intervention is Map<String, dynamic>
            ? _localIncidentData.intervention as Map<String, dynamic>
            : {};
      default:
        return _localIncidentData.incident ?? {};
    }
  }

  void _handleEdit() {
    if (AppDI.incidentDetailsCubit.isAnyEditActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please save or cancel current edits first'),
          backgroundColor: ColorHelper.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    AppDI.incidentDetailsCubit.setFeedbackWidgetEdit(true);
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setFeedbackWidgetEdit(false);
    _resetToOriginalData();
  }

  void _resetToOriginalData() {
    _initializeLocalData();
    for (var cardKey in _cardKeys.values) {
      cardKey.currentState?.resetToOriginalData();
    }
  }

  bool _hasDataChanged() {
    final currentData = _getCurrentFeedbackData();
    final originalData = widget.feedback;

    if (currentData is Map && originalData is Map) {
      if (currentData.length != originalData.length) {
        return true;
      }
    } else if (currentData is List && originalData is List) {
      if (currentData.length != originalData.length) {
        return true;
      }
    }

    for (var entry in _cardKeys.entries) {
      final cardState = entry.value.currentState;
      if (cardState != null) {
        final currentValue = cardState.getText();
        final originalValue = _getOriginalValue(entry.key);

        if (currentValue != originalValue) {
          return true;
        }
      }
    }

    return false;
  }

  String? _getOriginalValue(String key) {
    final originalData = widget.feedback;
    if (originalData is Map) {
      return originalData[key]?.toString();
    } else if (originalData is List) {
      final index = int.tryParse(key.replaceAll('item_', '')) ?? 0;
      if (index < originalData.length) {
        final item = originalData[index];
        if (item is String) {
          return item;
        } else if (item is EmergeXCaseInformation) {
          return item.text;
        }
      }
    }
    return null;
  }

  void _handleSave() {
    AppDI.incidentDetailsCubit.setFeedbackWidgetEdit(false);
    if (!_hasDataChanged()) {
      return;
    }

    final dynamic updatedFeedbackData = _collectUpdatedData();
    _updateLocalDataStructure(updatedFeedbackData);
    _saveToServer();
  }

  void _checkDataChanged() {
    final hasChanged = _hasDataChanged();
    AppDI.incidentDetailsCubit.setFeedbackWidgetEdit(hasChanged);
  }

  dynamic _collectUpdatedData() {
    final currentData = _getCurrentFeedbackData();
    if (currentData is Map<String, dynamic>) {
      final Map<String, dynamic> updatedData = {};
      for (var entry in _cardKeys.entries) {
        final cardState = entry.value.currentState;
        if (cardState != null) {
          updatedData[entry.key] = cardState.getText();
        }
      }
      return updatedData;
    } else if (currentData is List) {
      final List<String> updatedData = [];
      for (var entry in _cardKeys.entries) {
        final cardState = entry.value.currentState;
        if (cardState != null) {
          updatedData.add(cardState.getText());
        }
      }
      return updatedData;
    }

    return currentData;
  }

  void _updateLocalDataStructure(dynamic updatedFeedbackData) {
    switch (widget.parentPath) {
      case 'intervention':
        _localIncidentData.intervention ??= <String, dynamic>{};
        if (_localIncidentData.intervention is Map<String, dynamic>) {
          final interventionMap =
              _localIncidentData.intervention as Map<String, dynamic>;
          interventionMap[widget.feedbackKey] = updatedFeedbackData;
        }
        break;
      default:
        _localIncidentData.incident ??= <String, dynamic>{};
        _localIncidentData.incident![widget.feedbackKey] = updatedFeedbackData;
    }
  }

  Future<void> _saveToServer() async {
    AppDI.incidentDetailsCubit.updateReportFields(_localIncidentData);
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceFirst(key[0], key[0].toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      bloc: AppDI.incidentDetailsCubit,
      builder: (context, state) {
        final isEditing = state is IncidentDetailsLoaded
            ? (state.feedbackWidgetEdit ?? false)
            : false;

        final feedbackData = _getCurrentFeedbackData() ?? widget.feedback;

        if (feedbackData == null ||
            (feedbackData is Map && feedbackData.isEmpty) ||
            (feedbackData is List && feedbackData.isEmpty)) {
          return const NoFilesWidget(title: TextHelper.incidentComments);
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: ColorHelper.surfaceColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: ColorHelper.surfaceColor, width: 1),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isEditing),
              const SizedBox(height: 16),
              _buildFeedbackContent(feedbackData, isEditing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title ?? TextHelper.feedback,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: ColorHelper.textSecondary),
          ),
        ),
        if (widget.isEditRequired && (widget.isExpandable ?? true))
          if (isEditing) _buildSaveCancelButtons() else _buildEditButton(),
      ],
    );
  }

  Widget _buildSaveCancelButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: _handleCancel,
          icon: Icon(Icons.close, color: ColorHelper.textSecondary),
        ),
        IconButton(
          onPressed: _handleSave,
          icon: Icon(Icons.check, color: ColorHelper.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      onPressed: _handleEdit,
      icon: Image.asset(Assets.reportApEdit, height: 20, width: 20),
    );
  }

  Widget _buildFeedbackContent(dynamic feedbackData, bool isEditing) {
    if (feedbackData is Map<String, dynamic> && feedbackData.isNotEmpty) {
      return Column(
        children: feedbackData.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final mapEntry = entry.value;
          return Column(
            children: [
              ExpandableTextAreaCard(
                key: _cardKeys[mapEntry.key],
                title: _formatKey(mapEntry.key),
                initialText: mapEntry.value?.toString(),
                isEditing: isEditing,
                onChanged: _checkDataChanged,
                originalText: widget.feedback != null && widget.feedback is Map
                    ? widget.feedback[mapEntry.key]?.toString()
                    : null,
                index: index,
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      );
    } else if (feedbackData is List && feedbackData.isNotEmpty) {
      return Column(
        children: feedbackData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final keyName = 'item_$index';

          return Column(
            children: [
              ExpandableTextAreaCard(
                key: _cardKeys[keyName],
                title: "${TextHelper.incidentInformation} - ${index + 1}",
                initialText: (item is String
                    ? item.toString()
                    : item is EmergeXCaseInformation
                        ? item.text
                        : null),
                isEditing: isEditing,
                onChanged: _checkDataChanged,
                originalText: widget.feedback != null &&
                        widget.feedback is List &&
                        index < widget.feedback.length
                    ? (widget.feedback[index] is String
                        ? widget.feedback[index]?.toString()
                        : widget.feedback[index] != null &&
                                widget.feedback[index] is EmergeXCaseInformation
                            ? (widget.feedback[index] as EmergeXCaseInformation)
                                .text
                            : null)
                    : null,
                isIncidentReport: widget.isIncidentReport,
                incidentDetails: widget.incidentDetails,
                index: index,
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }
}
