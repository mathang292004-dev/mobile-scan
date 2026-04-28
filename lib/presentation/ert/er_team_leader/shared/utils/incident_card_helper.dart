import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/status_color_helper.dart';
import 'package:flutter/material.dart';

/// Helper class for building incident card data
/// Extracted from UI files to follow clean architecture
class IncidentCardHelper {
  /// Get incident ID from incident details
  static String getIncidentId(IncidentDetails incident) {
    return incident.incidentId ?? incident.sId ?? '';
  }

  /// Get project name from incident details
  static String getProjectName(IncidentDetails incident) {
    return incident.projectName ?? '';
  }

  /// Get title from incident details
  static String getTitle(IncidentDetails incident) {
    return incident.title ?? '';
  }

  static String getStatus(IncidentDetails incident) {
    final rawStatus = incident.incidentStatus?.toLowerCase().trim();

    switch (rawStatus) {
      case 'closed':
        return 'Approved';

      case 'pending':
        return 'Pending';

      case 'rejected':
        return 'Rejected';

      default:
        return incident.incidentStatus ?? '-';
    }
  }

  /// Get severity from incident details
  static String getSeverity(IncidentDetails incident) {
    return incident.incidentLevel?.value ?? 'Low';
  }

  /// Get priority (default to Medium if not available)
  static String getPriority(IncidentDetails incident) {
    return incident.incidentLevel?.value ?? 'Low';
  }

  /// Get status color for incident
  static Color getStatusColor(IncidentDetails incident) {
    return StatusColorHelper.getStatusColor(getStatus(incident));
  }

  /// Get status border color for incident
  static Color getStatusBorderColor(IncidentDetails incident) {
    return StatusColorHelper.getStatusBorderColor(getStatus(incident));
  }

  /// Get status background color for incident badge
  static Color getStatusBackgroundColor(IncidentDetails incident) {
    return StatusColorHelper.getStatusBackgroundColor(getStatus(incident));
  }

  /// Get timer color for incident
  static Color getTimerColor(IncidentDetails incident) {
    return StatusColorHelper.getTimerColor(getStatus(incident));
  }

  /// Get time elapsed - returns "N/A" if not available
  /// This will need to be calculated from task data or incident data
  static String getTimeElapsed(IncidentDetails incident) {
    // For now, return "N/A" as per requirement
    return 'N/A';
  }
}
