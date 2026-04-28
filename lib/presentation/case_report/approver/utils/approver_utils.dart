import 'dart:convert';

import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/utils/case_report_formatter_utils.dart';
import 'package:emergex/utils/map_utils.dart';

/// Reloads the dashboard incident list preserving active filters.
///
/// Used after approval/cancel actions to keep the dashboard in sync.
void performDashboardSearch() {
  final currentState = AppDI.dashboardCubit.state;
  if (currentState is DashboardLoaded) {
    final daterange = CaseReportFormatterUtils.buildDateRangeMap(
      currentState.fromDate,
      currentState.toDate,
    );

    AppDI.dashboardCubit.loadIncidents(
      page: 1,
      limit: 10,
      incidentStatus: currentState.incidentStatus,
      daterange: daterange,
      selectedMetricIndex: currentState.selectedMetricIndex,
    );
  } else {
    AppDI.dashboardCubit.loadIncidents(
      page: 1,
      limit: 10,
      selectedMetricIndex: 0,
    );
  }
}

/// Finds [targetKey] in [map] using case-insensitive comparison.
///
/// Returns the actual key from the map, or `null` if not found.
String? findCaseInsensitiveKey(Map<dynamic, dynamic>? map, String targetKey) {
  if (map == null) return null;
  final lowerTarget = targetKey.toLowerCase();
  for (var key in map.keys) {
    if (key is String && key.toLowerCase() == lowerTarget) {
      return key;
    }
  }
  return null;
}

/// Gets a value from [map] using case-insensitive key lookup.
dynamic getValueCaseInsensitive(dynamic map, String key) {
  if (map is! Map) return null;
  final foundKey = findCaseInsensitiveKey(map, key);
  if (foundKey == null) return null;
  return map[foundKey];
}

/// Gets a nested map from [map] using case-insensitive key lookup.
///
/// Returns an empty map if the key is not found or the value is not a Map.
Map<String, dynamic> getMapCaseInsensitive(dynamic map, String key) {
  if (map is! Map) return {};
  final foundKey = findCaseInsensitiveKey(map, key);
  if (foundKey == null) return {};
  final value = map[foundKey];
  if (value is Map) {
    try {
      return value.cast<String, dynamic>();
    } catch (e) {
      return {};
    }
  }
  return {};
}

/// Creates a deep copy of [incident] via JSON round-trip.
IncidentDetails deepCopyIncident(IncidentDetails incident) {
  final copiedMap =
      json.decode(json.encode(incident.toJson())) as Map<String, dynamic>;
  return IncidentDetails.fromJson(copiedMap);
}

/// Extracts injured person data from the incident for the muscle picker.
List<Map<String, dynamic>> getInjuredParts(IncidentDetails incident) {
  final allInjuriesData = MapUtils.getList<Map<String, dynamic>>(
    incident.incident,
    path: ['overallInjuries'],
    defaultValue: [],
  );

  if (allInjuriesData.isEmpty) return [];

  return allInjuriesData.map((personData) {
    return {
      'injuriedPersonName':
          personData['injuriedPersonName::'] ??
          personData['injuriedPersonName'],
      'injuriedPersonId': personData['injuriedPersonId'],
      'injuries': personData['injuries'] ?? [],
    };
  }).toList();
}

/// Checks whether all tasks in an incident are complete.
///
/// Returns `true` if any task group has status 'Inprogress' but an empty taskList.
bool hasIncompleteTasks(IncidentDetails? incident) {
  if (incident?.task == null) return false;
  for (var taskGroup in incident!.task!) {
    final status = taskGroup['status'] ?? '';
    final taskList = taskGroup['taskList'] as List<dynamic>? ?? [];
    if (status == 'Inprogress' && taskList.isEmpty) {
      return true;
    }
  }
  return false;
}
