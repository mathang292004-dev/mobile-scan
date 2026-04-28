import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:emergex/utils/map_utils.dart';
import 'package:flutter/material.dart';

/// Pure data-extraction / transformation helpers for case_report.
///
/// No cubit or navigation dependencies — only reads from [IncidentDetails].
class CaseReportDataUtils {
  CaseReportDataUtils._();

  // ---------------------------------------------------------------------------
  // Incident field extractors
  // ---------------------------------------------------------------------------

  /// Extracts the `assetsDamage` map from the incident payload.
  /// Handles both the legacy nested-map format and the new top-level array
  /// format `[{name, details}]`, converting the latter to `{name: details}`.
  static Map<String, dynamic> getAssetsDamage(IncidentDetails incident) {
    final raw = incident.incident is Map
        ? (incident.incident as Map)['assetsDamage']
        : null;
    if (raw is List) {
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

  /// Extracts the `propertyDamage` map from the incident payload.
  /// Handles both the legacy wrapped format `{details: [...]}` and the new
  /// top-level array format `[{propertyType, description, price}]`.
  static Map<String, dynamic> getPropertyDamage(IncidentDetails incident) {
    final raw = incident.incident is Map
        ? (incident.incident as Map)['propertyDamage']
        : null;
    if (raw is List) {
      return {'details': raw};
    }
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }

  /// Extracts the `incidentOverview` map from the incident payload.
  static Map<String, dynamic> getIncidentOverview(IncidentDetails incident) {
    return MapUtils.getMap(
      incident.incident,
      path: ['incidentOverview'],
      defaultValue: {},
    );
  }

  /// Extracts the summary list from `incidentOverview.summary`.
  static List<String> getSummaries(IncidentDetails incident) {
    final summaryData = MapUtils.getDynamic(
      incident.incident,
      path: ['incidentOverview', 'summary'],
      defaultValue: [],
    );
    if (summaryData is List) {
      return summaryData.map((e) => e.toString()).toList();
    } else if (summaryData is String) {
      return summaryData.isEmpty ? [] : [summaryData];
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // Audio / file mapping
  // ---------------------------------------------------------------------------

  /// Converts uploaded audio files from [details] into [FileUploadItem] list.
  static List<FileUploadItem> mapRecordings(IncidentDetails? details) {
    if (details?.uploadedFiles?.audio == null) return [];
    return details!.uploadedFiles!.audio
        .map(
          (audio) => FileUploadItem(
            id: audio.key ?? UniqueKey().toString(),
            fileName: audio.fileName!,
            fileType: 'audio',
            key: audio.key,
            fileUrl: audio.fileUrl,
            filePath: audio.fileUrl!,
            fileSize: audio.fileSize,
            text: audio.text,
            infoId: audio.infoId,
          ),
        )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Incident data helpers for the safety-assessment flow
  // ---------------------------------------------------------------------------

  /// Creates a shallow deep-copy of [overview] (a single-level map).
  static Map<String, dynamic>? deepCopyOverview(dynamic overview) {
    if (overview == null) return null;
    final map = _toMap(overview);
    return Map<String, dynamic>.from(map);
  }

  static Map<String, dynamic> _toMap(dynamic obj) {
    if (obj == null) return {};
    if (obj is Map<String, dynamic>) return obj;
    if (obj is Map) return Map<String, dynamic>.from(obj);
    try {
      return obj.toJson() as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Updates the observation section of [localIncident] at [childKey].
  static void updateObservation(
    IncidentDetails localIncident,
    String childKey,
    Map<String, dynamic> data,
  ) {
    if (localIncident.observation is Map) {
      final observation = localIncident.observation as Map;
      observation[childKey] = data;
    } else {
      localIncident.observation = {childKey: data};
    }
  }

  /// Updates the intervention section of [localIncident] at [childKey].
  static void updateIntervention(
    IncidentDetails localIncident,
    String childKey,
    Map<String, dynamic> data,
  ) {
    if (localIncident.intervention is Map) {
      final intervention = localIncident.intervention as Map;
      intervention[childKey] = data;
    } else {
      localIncident.intervention = {childKey: data};
    }
  }

  /// Updates the local data structure for the behavioural full widget.
  static void updateBehaviouralDataStructure(
    IncidentDetails localIncident,
    String parentPath,
    String topKey,
    Map<String, dynamic> updatedBehaviorData,
  ) {
    switch (parentPath) {
      case 'intervention':
        localIncident.intervention ??= <String, dynamic>{};
        if (localIncident.intervention is Map<String, dynamic>) {
          final interventionMap =
              localIncident.intervention as Map<String, dynamic>;
          interventionMap[topKey] = updatedBehaviorData;
        }
        break;
      case 'observation':
        localIncident.observation ??= <String, dynamic>{};
        if (localIncident.observation is Map<String, dynamic>) {
          final observationMap =
              localIncident.observation as Map<String, dynamic>;
          observationMap[topKey] = updatedBehaviorData;
        }
        break;
      default:
        localIncident.incident ??= <String, dynamic>{};
        localIncident.incident![topKey] = updatedBehaviorData;
    }
  }

  /// Gets parent data map by [parentPath] from [localIncident].
  static Map<String, dynamic> getParentData(
    IncidentDetails localIncident,
    String parentPath,
  ) {
    switch (parentPath) {
      case 'intervention':
        return localIncident.intervention is Map<String, dynamic>
            ? localIncident.intervention as Map<String, dynamic>
            : {};
      case 'observation':
        return localIncident.observation is Map<String, dynamic>
            ? localIncident.observation as Map<String, dynamic>
            : {};
      default:
        return localIncident.incident ?? {};
    }
  }
}
