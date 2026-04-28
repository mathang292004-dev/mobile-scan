import 'dart:convert';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/incident_details_card.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/incident_summary_card.dart';
import 'package:emergex/utils/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncidentOverviewDetails extends StatefulWidget {
  const IncidentOverviewDetails({
    super.key,
    this.incident,
    this.title,
    this.isEditOption = false,
    this.isEditRequired = true,
    this.onSave,
    this.rowSize = 1,
  });
  final IncidentDetails? incident;
  final bool isEditOption;
  final bool isEditRequired;
  final String? title;
  final Function(IncidentDetails updatedIncident)? onSave;
  final int? rowSize;
  @override
  State<IncidentOverviewDetails> createState() =>
      _IncidentOverviewDetailsState();
}

class _IncidentOverviewDetailsState extends State<IncidentOverviewDetails>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<IncidentDetailsCardState> _detailsCardKey =
      GlobalKey<IncidentDetailsCardState>();
  final List<TextEditingController> _summaryControllers = [];
  late final TextEditingController _immediateActionCtrl;
  IncidentDetails? _localIncidentData;
  bool _isSummaryExpanded = false;

  List<String> _flattenStringList(dynamic value) {
    final out = <String>[];

    void walk(dynamic v) {
      if (v == null) return;
      if (v is List) {
        for (final e in v) {
          walk(e);
        }
        return;
      }
      final s = v.toString().trim();
      if (s.isNotEmpty) out.add(s);
    }

    walk(value);
    return out;
  }

  List<String> _parseImmediateActionInput(String text) {
    final s = text.trim();
    if (s.isEmpty) return [];

    // If the field already contains a JSON-ish list string (e.g. "[a, b]" or
    // '["a","b"]'), decode and flatten to avoid sending nested lists.
    if (s.startsWith('[') && s.endsWith(']')) {
      try {
        final decoded = json.decode(s);
        final items = _flattenStringList(decoded);
        if (items.isNotEmpty) return items;
      } catch (_) {
        // Fall back to newline parsing below.
      }
    }

    return s
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // AppDI.incidentDetailsCubit.incidentOverEditMode(widget.isEditOption);
    _immediateActionCtrl = TextEditingController(
      text: widget.incident?.immediateAction ?? '',
    );
    _initializeLocalData();
    _initializeSummaryControllers();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  void didUpdateWidget(covariant IncidentOverviewDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isEditing = AppDI.incidentDetailsCubit.getIncidentOverEditMode();
    if (isEditing) {
      return;
    }
    if (widget.incident != oldWidget.incident) {
      _immediateActionCtrl.text = widget.incident?.immediateAction ?? '';
      _initializeLocalData();
      _initializeSummaryControllers();
    }
  }

  @override
  void dispose() {
    for (var controller in _summaryControllers) {
      controller.dispose();
    }
    _immediateActionCtrl.dispose();
    super.dispose();
  }

  void _initializeLocalData() {
    _localIncidentData = _deepCopyIncident(widget.incident);
  }

  void _initializeSummaryControllers() {
    for (var controller in _summaryControllers) {
      controller.dispose();
    }
    _summaryControllers.clear();
    final summaries = _getSummaries();
    for (var summary in summaries) {
      _summaryControllers.add(TextEditingController(text: summary));
    }
  }

  IncidentDetails? _deepCopyIncident(IncidentDetails? incident) {
    if (incident == null) return null;
    return IncidentDetails.fromJson(
      json.decode(json.encode(incident.toJson())),
    );
  }

  List<String> _getSummaries() {
    final summaryData = MapUtils.getDynamic(
      _getCurrentIncidentData(),
      path: ['incidentOverview', 'summary'],
      defaultValue: [],
    );
    if (summaryData is List) {
      return summaryData
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (summaryData is String) {
      final s = summaryData.trim();
      return (s.isEmpty || s == '[]') ? [] : [s];
    }
    return [];
  }

  Map<String, dynamic> _getIncidentOverview() {
    final overview = MapUtils.getMap(
      _getCurrentIncidentData(),
      path: ['incidentOverview'],
      defaultValue: {},
    );

    // Add incidentLevel field from the IncidentDetails model to incidentOverview for display
    final incidentLevel =
        _localIncidentData?.incidentLevel ?? widget.incident?.incidentLevel;
    if (incidentLevel != null && !overview.containsKey('incidentLevel')) {
      overview['incidentLevel'] = {
        'type': incidentLevel.type ?? 'Dropdown',
        'value': incidentLevel.value ?? 'low',
        '_id': '68f8fff1af36fd7e5b1b45b5',
      };
    }

    return overview;
  }

  Map<String, dynamic>? _getCurrentIncidentData() {
    return _localIncidentData?.incident ?? widget.incident?.incident;
  }

  void _toggleEditMode(bool isEditing) {
    AppDI.incidentDetailsCubit.incidentOverEditMode(isEditing);

    // Reset data changed flag when entering edit mode
    if (isEditing) {
      AppDI.incidentDetailsCubit.incidentOverviewEditMode(false);
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
    } else {
      AppDI.incidentDetailsCubit.incidentOverEditMode(true);
      _toggleEditMode(true);
    }
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.incidentOverviewEditMode(false);
    _resetToOriginalData();
    _toggleEditMode(false);
  }

  void _resetToOriginalData() {
    _immediateActionCtrl.text = widget.incident?.immediateAction ?? '';
    _initializeLocalData();
    _initializeSummaryControllers();
  }

  bool _hasDataChanged(Map<String, dynamic> updatedDetailsData) {
    // Get current summary texts
    final currentSummaries = _summaryControllers
        .map((controller) => controller.text)
        .where((text) => text.isNotEmpty)
        .toList();

    // Get original summaries from widget (current state)
    final originalSummaryData = MapUtils.getDynamic(
      widget.incident?.incident,
      path: ['incidentOverview', 'summary'],
      defaultValue: [],
    );

    List<String> originalSummaries = [];
    if (originalSummaryData is List) {
      originalSummaries = originalSummaryData.map((e) => e.toString()).toList();
    } else if (originalSummaryData is String &&
        originalSummaryData.isNotEmpty) {
      originalSummaries = [originalSummaryData];
    }

    // Check if summaries changed
    if (currentSummaries.length != originalSummaries.length) {
      return true;
    }
    for (int i = 0; i < currentSummaries.length; i++) {
      if (currentSummaries[i] != originalSummaries[i]) {
        return true;
      }
    }

    // Get original incident overview from widget (current state)
    final originalOverview = MapUtils.getMap(
      widget.incident?.incident,
      path: ['incidentOverview'],
      defaultValue: {},
    );

    // Check if immediateAction changed
    if (_immediateActionCtrl.text != (widget.incident?.immediateAction ?? '')) {
      return true;
    }

    // Compare each field in updatedDetailsData with original
    for (var key in updatedDetailsData.keys) {
      final currentValue = updatedDetailsData[key];

      // Special handling for incidentLevel - compare with IncidentDetails model
      if (key == 'incidentLevel') {
        final originalIncidentLevel = widget.incident?.incidentLevel;
        final originalValue = originalIncidentLevel?.value;

        if (currentValue != originalValue) {
          return true;
        }
      } else {
        final originalValue = originalOverview[key];

        if (currentValue != originalValue) {
          return true;
        }
      }
    }

    return false;
  }

  void _showNoChangesError() {
    _toggleEditMode(false);
  }

  void _handleSave() {
    AppDI.incidentDetailsCubit.incidentOverviewEditMode(false);
    final updatedDetailsData = _detailsCardKey.currentState?.getUpdatedData();
    if (updatedDetailsData == null || _localIncidentData?.incident == null) {
      return;
    }

    // Check if data has changed
    if (!_hasDataChanged(updatedDetailsData)) {
      _showNoChangesError();
      return;
    }

    _updateIncidentOverview(updatedDetailsData);
    _saveToServer(updatedDetailsData);
    _toggleEditMode(false);
  }

  void _checkDataChanged() {
    final updatedDetailsData = _detailsCardKey.currentState?.getUpdatedData();
    if (updatedDetailsData != null) {
      final hasChanged = _hasDataChanged(updatedDetailsData);
      AppDI.incidentDetailsCubit.incidentOverviewEditMode(hasChanged);
    }
  }

  void _updateIncidentOverview(Map<String, dynamic> updatedDetailsData) {
    final summaryTexts = _summaryControllers
        .map((controller) => controller.text)
        .where((text) => text.isNotEmpty)
        .toList();

    // Remove incidentLevel from updatedDetailsData before adding to incidentOverview
    final updatedDetailsWithoutIncidentLevel = Map<String, dynamic>.from(
      updatedDetailsData,
    );
    updatedDetailsWithoutIncidentLevel.remove('incidentLevel');

    final updatedIncidentOverview = {
      'summary': summaryTexts,
      ...updatedDetailsWithoutIncidentLevel,
    };
    _localIncidentData!.incident['incidentOverview'] = updatedIncidentOverview;

    // Update incidentLevel in the IncidentDetails model if it exists in updatedDetailsData
    if (updatedDetailsData.containsKey('incidentLevel')) {
      if (_localIncidentData!.incidentLevel == null) {
        _localIncidentData!.incidentLevel = IncidentLevel(
          type: 'Dropdown',
          value: updatedDetailsData['incidentLevel'],
        );
      } else {
        _localIncidentData!.incidentLevel!.value =
            updatedDetailsData['incidentLevel'];
      }
    }
  }

  Future<void> _saveToServer(Map<String, dynamic> updatedDetailsData) async {
    final summaryList = _summaryControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final immediateActionList = _parseImmediateActionInput(
      _immediateActionCtrl.text,
    );

    // Fields from the details card (category, classification, location, etc.)
    // excluding incidentLevel which is handled separately.
    final caseSummaryFields = Map<String, dynamic>.from(updatedDetailsData)
      ..remove('incidentLevel');

    final payload = {
      'caseId': _localIncidentData!.incidentId,
      'reportedBy': _localIncidentData!.reportedBy,
      'reportedDate': _localIncidentData!.reportedDate,
      'immediateAction': immediateActionList,
      'emergexCaseSummary': {'summary': summaryList, ...caseSummaryFields},
    };

    AppDI.incidentDetailsCubit.updateReportFieldsPayload(
      payload,
      incidentId: _localIncidentData!.incidentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      bloc: AppDI.incidentDetailsCubit,
      builder: (context, state) {
        final isEditing = state is IncidentDetailsLoaded
            ? (state.incidentOverEdit ?? false)
            : false;

        return AppContainer(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          radius: 20,
          child: Column(
            children: [
              _buildHeader(isEditing),
              _buildSummaryCards(isEditing),
              const SizedBox(height: 8),
              if (isEditing ||
                  (widget.incident?.immediateAction != null &&
                      widget.incident!.immediateAction!.trim().isNotEmpty &&
                      widget.incident!.immediateAction!.trim() != '[]'))
                AppContainer(
                  color: ColorHelper.white.withValues(alpha: 0.8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Immediate Action Taken',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: ColorHelper.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (isEditing)
                        AppTextField(
                          controller: _immediateActionCtrl,
                          maxLines: 4,
                          minLines: 2,
                          hint: 'Enter immediate action taken...',
                          fillColor: ColorHelper.white,
                          onChanged: (_) => _checkDataChanged(),
                        )
                      else
                        Text(
                          widget.incident?.immediateAction ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ColorHelper.textQuaternary),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              _buildDetailsCard(isEditing),
            ],
          ),
        );
      },
    );
  }

  bool get _isEditAllowed {
    final status = widget.incident?.incidentStatus;
    final isClosedOrResolved = status == 'Closed' || status == 'Resolved';

    if (isClosedOrResolved) {
      return false;
    }

    return widget.isEditRequired &&
        widget.incident?.adminStatus != 'ERT Assigned';
  }

  Widget _buildHeader(bool isEditing) {
    return Row(
      children: [
        Text(
          widget.title ?? TextHelper.emergeXCaseOverview,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 16,
            color: ColorHelper.black4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (_isEditAllowed) ...[
          if (isEditing)
            _buildSaveCancelButtons()
          else if (_getIncidentOverview().isNotEmpty)
            _buildEditButton(),
        ],
      ],
    );
  }

  Widget _buildSummaryCards(bool isEditing) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                TextHelper.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorHelper.black4,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _summaryControllers.isEmpty
              ? Text(
                  'No Summary Available',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor:
                              _isSummaryExpanded ||
                                  (_summaryControllers.length <= 1 &&
                                      (_summaryControllers.isEmpty ||
                                          _summaryControllers[0].text.length <=
                                              100))
                              ? 1.0
                              : 0.4,
                          child: Column(
                            children: List.generate(
                              _summaryControllers.length,
                              (index) {
                                return IncidentSummaryCard(
                                  summary: widget.incident != null
                                      ? _getSummaries().length > index
                                            ? _getSummaries()[index]
                                            : ''
                                      : '',
                                  isEditing: isEditing,
                                  controller: _summaryControllers[index],
                                  onChanged: _checkDataChanged,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_summaryControllers.length > 1 ||
                        (_summaryControllers.isNotEmpty &&
                            _summaryControllers[0].text.length > 100))
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isSummaryExpanded = !_isSummaryExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isSummaryExpanded
                                      ? 'Read Less'
                                      : 'Read More',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ColorHelper.primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isSummaryExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: ColorHelper.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isEditing) {
    return IncidentDetailsCard(
      key: _detailsCardKey,
      incidentOverview: _getIncidentOverview(),
      isEditing: isEditing,
      rowSize: widget.rowSize ?? 1,
      onChanged: _checkDataChanged,
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
}
