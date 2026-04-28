import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/case_report/approver/widgets/tl_teams_tab.dart';
import 'package:emergex/presentation/case_report/approver/widgets/prepared_by_section.dart';
import 'package:emergex/presentation/case_report/approver/widgets/project_manager_section.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/assets_damage_section.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/muscle_picker_widget.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/property_damage_section.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/uploaded_files_section.dart';
import 'package:emergex/utils/map_utils.dart';
import 'package:flutter/material.dart';
import 'incident_approval_tab_bar.dart';

class IncidentApprovalWidget extends StatelessWidget {
  final IncidentDetails incident;
  final ValueChanged<int>? onTabChanged;
  final TabSize tabSize;
  final double? fixedTabWidth;
  final Widget Function(BuildContext, int, bool)? tabBuilder;
  final Widget? customTabBar;
  final int initialTabIndex;
  final bool isEditRequired;

  const IncidentApprovalWidget({
    super.key,
    required this.incident,
    this.onTabChanged,
    this.tabSize = TabSize.expanded,
    this.fixedTabWidth,
    this.tabBuilder,
    this.customTabBar,
    this.initialTabIndex = 0,
    this.isEditRequired = false,
  });
  Map<String, dynamic> _getAssetsDamage() {
    final raw = incident.incident is Map
        ? (incident.incident as Map)['assetsDamage']
        : null;
    if (raw is List) {
      // New API format: [{name, details}] → {name: details}
      return Map.fromEntries(
        raw.whereType<Map>().map(
          (e) => MapEntry(
            e['name']?.toString() ?? '',
            e['details']?.toString() ?? '',
          ),
        ),
      );
    }
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }

  Map<String, dynamic> _getPropertyDamage() {
    final raw = incident.incident is Map
        ? (incident.incident as Map)['propertyDamage']
        : null;
    if (raw is List) {
      // New API format: [{propertyType, description, price}] → wrap for widget
      return {'details': raw};
    }
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return CustomTabBar(
      key: const ValueKey('incident_approval_tabs'),
      tabs: const [
        TextHelper.information,
        TextHelper.uploads,
        TextHelper.teams,
      ],
      tabContents: [
        _buildBasicInformationTab(incident),
        _buildUploadsTab(context, incident),
        _buildTeamsTab(),
      ],
      onChanged: onTabChanged,
      tabSize: tabSize,
      fixedTabWidth: fixedTabWidth,
      tabBuilder: tabBuilder,
      customTabBar: customTabBar,
      initialIndex: initialTabIndex,
    );
  }

  Widget _buildBasicInformationTab(IncidentDetails incident) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MusclePickerWidget(injuredParts: getInjuredParts(incident)),
        const SizedBox(height: 16),
        AssetsDamageSection(
          incident: incident,
          assetsDamage: _getAssetsDamage(),
          isEditable: true,
        ),
        const SizedBox(height: 16),
        PropertyDamageSection(
          propertyDamage: _getPropertyDamage(),
          isEdit: true,
          incident: incident,
        ),
        const SizedBox(height: 16),
        ProjectManagerSection(incident: incident),
        const SizedBox(height: 16),
        PreparedBySection(
          key: const ValueKey('prepared_by'),
          incident: incident,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUploadsTab(BuildContext context, IncidentDetails incident) {
    return incident.uploadedFiles != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UploadedFilesSection(
                key: const ValueKey('uploaded_files'),
                uploadedFiles: incident.uploadedFiles!,
                isEditRequired: isEditRequired,
                incidentStatus: incident.adminStatus,
            enableAnimation: true,
              ),
              const SizedBox(height: 32),
            ],
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  TextHelper.noUploadedFilesAvailable,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
  }

  Widget _buildTeamsTab() {
    return TlTeamsTab(
      key: const ValueKey('tl_teams_tab'),
      incident: incident,
    );
  }
}
