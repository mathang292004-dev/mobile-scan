import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/case_report/approver/widgets/common_text_card.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/immediate_actions_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/voice_recording_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/websockets_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';

import '../../../../helpers/dialog_helper.dart';
import '../../../../helpers/nav_helper/nav_helper.dart';

class ReportAgain extends StatelessWidget {
  const ReportAgain({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: EmergexButton(
            onPressed: () => _showReportAgainDialog(context),
            text: TextHelper.reportAgain,
            borderRadius: 30,
            leadingIcon: Icon(Icons.add, color: ColorHelper.surfaceColor),
          ),
        ),
      ],
    );
  }

  void _showReportAgainDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final cubit = AppDI.incidentFileHandleCubit;
        final TextEditingController incidentInformationController =
            TextEditingController(text: cubit.state.incidentText ?? '');
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              AppDI.incidentFileHandleCubit.setCancelDialogOpen(true);
              showErrorDialog(
                context,
                () {
                  AppDI.incidentFileHandleCubit.setCancelDialogOpen(false);
                  dialogContext
                      .read<IncidentFileHandleCubit>()
                      .resetRecording();
                  back();
                  back();
                },
                () {
                  AppDI.incidentFileHandleCubit.setCancelDialogOpen(false);
                  back();
                },
                TextHelper.areYouSure,
                TextHelper.cancelReportConfirmation,
                TextHelper.yesCancel,
                TextHelper.goBack,
              );
            }
          },
          child: Dialog(
            backgroundColor: ColorHelper.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: BlocListener<IncidentFileHandleCubit, IncidentState>(
              listenWhen: (previous, current) =>
                  ((current.incidentText?.isEmpty ?? false) &&
                  (current.currentTranscript.isEmpty)),
              listener: (context, state) {
                incidentInformationController.text = '';
              },
              child: BlocBuilder<IncidentFileHandleCubit, IncidentState>(
                builder: (context, state) {
                  // Update controller text when recording
                  if (!(state.recordingStatus == RecordingStatus.idle ||
                      state.recordingStatus == RecordingStatus.paused)) {
                    incidentInformationController.text =
                        state.currentTranscript;
                  }
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            top: 16.0,
                          ),
                          child: Text(
                            TextHelper.reportIncident,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        VoiceRecordingWidget(
                          color: ColorHelper.recordAgainCardColor,
                        ),

                        /// Show comments input when not recording
                        const SizedBox(height: 16),
                        CommentsCard(
                          reportIncident: true,
                          isEditRequired:
                              !(state.recordingStatus ==
                                  RecordingStatus.recording),
                          controller: incidentInformationController,
                          isCommon: true,
                          title: TextHelper.emergeXCaseInformation,
                          color: ColorHelper.recordAgainCardColor,
                          hint: TextHelper.youCanAlsoProvideATextInformation,
                          initialValue: state.incidentInformationTxt,
                          isRecording:
                              state.recordingStatus ==
                              RecordingStatus.recording,
                          onChanged: (value) {
                            // Only update when not recording to avoid IME issues
                            if (state.recordingStatus !=
                                RecordingStatus.recording) {
                              AppDI.incidentFileHandleCubit.updateIncidentText(
                                value,
                              );
                              AppDI.incidentFileHandleCubit
                                  .updateIncidentInformation(value, context);
                            }
                          },
                        ),
                        ImmediateActionsWidget(
                          backgroundColor: ColorHelper.recordAgainCardColor,
                        ),
                        WebSocketsWidget(state: state, isDialogOpen: true),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
