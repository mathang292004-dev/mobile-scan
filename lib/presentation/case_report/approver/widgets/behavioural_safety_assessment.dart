import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/case_report/utils/case_report_data_utils.dart';
import 'package:emergex/presentation/case_report/utils/case_report_edit_utils.dart';
import 'package:emergex/presentation/case_report/utils/case_report_formatter_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/incident_details_card.dart';
import 'package:flutter/material.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DataPath {
  final String parentKey;
  final String childKey;

  const DataPath({required this.parentKey, required this.childKey});
}

class BehaviouralSafetyAssessment extends StatefulWidget {
  const BehaviouralSafetyAssessment({
    super.key,
    this.incident,
    this.incidentOverview,
    this.dataPath,
    this.onSave,
    this.isEditRequired = true,
  });

  final IncidentDetails? incident;
  final dynamic incidentOverview;
  final DataPath? dataPath;
  final bool isEditRequired;
  final Function(IncidentDetails updatedIncident)? onSave;

  @override
  State<BehaviouralSafetyAssessment> createState() =>
      _BehaviouralSafetyAssessmentState();
}

class _BehaviouralSafetyAssessmentState
    extends State<BehaviouralSafetyAssessment>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<IncidentDetailsCardState> _cardKey =
      GlobalKey<IncidentDetailsCardState>();

  IncidentDetails? _localIncidentData;
  Map<String, dynamic>? _localIncidentOverview;

  @override
  void initState() {
    super.initState();
    _initializeLocalData();
  }

  @override
  void didUpdateWidget(covariant BehaviouralSafetyAssessment oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isEditing =
        AppDI.incidentDetailsCubit.getBehaviouralSafetyAssessmentEditMode();
    if (isEditing) {
      return;
    }
    if (widget.incident != oldWidget.incident ||
        widget.incidentOverview != oldWidget.incidentOverview) {
      _initializeLocalData();
    }
  }

  void _initializeLocalData() {
    _localIncidentData = widget.incident != null
        ? deepCopyIncident(widget.incident!)
        : null;
    _localIncidentOverview = CaseReportDataUtils.deepCopyOverview(
      widget.incidentOverview,
    );
  }

  bool _hasDataChanged(Map<String, dynamic> updatedData) {
    final originalData = widget.incidentOverview;
    if (originalData == null) return true;

    for (var key in updatedData.keys) {
      final currentValue = updatedData[key];
      final originalValue = originalData is Map ? originalData[key] : null;

      if (currentValue != originalValue) {
        return true;
      }
    }

    return false;
  }

  void _onSaveChanges() {
    AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEditMode(false);
    final updatedData = _cardKey.currentState?.getUpdatedData();
    if (updatedData == null ||
        _localIncidentData == null ||
        widget.dataPath == null) {
      return;
    }

    if (!_hasDataChanged(updatedData)) {
      AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEdit(false);
      return;
    }

    _updateLocalOverview(updatedData);
    _updateIncidentData();
    _saveToServer();
    AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEdit(false);
  }

  void _checkDataChanged() {
    final updatedData = _cardKey.currentState?.getUpdatedData();
    if (updatedData != null) {
      final hasChanged = _hasDataChanged(updatedData);
      AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEditMode(hasChanged);
    }
  }

  void _updateLocalOverview(Map<String, dynamic> updatedData) {
    if (_localIncidentOverview != null) {
      _localIncidentOverview!.addAll(updatedData);
    } else {
      _localIncidentOverview = Map<String, dynamic>.from(updatedData);
    }
  }

  void _updateIncidentData() {
    final dataPath = widget.dataPath!;
    final updatedData = _localIncidentOverview!;

    switch (dataPath.parentKey) {
      case 'observation':
        CaseReportDataUtils.updateObservation(
          _localIncidentData!,
          dataPath.childKey,
          updatedData,
        );
        break;
      case 'intervention':
        CaseReportDataUtils.updateIntervention(
          _localIncidentData!,
          dataPath.childKey,
          updatedData,
        );
        break;
      default:
        debugPrint('Unknown dataPath parentKey: ${dataPath.parentKey}');
    }
  }

  Future<void> _saveToServer() async {
    AppDI.incidentDetailsCubit.updateReportFields(_localIncidentData);
  }

  void _onCancelChanges() {
    AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEditMode(false);
    _initializeLocalData();
    AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEdit(false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      bloc: AppDI.incidentDetailsCubit,
      builder: (context, state) {
        final isEditing = state is IncidentDetailsLoaded
            ? (state.behaviouralSafetyAssessmentEdit ?? false)
            : false;

        return AppContainer(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          alpha: 0.4,
          radius: 20,
          child: Column(
            children: [
              _buildHeader(isEditing),
              const SizedBox(height: 8),
              _buildDetailsCard(isEditing),
              const SizedBox(height: 16),
              _buildAdminSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Row(
      children: [
        Text(
          TextHelper.behaviouralSafetyAssessment,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 16,
            color: ColorHelper.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.isEditRequired &&
            widget.incident?.adminStatus != 'ERT Assigned') ...[
          if (isEditing)
            _buildSaveCancelButtons()
          else if (_localIncidentOverview?.isNotEmpty ?? false)
            _buildEditButton(),
        ],
      ],
    );
  }

  Widget _buildDetailsCard(bool isEditing) {
    final hasData = _localIncidentOverview != null &&
        _localIncidentOverview!.isNotEmpty &&
        _hasMeaningfulData(_localIncidentOverview!);
    if (!hasData) {
      return _buildNoDataCard();
    }

    return IncidentDetailsCard(
      key: _cardKey,
      incidentOverview: _localIncidentOverview,
      isEditing: isEditing,
      rowSize: 1,
      onChanged: _checkDataChanged,
    );
  }

  bool _hasMeaningfulData(Map<String, dynamic> data) {
    return CaseReportFormatterUtils.hasMeaningfulData(data);
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

  Widget _buildAdminSection() {
    final state = AppDI.incidentDetailsCubit.state;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorHelper.adminCardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin use only',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: ColorHelper.green),
          ),
          const SizedBox(height: 8),
          Text(
            'EmergeX Case Number : ${(state as IncidentDetailsLoaded).incident.emergexCaseNumber ?? '--'}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: ColorHelper.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveCancelButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: _onCancelChanges,
          icon: Icon(Icons.close, color: ColorHelper.textSecondary),
        ),
        IconButton(
          onPressed: _onSaveChanges,
          icon: Icon(Icons.check, color: ColorHelper.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      onPressed: () {
        if (CaseReportEditUtils.guardEditConflict(context)) return;
        AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEditMode(true);
        AppDI.incidentDetailsCubit.behaviouralSafetyAssessmentEdit(true);
      },
      icon: Image.asset(Assets.reportApEdit, height: 20, width: 20),
    );
  }
}
