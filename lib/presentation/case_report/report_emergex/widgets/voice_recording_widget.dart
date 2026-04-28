import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/processing_container_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/recording_main_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/di/app_di.dart';

class VoiceRecordingWidget extends StatelessWidget {
  const VoiceRecordingWidget({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    //[Permission.microphone, Permission.storage].request();

    return BlocConsumer<IncidentFileHandleCubit, IncidentState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          debugPrint(state.errorMessage!);
        }
      },
      builder: (context, state) {
        final cubit =AppDI.incidentFileHandleCubit;
        final isRecording = state.recordingStatus == RecordingStatus.recording;
        final isPaused = state.recordingStatus == RecordingStatus.paused;
        final isProcessing =
            state.recordingStatus == RecordingStatus.processing;
        return SingleChildScrollView(
          child: Column(
            children: [
              _WaveAnimationController(
                isAnimating: isRecording,
                builder: (waveController) => MainContainerWidget(
                  isRecording: isRecording,
                  isPaused: isPaused,
                  waveController: waveController,
                  onStopRecording: cubit.stopRecording,
                  onPauseRecording: cubit.pauseResumeRecording,
                  onResetRecording: cubit.resetRecording,
                  duration: state.recordingDuration ?? 0,
                  selectedLanguage: TextHelper.english,
                  languages: const [TextHelper.english],
                  color: color,
                  state: state,
                ),
              ),
              if (isProcessing)
                const ProcessingContainerWidget(statusMessage: 'Processing...'),
            ],
          ),
        );
      },
    );
  }
}

class _WaveAnimationController extends StatefulWidget {
  final bool isAnimating;
  final Widget Function(AnimationController) builder;
  const _WaveAnimationController({
    required this.isAnimating,
    required this.builder,
  });

  @override
  State<_WaveAnimationController> createState() =>
      _WaveAnimationControllerState();
}

class _WaveAnimationControllerState extends State<_WaveAnimationController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isAnimating) _waveController.repeat();
  }

  @override
  void didUpdateWidget(covariant _WaveAnimationController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      widget.isAnimating ? _waveController.repeat() : _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_waveController);
}
