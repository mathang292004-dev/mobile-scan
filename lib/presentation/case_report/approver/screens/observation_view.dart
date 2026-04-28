import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/case_report/utils/case_report_edit_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/presentation/case_report/approver/screens/incident_action_buttons.dart';
import 'package:emergex/presentation/case_report/approver/widgets/behavioural_full_widget.dart';
import 'package:emergex/presentation/case_report/approver/widgets/behavioural_safety_assessment.dart';
import 'package:emergex/presentation/case_report/approver/widgets/common_text_card.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_approval_tab_bar.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:flutter/material.dart';

class ObservationView extends StatefulWidget {
  final IncidentDetailsLoaded state;
  final String? incidentId;
  final String selectedView;
  final bool isEditRequired;

  const ObservationView({
    super.key,
    required this.state,
    this.incidentId,
    required this.selectedView,
    this.isEditRequired = true,
  });

  @override
  State<ObservationView> createState() => _ObservationViewState();
}

/// Thin StatefulWidget — only manages TextEditingController lifecycle.
/// All business logic delegated to [IncidentDetailsCubit].
/// Zero setState() calls.
class _ObservationViewState extends State<ObservationView> {
  late IncidentDetails _localIncidentData;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, bool> _toggleStates = {};

  bool get _isEditing => widget.state.observationViewEdit == true;

  @override
  void initState() {
    super.initState();
    _initializeLocalData();
    _initializeTextControllers();
  }

  @override
  void didUpdateWidget(covariant ObservationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing) return;
    if (widget.state.incident != oldWidget.state.incident) {
      _initializeLocalData();
      _initializeTextControllers();
    }
  }

  void _initializeLocalData() {
    _localIncidentData = deepCopyIncident(widget.state.incident);
  }

  void _initializeTextControllers() {
    final othersMap = getMapCaseInsensitive(
      widget.state.incident.observation,
      'others',
    );

    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    _toggleStates.clear();

    for (String key in othersMap.keys) {
      final item = othersMap[key];
      if (item is Map) {
        final description =
            item['DescriptionOfIntervention']?.toString() ??
            item['Description']?.toString() ??
            item['Comment']?.toString() ??
            '';
        _textControllers[key] = TextEditingController(text: description);

        final actionTaken = item['ActionTaken'];
        _toggleStates[key] = actionTaken is bool ? actionTaken : false;
      }
    }
  }

  void _handleEdit() {
    if (CaseReportEditUtils.guardEditConflict(context)) return;
    AppDI.incidentDetailsCubit.setObservationViewEdit(true);
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setObservationViewEdit(false);
    _initializeLocalData();
    _initializeTextControllers();
  }

  bool _hasDataChanged() {
    final originalOthersMap = getMapCaseInsensitive(
      widget.state.incident.observation,
      'others',
    );
    return CaseReportEditUtils.hasObservationOthersChanged(
      textControllers: _textControllers,
      toggleStates: _toggleStates,
      originalOthersMap: originalOthersMap,
    );
  }

  void _handleSave() {
    AppDI.incidentDetailsCubit.setObservationViewEdit(false);

    if (!_hasDataChanged()) return;

    final originalOthersMap = getMapCaseInsensitive(
      widget.state.incident.observation,
      'others',
    );
    final updatedOthersData = CaseReportEditUtils.buildUpdatedOthersData(
      textControllers: _textControllers,
      toggleStates: _toggleStates,
      originalOthersMap: originalOthersMap,
    );

    if (updatedOthersData.isNotEmpty) {
      CaseReportEditUtils.mergeObservationOthers(
        _localIncidentData,
        updatedOthersData,
      );
      AppDI.incidentDetailsCubit.updateReportFields(_localIncidentData);
    }
  }

  void _checkDataChanged() {
    final hasChanged = _hasDataChanged();
    AppDI.incidentDetailsCubit.setObservationViewEdit(hasChanged);
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final othersMap = getMapCaseInsensitive(
      widget.state.incident.observation,
      'others',
    );

    return RefreshIndicator(
      onRefresh: () async {
        bool hasChanged = await AppDI.incidentDetailsCubit.checkDataChanged();
        if (hasChanged && context.mounted) {
          showErrorDialog(
            context,
            () async {
              back();
              AppDI.incidentDetailsCubit.clearCache();
              if (widget.incidentId != null && widget.incidentId!.isNotEmpty) {
                await AppDI.incidentDetailsCubit.getIncidentById(
                  widget.incidentId!,
                );
              }
            },
            () => back(),
            TextHelper.areYouSureYouWantToCancelEditedText,
            '',
            TextHelper.yesCancel,
            TextHelper.goBack,
          );
          return;
        }
        AppDI.incidentDetailsCubit.clearCache();
        if (widget.incidentId != null && widget.incidentId!.isNotEmpty) {
          await AppDI.incidentDetailsCubit.getIncidentById(
            widget.incidentId!,
          );
        }
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        children: [
          BehaviouralSafetyAssessment(
            key: const Key('behavioural_safety'),
            incident: widget.state.incident,
            incidentOverview: widget.state.incident.observation is Map
                ? (widget.state.incident.observation as Map)['HSEQObservation']
                : null,
            dataPath: DataPath(
              parentKey: 'observation',
              childKey: 'HSEQObservation',
            ),
            isEditRequired: widget.isEditRequired,
          ),
          const SizedBox(height: 16),
          CustomTabBar(
            tabs: [
              TextHelper.behaviorChecklist,
              TextHelper.criticalSafetyBehaviours,
              TextHelper.others,
            ],
            tabContents: [
              BehaviouralFullWidget(
                incidentMap: widget.state.incident.observation is Map
                    ? widget.state.incident.observation as Map<String, dynamic>
                    : {},
                topKey: 'behaviourChecklist',
                title: TextHelper.behaviorChecklist,
                isEditOption: true,
                incidentDetails: widget.state.incident,
                parentPath: 'observation',
                isEditRequired: widget.isEditRequired,
              ),
              BehaviouralFullWidget(
                incidentMap: widget.state.incident.observation is Map
                    ? widget.state.incident.observation as Map<String, dynamic>
                    : {},
                topKey: 'conditionsChecklist',
                isEditOption: true,
                title: TextHelper.criticalSafetyBehaviours,
                incidentDetails: widget.state.incident,
                parentPath: 'observation',
                isEditRequired: widget.isEditRequired,
              ),
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorHelper.surfaceColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: ColorHelper.surfaceColor, width: 1),
                ),
                child: Column(
                  children: [
                    _buildOthersHeader(othersMap),
                    const SizedBox(height: 8),
                    if (othersMap.isEmpty)
                      _buildNoDataCard()
                    else
                      ...othersMap.entries.map((entry) {
                        if (!_textControllers.containsKey(entry.key)) {
                          final item = entry.value;
                          if (item is Map) {
                            final description =
                                item['DescriptionOfIntervention']?.toString() ??
                                item['Description']?.toString() ??
                                item['Comment']?.toString() ??
                                '';
                            _textControllers[entry.key] = TextEditingController(
                              text: description,
                            );
                            final actionTaken = item['ActionTaken'];
                            _toggleStates[entry.key] = actionTaken is bool
                                ? actionTaken
                                : false;
                          }
                        }

                        final controller = _textControllers[entry.key]!;
                        return CommentsCard(
                          key: ValueKey(entry.key),
                          controller: controller,
                          isCommon: false,
                          isOther: true,
                          othersMap: {entry.key: entry.value},
                          isEditRequired: _isEditing,
                          isRecording: false,
                          onChanged: (value) => _checkDataChanged(),
                          onToggle: (value) {
                            _toggleStates[entry.key] = value;
                            _checkDataChanged();
                          },
                        );
                      }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.state.incident.adminStatus != 'ERT Assigned' &&
              widget.state.incident.adminStatus != 'Resolved' &&
              widget.state.incident.adminStatus != 'Closed' &&
              widget.isEditRequired)
            IncidentActionButtons(
              incidentId: widget.state.incident.incidentId,
              selectedView: widget.selectedView,
            ),
        ],
      ),
    );
  }

  Widget _buildOthersHeader(Map<String, dynamic> othersMap) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Others',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 16,
                color: ColorHelper.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (widget.isEditRequired &&
            widget.state.incident.adminStatus != 'ERT Assigned' &&
            othersMap.isNotEmpty) ...[
          if (_isEditing) _buildSaveCancelButtons() else _buildEditButton(),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
          ),
        ),
      ),
    );
  }
}
