import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/case_report/approver/widgets/behavior_checklist_card.dart';
import 'package:emergex/presentation/case_report/utils/case_report_data_utils.dart';
import 'package:emergex/presentation/case_report/utils/case_report_edit_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/utils/map_utils.dart';
import 'package:flutter/material.dart';
import '../../../../generated/assets.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

class BehaviouralFullWidget extends StatefulWidget {
  final Map<String, dynamic> incidentMap;
  final String topKey;
  final bool singleTo;
  final String title;
  final bool isEditOption;
  final IncidentDetails incidentDetails;
  final String parentPath;
  final bool isEditRequired;

  const BehaviouralFullWidget({
    super.key,
    required this.incidentMap,
    required this.topKey,
    this.singleTo = true,
    this.title = TextHelper.criticalSafetyBehaviours,
    this.isEditOption = false,
    required this.incidentDetails,
    required this.parentPath,
    this.isEditRequired = true,
  });

  @override
  State<BehaviouralFullWidget> createState() => _BehaviouralFullWidgetState();
}

class _BehaviouralFullWidgetState extends State<BehaviouralFullWidget>
    with AutomaticKeepAliveClientMixin {
  late IncidentDetails _localIncidentData;
  final Map<String, GlobalKey<BehaviorChecklistCardState>> _cardKeys = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeLocalData();
    _initializeCardKeys();
  }

  @override
  void didUpdateWidget(covariant BehaviouralFullWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = AppDI.incidentDetailsCubit.state;
    final isEditing = state is IncidentDetailsLoaded
        ? (state.behaviouralFullWidgetEdit ?? false)
        : false;
    if (isEditing) {
      return;
    }
    if (widget.incidentDetails != oldWidget.incidentDetails ||
        widget.topKey != oldWidget.topKey) {
      _initializeLocalData();
      _initializeCardKeys();
    }
  }

  void _initializeLocalData() {
    _localIncidentData = deepCopyIncident(widget.incidentDetails);
  }

  void _initializeCardKeys() {
    _cardKeys.clear();
    final behaviourCheckList = _getCurrentBehaviourCheckList();
    for (String key in behaviourCheckList.keys) {
      _cardKeys[key] = GlobalKey<BehaviorChecklistCardState>();
    }
  }

  Map<String, dynamic> _getCurrentBehaviourCheckList() {
    final parentData = CaseReportDataUtils.getParentData(
      _localIncidentData,
      widget.parentPath,
    );
    return MapUtils.getMap(parentData, key: widget.topKey);
  }

  void _handleEdit() {
    if (CaseReportEditUtils.guardEditConflict(context)) return;
    AppDI.incidentDetailsCubit.setBehaviouralFullWidgetEdit(true);
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setBehaviouralFullWidgetEdit(false);
    _resetToOriginalData();
  }

  void _resetToOriginalData() {
    _initializeLocalData();
    for (var cardKey in _cardKeys.values) {
      cardKey.currentState?.resetToOriginalData();
    }
  }

  bool _hasDataChanged() {
    final originalBehaviorData = MapUtils.getMap(
      widget.incidentMap,
      key: widget.topKey,
    );

    final currentBehaviorData = _getCurrentBehaviourCheckList();

    if (currentBehaviorData.length != originalBehaviorData.length) {
      return true;
    }

    for (var entry in _cardKeys.entries) {
      final cardState = entry.value.currentState;
      if (cardState != null) {
        final updatedBehaviors = cardState.getUpdatedBehaviors();
        if (updatedBehaviors != null) {
          final originalBehaviors = originalBehaviorData[entry.key];

          final updatedJson = json.encode(updatedBehaviors);
          final originalJson = json.encode(originalBehaviors);

          if (updatedJson != originalJson) {
            return true;
          }
        }
      }
    }

    return false;
  }

  void _handleSave() {
    AppDI.incidentDetailsCubit.setBehaviouralFullWidgetEdit(false);
    if (!_hasDataChanged()) {
      return;
    }

    final Map<String, dynamic> updatedBehaviorData = {};

    for (var entry in _cardKeys.entries) {
      final cardState = entry.value.currentState;
      if (cardState != null) {
        final updatedBehaviors = cardState.getUpdatedBehaviors();
        if (updatedBehaviors != null) {
          updatedBehaviorData[entry.key] = updatedBehaviors;
        }
      }
    }
    _updateLocalDataStructure(updatedBehaviorData);
    _saveToServer();
  }

  void _checkDataChanged() {
    final hasChanged = _hasDataChanged();
    AppDI.incidentDetailsCubit.setBehaviouralFullWidgetEdit(hasChanged);
  }

  void _updateLocalDataStructure(Map<String, dynamic> updatedBehaviorData) {
    CaseReportDataUtils.updateBehaviouralDataStructure(
      _localIncidentData,
      widget.parentPath,
      widget.topKey,
      updatedBehaviorData,
    );
  }

  Future<void> _saveToServer() async {
    AppDI.incidentDetailsCubit.updateReportFields(_localIncidentData);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      bloc: AppDI.incidentDetailsCubit,
      builder: (context, state) {
        final isEditing = state is IncidentDetailsLoaded
            ? (state.behaviouralFullWidgetEdit ?? false)
            : false;

        final behaviourCheckList = _getCurrentBehaviourCheckList();

        return Container(
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: ColorHelper.surfaceColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: ColorHelper.surfaceColor, width: 1),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isEditing),
              const SizedBox(height: 8),
              if (behaviourCheckList.isEmpty)
                _buildNoDataCard()
              else
                ...behaviourCheckList.entries.map((entry) {
                  return BehaviorChecklistCard(
                    key: _cardKeys[entry.key],
                    title: entry.key,
                    behaviors: MapUtils.getBehaviorItems(entry.value),
                    showSafe: widget.singleTo,
                    isEditing: isEditing,
                    onChanged: _checkDataChanged,
                    originalBehaviors: MapUtils.getBehaviorItems(
                      MapUtils.getMap(
                            widget.incidentMap,
                            key: widget.topKey,
                          )[entry.key] ??
                          {},
                    ),
                  );
                }),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 16,
                color: ColorHelper.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (widget.isEditOption &&
            widget.isEditRequired &&
            widget.incidentDetails.adminStatus != 'ERT Assigned') ...[
          if (isEditing)
            _buildSaveCancelButtons()
          else if (_getCurrentBehaviourCheckList().isNotEmpty)
            _buildEditButton(),
        ],
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

  Widget _buildNoDataCard() {
    return Card(
      color: ColorHelper.white.withValues(alpha: 0.8),
      shadowColor: ColorHelper.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            TextHelper.noDataAvailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColorHelper.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
