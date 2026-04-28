/// Task Status Helper
/// Provides utilities for normalizing and checking task status values
/// across the application to ensure consistent timer behavior.
class TaskStatusHelper {
  // Private constructor to prevent instantiation
  TaskStatusHelper._();

  /// Canonical status values
  static const String statusDraft = 'Draft';
  static const String statusInProgress = 'Inprogress';
  static const String statusPaused = 'Paused';
  static const String statusCompleted = 'Completed';
  static const String statusRejected = 'Rejected';

  /// Normalize status string to canonical form
  /// Handles variations like "In Progress", "in progress", "InProgress"
  static String normalizeStatus(String? status) {
    if (status == null || status.isEmpty) {
      return statusDraft;
    }

    final normalized = status.toLowerCase().replaceAll(' ', '');

    switch (normalized) {
      case 'inprogress':
      case 'in-progress':
        return statusInProgress;
      case 'paused':
        return statusPaused;
      case 'completed':
      case 'complete':
      case 'verified':
        return statusCompleted;
      case 'rejected':
        return statusRejected;
      case 'draft':
        return statusDraft;
      default:
        return status; // Return original if unknown
    }
  }

  /// Check if task is in progress
  static bool isInProgress(String? status) {
    return normalizeStatus(status) == statusInProgress;
  }

  /// Check if task is paused
  static bool isPaused(String? status) {
    return normalizeStatus(status) == statusPaused;
  }

  /// Check if task is completed
  static bool isCompleted(String? status) {
    return normalizeStatus(status) == statusCompleted;
  }

  /// Check if task is rejected
  static bool isRejected(String? status) {
    return normalizeStatus(status) == statusRejected;
  }

  /// Check if task is in a final state (completed or rejected)
  /// Use this for hiding action buttons and showing static timer
  static bool isFinalState(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusCompleted || normalized == statusRejected;
  }

  /// Check if task is draft
  static bool isDraft(String? status) {
    return normalizeStatus(status) == statusDraft;
  }

  /// Determine if timer should run based on status
  /// Timer runs ONLY when status is "Inprogress"
  static bool shouldTimerRun(String? status) {
    return isInProgress(status);
  }

  /// Get display-friendly status string
  /// Converts "Inprogress" → "In Progress" for UI
  static String getDisplayStatus(String? status) {
    final normalized = normalizeStatus(status);
    switch (normalized) {
      case statusInProgress:
        return 'In Progress';
      case statusPaused:
        return 'Paused';
      case statusCompleted:
        return 'Completed';
      case statusRejected:
        return 'Rejected';
      case statusDraft:
        return 'Draft';
      default:
        return status ?? 'Unknown';
    }
  }

  /// Get API-compatible status string
  /// Converts "In Progress" → "Inprogress" for API calls
  static String getApiStatus(String? status) {
    return normalizeStatus(status);
  }
}
