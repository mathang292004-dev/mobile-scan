import 'package:flutter/foundation.dart';

/// Singleton class to manage global call state
/// Used to prevent showing incoming call dialogs when user is already in a call
/// or when another incoming call dialog is already visible
class CallStateManager {
  // Singleton instance
  static final CallStateManager _instance = CallStateManager._internal();
  factory CallStateManager() => _instance;
  CallStateManager._internal();

  /// Whether the user is currently in an active call
  bool _isInCall = false;

  /// Whether an incoming call dialog is currently being displayed
  bool _isIncomingCallDialogVisible = false;

  /// The call ID of the current incoming call dialog (to prevent duplicates)
  String? _currentIncomingCallId;

  /// Set of call IDs that have ended (used to prevent showing join button for ended calls)
  final Set<String> _endedCallIds = {};

  /// Get whether the user is currently in a call
  bool get isInCall => _isInCall;

  /// Get whether an incoming call dialog is currently visible
  bool get isIncomingCallDialogVisible => _isIncomingCallDialogVisible;

  /// Get the current incoming call ID
  String? get currentIncomingCallId => _currentIncomingCallId;

  /// Set the in-call state (called when entering/exiting a call screen)
  void setInCall(bool inCall) {
    _isInCall = inCall;
    debugPrint('📞 CallStateManager: isInCall = $_isInCall');

    // If we're now in a call, clear any incoming call dialog state
    if (inCall) {
      _isIncomingCallDialogVisible = false;
      _currentIncomingCallId = null;
    }
  }

  /// Set the incoming call dialog visibility
  /// Returns true if the dialog can be shown, false if it should be blocked
  bool showIncomingCallDialog(String callId) {
    // Don't show if already in a call
    if (_isInCall) {
      debugPrint('📞 CallStateManager: Blocking incoming call dialog - already in call');
      return false;
    }

    // Don't show if another incoming call dialog is visible
    if (_isIncomingCallDialogVisible) {
      debugPrint('📞 CallStateManager: Blocking incoming call dialog - another dialog visible');
      return false;
    }

    // Don't show duplicate dialogs for the same call
    if (_currentIncomingCallId == callId) {
      debugPrint('📞 CallStateManager: Blocking incoming call dialog - duplicate call ID');
      return false;
    }

    // Allow showing the dialog
    _isIncomingCallDialogVisible = true;
    _currentIncomingCallId = callId;
    debugPrint('📞 CallStateManager: Showing incoming call dialog for call: $callId');
    return true;
  }

  /// Called when the incoming call dialog is dismissed (accepted or declined)
  void dismissIncomingCallDialog() {
    _isIncomingCallDialogVisible = false;
    _currentIncomingCallId = null;
    debugPrint('📞 CallStateManager: Incoming call dialog dismissed');
  }

  /// Mark a call as ended (called when participantLeft with remainingParticipants: 0 or callEnded event)
  void markCallEnded(String callId) {
    _endedCallIds.add(callId);
    debugPrint('📞 CallStateManager: Call $callId marked as ended');
    // Keep only recent ended calls to prevent memory growth
    if (_endedCallIds.length > 50) {
      _endedCallIds.remove(_endedCallIds.first);
    }
  }

  /// Check if a call has ended
  bool isCallEnded(String callId) {
    return _endedCallIds.contains(callId);
  }

  /// Clear a specific ended call (called when a new call starts with the same group)
  void clearEndedCall(String callId) {
    _endedCallIds.remove(callId);
    debugPrint('📞 CallStateManager: Cleared ended call $callId');
  }

  /// Reset all state (useful for logout or app reset)
  void reset() {
    _isInCall = false;
    _isIncomingCallDialogVisible = false;
    _currentIncomingCallId = null;
    _endedCallIds.clear();
    debugPrint('📞 CallStateManager: State reset');
  }
}
