/// Utility class for date and time formatting
/// Extracted from UI files to follow clean architecture
class DateTimeFormatter {
  /// TEMPORARY WORKAROUND: Fixed offset to sync mobile timer with web app.
  /// There is a consistent ~6 second delay between web and mobile timers.
  /// This offset compensates for that difference until a proper server-time
  /// synchronization solution is implemented.
  /// TODO: Replace with proper server-time-based implementation
  static const Duration _timerSyncOffset = Duration(seconds: 6);

  /// Format time string (e.g., "00:00:00")
  static String formatTime(String? timeTaken) {
    if (timeTaken == null || timeTaken.isEmpty) {
      return '00:00:00';
    }
    return timeTaken;
  }

  /// Format duration in seconds to MM:SS format
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format duration in seconds to HH:MM:SS format
  /// Use this for task timeTaken which comes from API as seconds
  static String formatDurationFromSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  /// Parse timeTaken string (seconds) and format as HH:MM:SS duration
  static String formatTimeTakenAsDuration(String? timeTaken) {
    if (timeTaken == null || timeTaken.isEmpty) {
      return '00:00:00';
    }
    final seconds = int.tryParse(timeTaken);
    if (seconds == null || seconds <= 0) {
      return '00:00:00';
    }
    return formatDurationFromSeconds(seconds);
  }

  /// Format incident timer based on startTime, endTime, and timeTaken
  /// - If endTime is null/empty: Show LIVE elapsed time from startTime
  /// - If endTime is present: Show final duration using timeTaken
  /// - If timer data is missing: Return null (caller should show N/A)
  static String? formatIncidentTimer({
    required String? startTime,
    String? endTime,
    int? timeTaken,
  }) {
    // If no startTime, we can't calculate anything
    if (startTime == null || startTime.isEmpty) {
      return null;
    }

    // If endTime is null or empty, incident is still active - calculate live duration
    if (endTime == null || endTime.isEmpty) {
      try {
        final start = DateTime.parse(startTime).toLocal();
        final duration = DateTime.now().difference(start);
        // Only return positive durations
        if (duration.isNegative) {
          return '00:00:00';
        }
        return formatDurationFromSeconds(duration.inSeconds);
      } catch (_) {
        return null;
      }
    }

    // Incident is closed - use timeTaken if available
    if (timeTaken != null && timeTaken > 0) {
      return formatDurationFromSeconds(timeTaken);
    }

    // Fallback: calculate from startTime and endTime
    try {
      final start = DateTime.parse(startTime).toLocal();
      final end = DateTime.parse(endTime).toLocal();
      final duration = end.difference(start);
      if (duration.isNegative) {
        return '00:00:00';
      }
      return formatDurationFromSeconds(duration.inSeconds);
    } catch (_) {
      return null;
    }
  }

  /// Check if incident timer is active (endTime is null/empty)
  static bool isIncidentTimerActive(String? endTime) {
    return endTime == null || endTime.isEmpty;
  }

  /// Calculate task duration based on status and timestamps
  ///
  /// Timer calculation logic:
  /// - Completed/Verified/Rejected: (completedAt - startedAt) - totalPausedTime
  /// - Paused: (pausedAt - startedAt) - totalPausedTime (static, no live update)
  /// - Inprogress: Working time before pause + time since resume (live update)
  ///
  /// Returns Duration.zero if startedAt is null
  static Duration calculateTaskDuration({
    required DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    int? totalPausedTime,
    String? status,
  }) {
    if (startedAt == null) return Duration.zero;

    final pausedSeconds = totalPausedTime ?? 0;
    final pausedDuration = Duration(seconds: pausedSeconds);

    // Normalize status for comparison
    final normalizedStatus = status?.toLowerCase().replaceAll(' ', '') ?? '';

    // Convert timestamps to local time for consistent calculations
    final localStartedAt = startedAt.toLocal();
    final localPausedAt = pausedAt?.toLocal();
    final localCompletedAt = completedAt?.toLocal();

    // Completed / Verified / Rejected - use completedAt
    if (_isCompletedStatus(normalizedStatus) && localCompletedAt != null) {
      final duration = localCompletedAt.difference(localStartedAt);
      final adjustedDuration = duration - pausedDuration;
      return adjustedDuration.isNegative ? Duration.zero : adjustedDuration;
    }

    // Paused - use pausedAt (static, NO DateTime.now())
    if (normalizedStatus == 'paused' || normalizedStatus == 'draft') {
      if (localPausedAt != null) {
        final duration = localPausedAt.difference(localStartedAt);
        final adjustedDuration = duration - pausedDuration;
        return adjustedDuration.isNegative ? Duration.zero : adjustedDuration;
      }
      // If paused but no pausedAt, return zero
      return Duration.zero;
    }

    // Inprogress - calculate live duration
    if (normalizedStatus == 'inprogress') {
      // If pausedAt is still set, task was just resumed from pause
      // Return the working time BEFORE pause as the starting point
      // The TimerWidget will tick forward from this value
      if (localPausedAt != null) {
        // Working time before the task was paused
        // This is the time the user was actively working on the task
        final workBeforePause = localPausedAt.difference(localStartedAt) - pausedDuration;
        final adjustedWork = workBeforePause.isNegative
            ? Duration.zero
            : workBeforePause;
        // Apply timer sync offset for in-progress tasks
        return adjustedWork + _timerSyncOffset;
      }

      // Normal case: no pausedAt, calculate from startedAt
      final duration = DateTime.now().difference(localStartedAt);
      final adjustedDuration = duration - pausedDuration;
      final result = adjustedDuration.isNegative
          ? Duration.zero
          : adjustedDuration;
      // Apply timer sync offset for in-progress tasks
      return result + _timerSyncOffset;
    }

    // Default fallback
    final duration = DateTime.now().difference(localStartedAt);
    final adjustedDuration = duration - pausedDuration;
    return adjustedDuration.isNegative ? Duration.zero : adjustedDuration;
  }

  /// Check if status indicates a completed/final state
  static bool _isCompletedStatus(String normalizedStatus) {
    return normalizedStatus == 'completed' ||
        normalizedStatus == 'verified' ||
        normalizedStatus == 'rejected';
  }

  /// Format Duration to HH:MM:SS string
  /// This is the ONLY method that should be used for duration formatting
  static String formatDurationToString(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// Calculate and format task duration as HH:MM:SS string
  /// Convenience method combining calculateTaskDuration and formatDurationToString
  static String formatTaskDuration({
    required DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    int? totalPausedTime,
    String? status,
  }) {
    final duration = calculateTaskDuration(
      startedAt: startedAt,
      pausedAt: pausedAt,
      completedAt: completedAt,
      totalPausedTime: totalPausedTime,
      status: status,
    );
    return formatDurationToString(duration);
  }

  /// Check if task timer should be running (live updates)
  /// Returns true only for Inprogress status
  static bool shouldTaskTimerRun(String? status) {
    final normalizedStatus = status?.toLowerCase().replaceAll(' ', '') ?? '';
    return normalizedStatus == 'inprogress';
  }

  /// Get month name abbreviation from month number (1-12)
  static String getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return 'Jan';
    return months[month - 1];
  }

  /// Format date to readable string (e.g., "27 Oct, 2025")
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day} ${getMonthName(date.month)}, ${date.year}';
  }
}
