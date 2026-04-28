import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssetsDamageSection extends StatefulWidget {
  const AssetsDamageSection({
    super.key,
    this.incident,
    this.assetsDamage,
    this.isEditable = false,
    this.onSave,
  });

  final IncidentDetails? incident;
  final Map<String, dynamic>? assetsDamage;
  final bool isEditable;
  final Function(IncidentDetails updatedIncident)? onSave;

  @override
  State<AssetsDamageSection> createState() => _AssetsDamageSectionState();
}

class _AssetsDamageSectionState extends State<AssetsDamageSection> {
  IncidentDetails? _localIncidentData;

  // List-based storage: each item has 'name' and 'details' controllers.
  // This allows adding new rows with editable asset names.
  List<Map<String, TextEditingController>> _editableAssets = [];

  @override
  void initState() {
    super.initState();
    _initializeLocalData();
  }

  @override
  void didUpdateWidget(covariant AssetsDamageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cubitState = AppDI.incidentDetailsCubit.state;
    final isEditing = cubitState is IncidentDetailsLoaded &&
        (cubitState.assetsDamageEdit ?? false);
    if (isEditing) return;

    if (widget.assetsDamage != oldWidget.assetsDamage ||
        widget.incident != oldWidget.incident) {
      _disposeControllers();
      _initializeLocalData();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final item in _editableAssets) {
      item['name']?.dispose();
      item['details']?.dispose();
    }
    _editableAssets = [];
  }

  void _initializeLocalData() {
    _localIncidentData = widget.incident != null
        ? deepCopyIncident(widget.incident!)
        : null;
    _editableAssets = (widget.assetsDamage ?? {})
        .entries
        .map(
          (e) => {
            'name': TextEditingController(text: e.key),
            'details': TextEditingController(text: e.value.toString()),
          },
        )
        .toList();
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
    AppDI.incidentDetailsCubit.setAssetsDamageEdit(true);
  }

  void _handleCancel() {
    AppDI.incidentDetailsCubit.setAssetsDamageEdit(false);
    _disposeControllers();
    _initializeLocalData();
    setState(() {});
  }

  void _addNewAsset() {
    setState(() {
      _editableAssets.add({
        'name': TextEditingController(),
        'details': TextEditingController(),
      });
    });
    _checkDataChanged();
  }

  bool _hasDataChanged() {
    final original = widget.assetsDamage ?? {};
    if (_editableAssets.length != original.length) return true;
    for (int i = 0; i < _editableAssets.length; i++) {
      final currentName = _editableAssets[i]['name']!.text.trim();
      final currentDetails = _editableAssets[i]['details']!.text.trim();
      final originalEntries = original.entries.toList();
      if (i >= originalEntries.length) return true;
      if (currentName != originalEntries[i].key ||
          currentDetails != originalEntries[i].value.toString().trim()) {
        return true;
      }
    }
    return false;
  }

  void _handleSave() {
    AppDI.incidentDetailsCubit.setAssetsDamageEdit(false);
    if (_localIncidentData == null) return;
    if (!_hasDataChanged()) return;
    _saveToServer();
  }

  void _checkDataChanged() {
    final hasChanged = _hasDataChanged();
    AppDI.incidentDetailsCubit.setAssetsDamageEdit(hasChanged);
  }

  void _saveToServer() {
    final payload = {
      'caseId': _localIncidentData!.incidentId,
      'assetsDamage': _editableAssets
          .map(
            (item) => {
              'name': item['name']!.text.trim(),
              'details': item['details']!.text.trim(),
            },
          )
          .where((e) => (e['name'] as String).isNotEmpty)
          .toList(),
    };
    AppDI.incidentDetailsCubit.updateReportFieldsPayload(
      payload,
      incidentId: _localIncidentData!.incidentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
      bloc: AppDI.incidentDetailsCubit,
      buildWhen: (previous, current) {
        if (previous is IncidentDetailsLoaded &&
            current is IncidentDetailsLoaded) {
          return previous.assetsDamageEdit != current.assetsDamageEdit;
        }
        return false;
      },
      builder: (context, state) {
        final isEditing = state is IncidentDetailsLoaded &&
            (state.assetsDamageEdit ?? false);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: _buildContainerDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isEditing),
              const SizedBox(height: 16),
              _buildAssetDamageList(isEditing),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: ColorHelper.surfaceColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: ColorHelper.surfaceColor, width: 1),
    );
  }

  Widget _buildHeader(bool isEditing) {
    final canEdit = widget.incident?.adminStatus != 'ERT Assigned' &&
        widget.incident?.incidentStatus != 'Closed' &&
        widget.incident?.incidentStatus != 'Resolved';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          TextHelper.assetsDamage,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 16,
            color: ColorHelper.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (canEdit && widget.isEditable)
          isEditing ? _buildSaveCancelButtons() : _buildEditButton(),
      ],
    );
  }

  Widget _buildAssetDamageList(bool isEditing) {
    if (_editableAssets.isEmpty && !isEditing) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ListView.separated(
          itemCount: _editableAssets.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => isEditing
              ? _buildEditItem(index)
              : _buildDisplayItem(
                  title: _formatTitle(_editableAssets[index]['name']!.text),
                  value: _editableAssets[index]['details']!.text,
                ),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'No assets damage reported',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDisplayItem({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: ColorHelper.assetDamageCardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildItemIcon(),
          const SizedBox(width: 12),
          _buildItemContent(title, value),
        ],
      ),
    );
  }

  Widget _buildItemIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorHelper.white.withValues(alpha: 0.5),
      ),
      child: Image.asset(Assets.profileIcon, height: 16, width: 16),
    );
  }

  Widget _buildItemContent(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? 'Asset' : title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColorHelper.successColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'Not specified' : value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEditItem(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asset Name',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ColorHelper.black4,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
          AppTextField(
            controller: _editableAssets[index]['name']!,
            fillColor: ColorHelper.white.withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            onChanged: (_) => _checkDataChanged(),
          ),
          Text('Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ColorHelper.black4,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          AppTextField(
            controller: _editableAssets[index]['details']!,
            fillColor: ColorHelper.white.withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            maxLines: 4,
            onChanged: (_) => _checkDataChanged(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _addNewAsset,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: ColorHelper.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorHelper.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: ColorHelper.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Add Asset',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorHelper.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      onPressed: _handleEdit,
      icon: Image.asset(Assets.reportApEdit, height: 20, width: 20),
    );
  }

  Widget _buildSaveCancelButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: _addNewAsset,
          icon: Icon(Icons.add, color: ColorHelper.textSecondary),
        ),
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

  String _formatTitle(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}
