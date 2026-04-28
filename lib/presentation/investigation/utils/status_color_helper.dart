import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

/// Utility class for status color management
/// Extracted from UI files to follow clean architecture
class InvestigationStatusColorHelper {
  /// Get status color based on status string
  static Color getStatusColor(String status) {
    if (status.isEmpty) {
      return ColorHelper.primaryColor;
    }
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'verified':
        return ColorHelper.verifiedTextColor; // #41A229 - Green
      case 'approved':
      case 'closed':
        return ColorHelper.resolvedColor;
      case 'not verified':
      case 'notverified':
      case 'pending':
        return ColorHelper.notVerifiedTextColor; // #A27429
      case 'rejected':
        return ColorHelper.rejectedBorder; // #A22929
      case 'resolved':
        return ColorHelper.textLightGreen;
      case 'inprogress':
        return ColorHelper.timerInProgressColor;
      case 'completed':
        return ColorHelper.verifiedTextColor;
      case 'paused':
        return ColorHelper.pausedColor;
      case 'draft':
        return ColorHelper.white;
      default:
        return ColorHelper.primaryColor;
    }
  }

  /// Get status border color based on status string
  static Color getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return ColorHelper.erteamleaderresolveboder.withValues(alpha: 0.36);
      case 'inprogress':
        return ColorHelper.erteamleaderprogress.withValues(alpha: 0.4);
      case 'closed':
      case 'approved':
        return ColorHelper.resolvedColor.withValues(alpha: 0.32);
      case 'rejected':
        return ColorHelper.rejectedBorder.withValues(alpha: 0.32);
      case 'paused':
      case 'pending':
        return ColorHelper.pausedColor.withValues(alpha: 0.32);
      default:
        return Colors.transparent;
    }
  }

  /// Get status background color with opacity
  static Color getStatusBackgroundColor(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'verified':
        return ColorHelper.verifiedBackgroundColor; // #D7FFD3
      case 'closed':
      case 'approved':
        return ColorHelper.primaryLight4.withValues(alpha: 0.4);
      case 'not verified':
      case 'notverified':
        return ColorHelper.notVerifiedBackgroundColor; // #FFFCA8
      case 'pending':
        return ColorHelper.pendingBackgroundColor.withValues(alpha: 0.4);
      case 'rejected':
        return ColorHelper.userbackground.withValues(alpha: 0.1); // #FFB5A8
      case 'paused':
        return ColorHelper.notVerifiedBackgroundColor;
      case 'draft':
        return ColorHelper.pausedColor; // #FFFCA8
      case 'inprogress':
        return ColorHelper.taskteamProgressbackgorund;

      default:
        return getStatusColor(status).withValues(alpha: 0.1);
    }
  }

  /// Get timer color based on status
  static Color getTimerColor(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'verified':
      case 'closed':
      case 'completed': // Closed means verified
        return ColorHelper.verifiedTimerColor; // #3DA229
      case 'not verified':
      case 'notverified':
      case 'paused':
      case 'draft':
      case 'pending':
        return ColorHelper.notVerifiedTimerColor; // #242424
      case 'rejected':
        return ColorHelper.rejectedTimerColor; // #FF3C56
      case 'inprogress':
        return ColorHelper.timerInProgressColor;
      default:
        return ColorHelper.textTertiary;
    }
  }

  static Color getTaskTimerColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
      case 'completed':
        return ColorHelper.primaryColor;

      case 'paused':
      case 'pause':
      case 'draft':
        return Colors.black;

      case 'inprogress':
      case 'in progress':
        return ColorHelper.timeColor;

      default:
        return ColorHelper.primaryColor;
    }
  }
}
