import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/feedback/report_upload_loader.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_overview_details.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/approver/widgets/common_text_card.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/report_again.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/view_all_list_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/immediate_actions_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/voice_recording_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/websockets_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../helpers/widgets/feedback/user_guidence_popup.dart';

class ReportIncident extends StatefulWidget {
  final String? incidentId;

  const ReportIncident({super.key, this.incidentId});

  @override
  State<ReportIncident> createState() => _ReportIncidentState();
}

class _ReportIncidentState extends State<ReportIncident> {
  late final IncidentFileHandleCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AppDI.incidentFileHandleCubit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.requestPermissions();
      _cubit.initReportScreen(widget.incidentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IncidentFileHandleCubit, IncidentState>(
      listener: (context, state) {
        _cubit.syncControllerWithState(state);

        if (state.isReportUploading) {
          loaderService.hideLoader();
        } else if (state.processState == ProcessState.loading) {
          loaderService.showLoader();
        } else if (state.processState == ProcessState.done ||
            state.processState == ProcessState.error) {
          loaderService.hideLoader();
          if (state.processState == ProcessState.error ||
              state.fileProcessState == ProcessState.error) {
            final message = state.errorMessage?.isNotEmpty == true
                ? state.errorMessage!
                : '';
            if (message.isNotEmpty) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(message),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                  ),
                );
            }
          }
        }
      },
      builder: (context, state) {
        if (state.recordingStatus == RecordingStatus.recording &&
            _cubit.incidentInfoController.text != state.currentTranscript) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_cubit.incidentInfoController.text != state.currentTranscript) {
              _cubit.incidentInfoController.text = state.currentTranscript;
              _cubit.incidentInfoController.selection =
                  TextSelection.collapsed(
                    offset: _cubit.incidentInfoController.text.length,
                  );
            }
          });
        }

        final screenContent = state.data.isNotEmpty
            ? RefreshIndicator(
                onRefresh: () => state.data.isNotEmpty
                    ? _cubit.fetchIncidentById(
                        state.data.first.incidentId ?? '',
                      )
                    : Future.value(),
                child: _buildScreen(context, state),
              )
            : _buildScreen(context, state);

        return Stack(
          children: [
            screenContent,
            if (state.isReportUploading)
              Positioned.fill(
                child: ReportUploadLoader(
                  percentage: state.reportUploadProgress,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScreen(BuildContext context, IncidentState state) {
    final appState = AppDI.emergexAppCubit.state;
    final projects = appState.userPermissions?.projects ?? [];
    final selectedProjectId = appState.selectedProjectId;
    final selectedProject = projects.isEmpty
        ? null
        : projects.firstWhere(
          (p) => p.projectId == selectedProjectId,
      orElse: () => projects.first,
    );
    final projectName =
        selectedProject?.projectName ?? "Project";
    return PopScope(
      canPop: _cubit.allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _cubit.handleBackNavigation(context, state);
      },
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        appBar: AppBarWidget(
          hasNotifications: false,
          isRecording:
              state.recordingStatus != RecordingStatus.idle ||
              state.fileProcessState == ProcessState.loading,
        ),
        showBottomNav:
            state.data.isEmpty && state.processState != ProcessState.loading,
        navSelectedIndex: 1,
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            padding: const EdgeInsets.only(top: 15),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (state.data.isNotEmpty &&
                              state.fileProcessState !=
                                  ProcessState.loading) ...[
                            GestureDetector(
                              onTap: () =>
                                  _cubit.handleBackButtonTap(context, state),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ColorHelper.white
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: ColorHelper.textLight,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_left,
                                  size: 24,
                                  color: ColorHelper.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              TextHelper.reportIncident,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: ColorHelper.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      // if (state.data.isEmpty) UserGuidancePopup(),
                    ],
                  ),
                ),
                if (state.data.isNotEmpty) ReportAgain(),
                if (state.data.isEmpty) ...[
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Project Name",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColorHelper.grey4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: ColorHelper.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(projectName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColorHelper.projectText,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Column(
                  children: [
                    if (state.data.firstOrNull?.incidentId == null) ...[
                      VoiceRecordingWidget(),
                    ],
                    if (state.data.isEmpty) ...[
                      const SizedBox(height: 16),
                      CommentsCard(
                        reportIncident: true,
                        isEditRequired:
                            !(state.recordingStatus ==
                                RecordingStatus.recording),
                        controller: _cubit.incidentInfoController,
                        isCommon: true,
                        title: TextHelper.incidentInformation,
                        hint: TextHelper.youCanAlsoProvideATextInformation,
                        initialValue: state.incidentInformationTxt,
                        isRecording:
                            state.recordingStatus == RecordingStatus.recording,
                        onChanged: (value) {
                          if (state.recordingStatus !=
                              RecordingStatus.recording) {
                            _cubit.updateIncidentText(value);
                            _cubit.updateIncidentInformation(value, context);
                          }
                        },
                      ),
                    ],
                    if (state.data.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      IncidentOverviewDetails(
                        incident: state.data.first,
                        title: TextHelper.incidentSummary,
                        isEditRequired: false,
                      ),
                    ],
                    if (state.data.isEmpty) ...[
                        const SizedBox(height: 10),
                        const ImmediateActionsWidget(),
                    ],
                    ViewAllFileWidget(),
                    WebSocketsWidget(state: state),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
