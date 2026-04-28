import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/ai_summary.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/incident_common_button.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/provide_info.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum VoiceFlowStep { aiSummary, comments }

class WebSocketsWidget extends StatelessWidget {
  final IncidentState state;
  final bool isDialogOpen;

  const WebSocketsWidget({
    super.key,
    required this.state,
    this.isDialogOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = state.recordingStatus;
    final cubit = AppDI.incidentFileHandleCubit;
    return SizedBox(
      child: Column(
        children: [
          // 🔹 When paused
          if ((!isDialogOpen && state.data.isEmpty) &&
                  (state.aiSummary.trim().isNotEmpty ||
                      (state.questions.isNotEmpty &&
                          state.examples.isNotEmpty)) ||
              (isDialogOpen && state.data.isNotEmpty) &&
                  (state.aiSummary.trim().isNotEmpty ||
                      (state.questions.isNotEmpty &&
                          state.examples.isNotEmpty)))
            BlocBuilder<IncidentFileHandleCubit, IncidentState>(
              builder: (context, state) {
                return Column(
                  children: [
                    AISummary(
                      title: TextHelper.aiSummary,
                      color: state.data.isNotEmpty
                          ? ColorHelper.recordAgainCardColor
                          : ColorHelper.white.withValues(alpha: 0.8),
                      summary: state.aiSummary.isNotEmpty
                          ? state.aiSummary
                          : "No summary found. Please provide more details in text or audio",
                      onPressed: () {},
                    ),
                    SizedBox(height: 16),
                    if (state.totalQuestionsLength > 0)
                      IncidentReportWidget(
                        totalQuestion: state.totalQuestionsLength,
                        unansweredQuestion: state.unansweredQuestionsLength,
                        incidentPoints: state.questions,
                        examples: state.examples,
                      ),
                  ],
                );
              },
            ),

          ActionButtonsRow(
            leftText: TextHelper.cancel,
            rightText: (state.data.isNotEmpty && !isDialogOpen)
                ? TextHelper.report
                : TextHelper.continue_,
            isEnabled:
                (((state.totalQuestionsLength > 0 && isDialogOpen) ||
                        (state.data.isNotEmpty && !isDialogOpen)) &&
                    state.fileProcessState != ProcessState.loading ||
                ((!isDialogOpen &&
                        state.totalQuestionsLength -
                                state.unansweredQuestionsLength >
                            0) &&
                    (state.recordingStatus != RecordingStatus.recording))),
            onLeftPressed: () {
              // Case 1: Nothing recorded or typed — go home directly
              if (state.incidentText!.isEmpty &&
                  !isDialogOpen &&
                  state.recordingStatus == RecordingStatus.idle &&
                  state.data.isEmpty) {
                loadDasboardData();
                return context.go(
                  Routes.homeScreen,
                );
              }

              // --- Separated condition starts here ---
              if (isDialogOpen) {
                // Case 2: Dialog open but text empty and idle — just go back
                if (state.recordingStatus == RecordingStatus.idle &&
                    state.incidentText!.isEmpty) {
                  return back();
                }

                // Case 3: Dialog open and possibly recording/text present — confirm cancel
                cubit.setCancelDialogOpen(true);
                if (state.recordingStatus == RecordingStatus.idle) {
                  showErrorDialog(
                    context,
                    () {
                      cubit.setCancelDialogOpen(false);
                      cubit.updateIncidentText("");
                      back();
                      back();
                    },
                    () {
                      cubit.setCancelDialogOpen(false);
                      back();
                    },
                    TextHelper.areYouSureYouWantToCancelTheReport,
                    '',
                    TextHelper.yesCancel,
                    TextHelper.goBack,
                  );
                } else {
                  showErrorDialog(
                    context,
                    () {
                      cubit.setCancelDialogOpen(false);
                      cubit.resetRecording();

                      cubit.updateIncidentText("");
                      back();
                      back();
                    },
                    () {
                      cubit.setCancelDialogOpen(false);
                      back();
                    },
                    TextHelper.areYouSureYouWantToCancelTheReport,
                    '',
                    TextHelper.yesCancel,
                    TextHelper.goBack,
                  );
                }
              } else {
                if (state.data.isEmpty) {
                  cubit.setCancelDialogOpen(true);
                  showErrorDialog(
                    context,
                    () {
                      cubit.setCancelDialogOpen(false);
                      cubit.resetRecording();
                      back();

                      cubit.clear();
                      cubit.clearAisummaryIncident();
                      loadDasboardData();
                      context.go(
                        Routes.homeScreen,
                      );
                    },
                    () {
                      cubit.setCancelDialogOpen(false);
                      back();
                    },
                    TextHelper.areYouSure,
                    TextHelper.cancelReportConfirmation,
                    TextHelper.yesCancel,
                    TextHelper.goBack,
                  );
                } else {
                  // Case 5: Data exists — confirm delete
                  cubit.setCancelDialogOpen(true);
                  showErrorDialog(
                    context,
                    () {
                      cubit.deleteIncident(state.data.first.incidentId!);
                      back();
                      loadDasboardData();
                      context.go(
                        Routes.homeScreen,
                      );
                    },
                    () {
                      cubit.setCancelDialogOpen(false);
                      back();
                    },
                    TextHelper.areYouSure,
                    TextHelper.cancelReportSubtitle,
                    TextHelper.yesCancel,
                    TextHelper.no,
                  );
                }
              }
            },
            onRightPressed: () async {
              if (!isDialogOpen &&
                  state.data.isNotEmpty &&
                  state.processState == ProcessState.done) {
                if ((state.data.first.uploadedFiles == null ||
                        state.data.first.uploadedFiles!.audio.isEmpty) &&
                    state.data.first.emergeXCaseInformations!.isEmpty) {
                  showErrorDialog(
                    context,
                    () {
                      back();
                    },
                    () {
                      loadDasboardData();
                      back();
                      context.go(
                        Routes.homeScreen,
                      );
                    },
                    TextHelper.enterTheValidIncidentDetails,
                    TextHelper.fillAllFields,
                    TextHelper.stayOnThisPage,
                    TextHelper.backToDashboard,
                  );
                } else {
                  cubit.reportIncident(state.data.first.incidentId!, context);
                }
              } else if (status != RecordingStatus.recording &&
                  status != RecordingStatus.paused &&
                  (state.currentTranscript).isNotEmpty &&
                  state.incidentText!.isNotEmpty) {
                if (state.data.isNotEmpty) {
                  cubit.addLoader();
                  cubit.updateIncident(
                    state.data.first.incidentId!,
                    null,
                    null,
                    state.currentTranscript,
                  );
                  if (state.data.isNotEmpty) {
                    back();
                  }
                } else {
                  cubit.createIncident(null, null, state.currentTranscript);
                  if (state.data.isNotEmpty &&
                      state.processState == ProcessState.done) {
                    back();
                    if (isDialogOpen == true) {
                      back();
                    }
                  }
                }
              } else if (status == RecordingStatus.paused) {
                cubit.updateAiSummary(state.incidentInformationTxt ?? '');
                cubit.stopRecording();
                if (isDialogOpen == true) {
                  back();
                }
              } else {
                showErrorDialog(
                  context,
                  () {
                    back();
                  },
                  () {
                    loadDasboardData();
                    back();
                    context.go(
                      Routes.homeScreen,
                    );
                  },
                  TextHelper.enterTheValidIncidentDetails,
                  TextHelper.fillAllFields,
                  TextHelper.stayOnThisPage,
                  TextHelper.backToDashboard,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void loadDasboardData() {
    final currentState = AppDI.dashboardCubit.state;
    if (currentState is DashboardLoaded) {
      Map<String, String>? daterange;
      if (currentState.fromDate != null && currentState.toDate != null) {
        daterange = {
          'from':
              '${currentState.fromDate!.year}-${currentState.fromDate!.month.toString().padLeft(2, '0')}-${currentState.fromDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z',
          'to':
              '${currentState.toDate!.year}-${currentState.toDate!.month.toString().padLeft(2, '0')}-${currentState.toDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z',
        };
      }

      AppDI.dashboardCubit.loadIncidents(
        page: 1,
        limit: 10,

        incidentStatus: currentState.incidentStatus,
        daterange: daterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    } else {
      AppDI.dashboardCubit.loadIncidents(
        page: 1,
        limit: 10,
        selectedMetricIndex: 0,
      );
    }
  }
}
