import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:flutter/material.dart';

/// Shared edit-mode utilities for case_report widgets.
///
/// Common patterns for inline edit/save/cancel flows.
class CaseReportEditUtils {
  CaseReportEditUtils._();

  /// Shows a snack bar warning that another edit is in progress.
  ///
  /// Returns `true` if an edit was already active (and the snack bar was shown),
  /// `false` otherwise.
  static bool guardEditConflict(BuildContext context) {
    if (AppDI.incidentDetailsCubit.isAnyEditActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please save or cancel current edits first'),
          backgroundColor: ColorHelper.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Observation-view others-section helpers
  // ---------------------------------------------------------------------------

  /// Checks if observation "others" data has changed vs the original.
  static bool hasObservationOthersChanged({
    required Map<String, TextEditingController> textControllers,
    required Map<String, bool> toggleStates,
    required Map<String, dynamic> originalOthersMap,
  }) {
    if (textControllers.length != originalOthersMap.length) return true;

    for (var entry in textControllers.entries) {
      final key = entry.key;
      final currentDescription = entry.value.text.trim();
      final currentActionTaken = toggleStates[key] ?? false;

      final originalItem = originalOthersMap[key];
      if (originalItem is Map) {
        final originalDescription =
            (originalItem['DescriptionOfIntervention']?.toString() ??
                    originalItem['Description']?.toString() ??
                    originalItem['Comment']?.toString() ??
                    '')
                .trim();
        final originalActionTaken =
            originalItem['ActionTaken'] as bool? ?? false;

        if (currentDescription != originalDescription ||
            currentActionTaken != originalActionTaken) {
          return true;
        }
      }
    }

    return false;
  }

  /// Builds the updated others-data map for only changed entries.
  static Map<String, dynamic> buildUpdatedOthersData({
    required Map<String, TextEditingController> textControllers,
    required Map<String, bool> toggleStates,
    required Map<String, dynamic> originalOthersMap,
  }) {
    final Map<String, dynamic> updatedOthersData = {};

    for (var entry in textControllers.entries) {
      final key = entry.key;
      final newDescription = entry.value.text.trim();
      final originalItem = originalOthersMap[key];

      if (originalItem is Map) {
        final originalDescription =
            (originalItem['DescriptionOfIntervention']?.toString() ??
                    originalItem['Description']?.toString() ??
                    originalItem['Comment']?.toString() ??
                    '')
                .trim();

        final originalActionTaken =
            originalItem['ActionTaken'] as bool? ?? false;
        final newActionTaken = toggleStates[key] ?? false;

        if (newDescription != originalDescription ||
            newActionTaken != originalActionTaken) {
          final updatedItem = Map<String, dynamic>.from(originalItem);
          updatedItem['ActionTaken'] = newActionTaken;

          if (updatedItem.containsKey('DescriptionOfIntervention')) {
            updatedItem['DescriptionOfIntervention'] = newDescription;
          } else if (updatedItem.containsKey('Description')) {
            updatedItem['Description'] = newDescription;
          } else if (updatedItem.containsKey('Comment')) {
            updatedItem['Comment'] = newDescription;
          }
          updatedOthersData[key] = updatedItem;
        }
      }
    }

    return updatedOthersData;
  }

  /// Merges [updatedOthersData] into the observation section of
  /// [localIncidentData].
  static void mergeObservationOthers(
    IncidentDetails localIncidentData,
    Map<String, dynamic> updatedOthersData,
  ) {
    localIncidentData.observation ??= <String, dynamic>{};
    if (localIncidentData.observation is Map<String, dynamic>) {
      final observationMap =
          localIncidentData.observation as Map<String, dynamic>;

      final othersKey =
          findCaseInsensitiveKey(observationMap, 'others') ?? 'others';
      final existingOthers =
          (observationMap[othersKey] as Map<String, dynamic>?) ??
          <String, dynamic>{};

      final mergedOthers = Map<String, dynamic>.from(existingOthers);
      updatedOthersData.forEach((key, value) {
        mergedOthers[key] = value;
      });

      observationMap[othersKey] = mergedOthers;
    }
  }
}
