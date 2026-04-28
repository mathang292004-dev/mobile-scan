import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/recording_timer_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/voice_recording_controls.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/voice_recording_visualization.dart';

import 'package:flutter/material.dart';

class MainContainerWidget extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final AnimationController waveController;
  
  final VoidCallback onStopRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResetRecording;
  final String selectedLanguage;
  final int duration;
  final List<String> languages;
  final IncidentState state;
  final Color? color;

  const MainContainerWidget({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.waveController,

    required this.onStopRecording,
    required this.onPauseRecording,
    required this.onResetRecording,
    required this.selectedLanguage,
    required this.duration,
    required this.languages,
    required this.state,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 15, right: 15, top: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
      decoration: BoxDecoration(
        color: color ?? ColorHelper.surfaceColor.withValues(alpha: 0.4),

        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.surfaceColor),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _buildTitle(),
          const SizedBox(height: 8),
          if (!isRecording && !isPaused) _buildSubtitle(),
          if (!isPaused) ...[
            const SizedBox(height: 10),
            _buildStatusText(),
            VoiceRecordingVisualization(
              isListening: isRecording && !isPaused,
              isPaused: isPaused,
              waveController: waveController,
              audioLevels: state.audioLevels,
            ),
          ],
          if (isRecording || isPaused)
            RecordingTimerWidget(durationSeconds: duration),
          const SizedBox(height: 16),
          VoiceRecordingControls(
            isListening: isRecording,
            isPaused: isPaused,
            speechEnabled: true,
            connectionStatus: state.websocketConnectionStatus,
            onStopListening: onStopRecording,
            onPauseListening: onPauseRecording,
            onResetListening: onResetRecording,
            waveController: waveController,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Builder(
      builder: (context) => Text(
        TextHelper.recordIncidentDetails,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: ColorHelper.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          TextHelper.provideMinimalDetails,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return Builder(
      builder: (context) {
        String statusText;
        Color statusColor = ColorHelper.successColor;

        if (isRecording) {
          statusText = TextHelper.recording;
          statusColor = ColorHelper.recordingStatusGreen;
        } else {
          statusText = TextHelper.tapMicToStartRecording;
        }

        return SizedBox(
          height: 30,
          child: Text(
            statusText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
