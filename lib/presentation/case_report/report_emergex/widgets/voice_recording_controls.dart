// Handles the mic button and control buttons (play/pause/stop)

import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class VoiceRecordingControls extends StatelessWidget {
  final bool isListening;
  final bool isPaused;
  final bool speechEnabled;
  final WebSocketConnectionStatus connectionStatus;
  final VoidCallback onStopListening;
  final VoidCallback onPauseListening;
  final VoidCallback onResetListening;
  final AnimationController waveController;

  const VoiceRecordingControls({
    super.key,
    required this.isListening,
    required this.isPaused,
    required this.speechEnabled,
    required this.connectionStatus,
    required this.onStopListening,
    required this.onPauseListening,
    required this.onResetListening,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    if (!isListening && !isPaused) {
      return _buildMicButtonWithRings(context);
    } else if (isListening && !isPaused) {
      FocusScope.of(context).unfocus();
      return Column(
        children: [
          const SizedBox(height: 50),
          _buildControlPanel(
            context: context,
            isPaused: false,
            onPause: onPauseListening,
            onStop: onStopListening,
            onReset: onResetListening,
          ),
        ],
      );
    } else {
      return _buildControlPanel(
        context: context,
        isPaused: true,
        onPause: onPauseListening,
        onStop: onStopListening,
        onReset: onResetListening,
      );
    }
  }

  Widget _buildMicButtonWithRings(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorHelper.successColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        // Middle ring
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ColorHelper.successColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        // Main button
        _buildMicButton(context: context),
      ],
    );
  }

  Widget _buildMicButton({required BuildContext context}) {
    final result = AppDI.incidentFileHandleCubit;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ColorHelper.primaryLight,
            ColorHelper.primaryLight.withValues(alpha: 0.8),
            ColorHelper.primaryLight.withValues(alpha: 0.4),
            ColorHelper.primaryLight.withValues(alpha: 0.1),
          ],
          stops: const [0.6, 0.9, 0.9, 1.0],
        ),
      ),
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: ColorHelper.primaryDark.withValues(alpha: 0.1),
            width: 1,
          ),
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorHelper.primaryDark, ColorHelper.primaryLight],
          ),
        ),
        child: IconButton(
          icon: connectionStatus == WebSocketConnectionStatus.connecting
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorHelper.white,
                    ),
                  ),
                )
              : Image.asset(
                  Assets.reportIncidentMicFill,
                  color: ColorHelper.white,
                  width: 36,
                  height: 36,
                ),
          onPressed: () {
            FocusScope.of(context).unfocus();
            connectionStatus == WebSocketConnectionStatus.connecting
                ? null
                : !isListening
                ? {
                    if (result.state.incidentText?.isNotEmpty ?? true)
                      {
                        showErrorDialog(
                          context,
                          () {
                            back();
                            result.clearAisummaryIncident();
                            result.startRecording(context);
                          },
                          () {
                            back();
                          },
                          TextHelper.startNewRecordingTitle,
                          TextHelper.startNewRecordingMessage,
                          TextHelper.startOverText,
                          TextHelper.goBack,
                        ),
                      }
                    else
                      {result.startRecording(context)},
                  }
                : null;
          },
          tooltip: connectionStatus == WebSocketConnectionStatus.connecting
              ? TextHelper.connecting
              : speechEnabled
              ? TextHelper.startRecording
              : TextHelper.speechNotAvailable,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required Widget icon,
    Color? color,
    required VoidCallback onPressed,
    String? tooltip,
    bool shouldUnfocus = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color != null
              ? color.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(color: color ?? ColorHelper.red, width: 2),
        ),
        child: IconButton(
          icon: icon,
          onPressed: () {
            if (shouldUnfocus) {
              FocusScope.of(context).unfocus();
            }
            onPressed();
          },
        ),
      ),
    );
  }

  Widget _buildControlPanel({
    required BuildContext context,
    required bool isPaused,
    required VoidCallback onPause,
    required VoidCallback onStop,
    required VoidCallback onReset,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            context: context,
            icon: Icon(
              isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined,
              size: 22,
            ),
            color: ColorHelper.recordingStatusGreen,
            onPressed: onPause,
            shouldUnfocus: true,
          ),
          const SizedBox(width: 18),
          _buildControlButton(
            context: context,
            icon: Image.asset(
              Assets.reportIncidentReset,
              width: 16,
              height: 16,
            ),
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}
