import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/case_report/utils/case_report_edit_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter/material.dart';

/// Thin StatefulWidget — only manages TextEditingController lifecycle.
/// Edit state read from [IncidentDetailsCubit] via widget.state.additionalCommentsEdit.
/// Zero setState() calls.
class AdditionalComments extends StatefulWidget {
  final IncidentDetailsLoaded state;
  final bool isEditRequired;

  const AdditionalComments({
    super.key,
    required this.state,
    required this.isEditRequired,
  });

  @override
  State<AdditionalComments> createState() => _AdditionalCommentsState();
}

class _AdditionalCommentsState extends State<AdditionalComments> {
  final TextEditingController _controller = TextEditingController();
  String _originalValue = '';

  bool get _isEditing => widget.state.additionalCommentsEdit == true;

  @override
  void initState() {
    super.initState();
    _originalValue =
        widget.state.incident.intervention?['additionalComments'] ?? '';
    _controller.text = _originalValue;
  }

  @override
  void didUpdateWidget(covariant AdditionalComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing) return;
    if (widget.state.incident != oldWidget.state.incident) {
      _originalValue =
          widget.state.incident.intervention?['additionalComments'] ?? '';
      _controller.text = _originalValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleEdit() {
    if (CaseReportEditUtils.guardEditConflict(context)) return;
    AppDI.incidentDetailsCubit.setAdditionalCommentsEdit(true);
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setAdditionalCommentsEdit(false);
    _controller.text = _originalValue;
  }

  void _handleSave() {
    AppDI.incidentDetailsCubit.setAdditionalCommentsEdit(false);

    final currentValue = _controller.text.trim();
    if (currentValue == _originalValue) return;

    _originalValue = currentValue;

    if (widget.state.incident.intervention is Map) {
      final intervention = widget.state.incident.intervention as Map;
      intervention['additionalComments'] = currentValue;
    } else {
      widget.state.incident.intervention = {
        'additionalComments': currentValue,
      };
    }

    AppDI.incidentDetailsCubit.updateReportFields(widget.state.incident);
  }

  void _checkDataChanged() {
    final hasChanged = _controller.text.trim() != _originalValue;
    AppDI.incidentDetailsCubit.setAdditionalCommentsEdit(hasChanged);
  }

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      alpha: 0.6,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TextHelper.additionalComments,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ColorHelper.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.state.incident.adminStatus != 'ERT Assigned' &&
                  widget.isEditRequired) ...[
                if (_isEditing)
                  _buildSaveCancelButtons()
                else
                  _buildEditButton(),
              ],
            ],
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _controller,
            fillColor: ColorHelper.white,
            maxLines: 5,
            minLines: 5,
            hint: TextHelper.enterDetailsHere,
            enabled: _isEditing,
            onChanged: (value) {
              Future.microtask(() {
                if (mounted) _checkDataChanged();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveCancelButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: _handleCancel,
          icon: Icon(Icons.close, color: ColorHelper.textSecondary),
          tooltip: TextHelper.cancel,
        ),
        IconButton(
          onPressed: _handleSave,
          icon: Icon(Icons.check, color: ColorHelper.textSecondary),
          tooltip: TextHelper.save,
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      onPressed: _handleEdit,
      icon: Image.asset(Assets.reportApEdit, height: 20, width: 20),
      tooltip: TextHelper.edit,
    );
  }
}
