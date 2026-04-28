import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/approver/widgets/feed_back_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/file_upload.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/recorded_files_list.dart';
import 'package:emergex/presentation/case_report/utils/case_report_data_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewAllFileWidget extends StatelessWidget {
  const ViewAllFileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // [Permission.microphone, Permission.storage].request();

    return BlocConsumer<IncidentFileHandleCubit, IncidentState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          debugPrint(state.errorMessage!);
        }
      },
      builder: (context, state) {
        final recordings = CaseReportDataUtils.mapRecordings(
          state.data.isNotEmpty ? state.data.first : null,
        );

        final isRecording = state.recordingStatus == RecordingStatus.recording;
        final isPaused = state.recordingStatus == RecordingStatus.paused;
        final isProcessing =
            state.recordingStatus == RecordingStatus.processing;

        return SingleChildScrollView(
          child: Column(
            children: [
              if (!isRecording &&
                  !isProcessing &&
                  !isPaused &&
                  state.data.isNotEmpty) ...[
                const SizedBox(height: 24),

                RecordedFilesWidget(recordings: recordings),
              ],
              if (state.data.isNotEmpty &&
                  !isRecording &&
                  !isProcessing &&
                  !isPaused) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),

                  child: FeedbackWidget(
                    feedback: state.data.first.emergeXCaseInformations,
                    title: TextHelper.incidentInformation,
                    isExpandable: false,
                    feedbackKey: 'incidentInformations',
                    incidentDetails: state.data.first,
                    parentPath: '',
                    isIncidentReport: true,
                  ),
                ),
                const SizedBox(height: 24),
                const FileUpload(),
              ],
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
