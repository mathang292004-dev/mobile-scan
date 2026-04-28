import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/feedback/pdf_viewer_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/ert/er_team_approver/cubit/er_team_approver_dashboard_cubit.dart';
import 'package:emergex/presentation/ert/er_team_approver/model/er_incident_model.dart';
import 'package:emergex/presentation/ert/er_team_approver/widgets/case_overview_widget.dart';
import 'package:emergex/presentation/ert/er_team_approver/widgets/custom_checkbox_widget.dart';
import 'package:emergex/presentation/ert/er_team_approver/widgets/incident_card_widget.dart';
import 'package:emergex/presentation/ert/er_team_approver/widgets/tab_filter_widget.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/utils/timer_widget.dart' as live_timer;
import 'package:emergex/presentation/ert/er_team_approver/widgets/timer_widget.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/utils/date_time_formatter.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/assets.dart';

/// ER Team Approver Screen
/// Main screen for ER Team Approver functionality
class ErTeamApproverScreen extends StatefulWidget {
  final String incidentId;
  final bool showVerificationDialog;
  const ErTeamApproverScreen({super.key, required this.incidentId, this.showVerificationDialog = false});

  @override
  State<ErTeamApproverScreen> createState() => _ErTeamApproverScreenState();
}

class _ErTeamApproverScreenState extends State<ErTeamApproverScreen> {
  String selectedTab = TextHelper.tabAll;
  Map<String, bool> selectedIncidents = {}; // Track selected incidents by ID
  bool selectAllChecked = false;
  late final ErTeamApproverDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AppDI.erTeamApproverDashboardCubit;
    _loadIncidentTasks();
  }

  Future<void> _loadIncidentTasks() async {
    await _cubit.loadIncidentTasks(
      incidentId: widget.incidentId,
      status: selectedTab == TextHelper.tabAll
          ? 'all'
          : _mapTabToStatus(selectedTab),
    );
  }

  bool get _showSelectAllCheckbox {
    if (_cubit.state.isLoadingTasks) return false;

    return selectedTab == TextHelper.tabAll ||
        selectedTab == TextHelper.tabNotVerified;
  }

  String _mapTabToStatus(String tab) {
    switch (tab) {
      case TextHelper.tabVerified:
        return 'verified';
      case TextHelper.tabNotVerified:
        return 'not_verified';
      case TextHelper.tabRejected:
        return 'rejected';
      default:
        return 'all';
    }
  }

  void _handleTabChange(String tab) {
    setState(() {
      selectedTab = tab;
      selectAllChecked = false;
      selectedIncidents.clear();
    });
    
    _cubit.clearIncidentTasks();
    // Reload tasks with new status filter
    _loadIncidentTasks();
  }

  void _handleIncidentSelection(String incidentId, bool isSelected) {
    setState(() {
      selectedIncidents[incidentId] = isSelected;
      _updateSelectAllState();
    });
  }

  void _handleSelectAll(CheckboxState state, List<ErIncidentModel> incidents) {
    setState(() {
      selectAllChecked = state == CheckboxState.checked;
      // Only select/deselect "Not Verified" incidents
      for (var incident in incidents) {
        if (incident.status == ErIncidentStatus.notVerified) {
          selectedIncidents[incident.id] = selectAllChecked;
        }
      }
    });
  }

  void _updateSelectAllState() {
    // This will be called from within BlocBuilder context
    // We'll update it based on the current incidents list
  }

  bool _isIncidentSelected(String incidentId) {
    return selectedIncidents[incidentId] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      ErTeamApproverDashboardCubit,
      ErTeamApproverDashboardState
    >(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          previous.isVerifyingTask != current.isVerifyingTask ||
          previous.verifyTaskSuccess != current.verifyTaskSuccess ||
          previous.verifyTaskErrorMessage != current.verifyTaskErrorMessage ||
          previous.isExportingPdf != current.isExportingPdf ||
          previous.exportPdfSuccess != current.exportPdfSuccess ||
          previous.exportPdfErrorMessage != current.exportPdfErrorMessage,
      listener: (context, state) {
        if (state.verifyTaskSuccess) {
          showVerificationSuccessDialog(
            context: context,
            onContinue: () {
              _cubit.clearVerifyTaskState();

              if (!mounted) return;

              setState(() {
                selectedIncidents.clear();
                selectAllChecked = false;
              });

              _loadIncidentTasks();
            },
          );
        } else if (state.verifyTaskErrorMessage != null) {
          showSnackBar(
            context,
            state.verifyTaskErrorMessage!,
            isSuccess: false,
          );
          _cubit.clearVerifyTaskState();
        }

        // Handle PDF export state
        if (state.exportPdfSuccess && state.exportPdfResponse != null) {
          final pdfUrl = state.exportPdfResponse!.pdfUrl;
          _cubit.clearExportPdfState();
          // Open the PDF viewer dialog
          _openPdfViewer(pdfUrl);
        } else if (state.exportPdfErrorMessage != null) {
          showSnackBar(context, state.exportPdfErrorMessage!, isSuccess: false);
          _cubit.clearExportPdfState();
        }
      },
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        appBar: AppBarWidget(showNotificationIcon: false),
        child:
            BlocBuilder<
              ErTeamApproverDashboardCubit,
              ErTeamApproverDashboardState
            >(
              bloc: _cubit,
              builder: (context, state) {
                // Get incidents from API
                final allIncidents = _getIncidentsFromApi(state);

                // Update select all state based on current incidents
                final notVerifiedIncidents = allIncidents
                    .where(
                      (incident) =>
                          incident.status == ErIncidentStatus.notVerified,
                    )
                    .toList();
                if (notVerifiedIncidents.isNotEmpty) {
                  final selectedCount = notVerifiedIncidents
                      .where((incident) => _isIncidentSelected(incident.id))
                      .length;
                  selectAllChecked =
                      selectedCount == notVerifiedIncidents.length &&
                      selectedCount > 0;
                }

                final caseSummary = state.incidentTasksData?.emergexCaseSummary;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // Header Section with Title and Timer
                      _buildHeaderSection(),
                      const SizedBox(height: 16),

                      // Show error message
                      if (state.tasksErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            state.tasksErrorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      // Case Overview Section
                      if (caseSummary != null)
                        CaseOverviewWidget(
                          title: 'EmergeX Case Overview',
                          description: caseSummary.summary.join('\n'),
                        ),
                      const SizedBox(height: 16),

                      // Tab Filter
                      TabFilterWidget(
                        selectedTab: selectedTab,
                        onTabChanged: _handleTabChange,
                      ),
                      const SizedBox(height: 16),

                      // Select All Checkbox
                      // Loader
                      if (state.isLoadingTasks) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ]

                      // Empty state
                      else if (allIncidents.isEmpty) ...[
                        _buildEmptyState(),
                      ]

                      // Task list (ONLY place checkbox here)
                      else ...[
                        Column(
                          children: [

                            // ✅ Select All Checkbox (only when tasks exist)
                            if (_showSelectAllCheckbox) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  border: Border.all(color: Colors.white, width: 0.1),
                                  borderRadius: BorderRadius.circular(44),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomCheckboxWidget(
                                      state: selectAllChecked
                                          ? CheckboxState.checked
                                          : CheckboxState.unchecked,
                                      onChanged: (checkboxState) =>
                                          _handleSelectAll(checkboxState, allIncidents),
                                    ),
                                    Text(
                                      TextHelper.selectAllPendingTask,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: ColorHelper.primaryColor2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Task list
                            Container(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: allIncidents.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final incident = allIncidents[index];
                                  return IncidentCardWidget(
                                    incident: incident,
                                    onSelectionChanged: (isSelected) {
                                      _handleIncidentSelection(incident.id, isSelected);
                                    },
                                  );
                                },
                              ),
                            ),

                            _buildBottomActions(),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Bottom Action Buttons
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }

  /// Get incidents from API data
  List<ErIncidentModel> _getIncidentsFromApi(
    ErTeamApproverDashboardState state,
  ) {
    if (state.incidentTasksData == null) return [];

    final tasksData = state.incidentTasksData!;
    final allIncidents = <ErIncidentModel>[];

    // Convert API tasks to ErIncidentModel
    for (final userTask in tasksData.tasks) {
      for (final task in userTask.tasks) {
        // Map API status to ErIncidentStatus
        ErIncidentStatus status;
        if (task.status == 'Verified') {
          status = ErIncidentStatus.verified;
        } else if (task.status == 'Rejected') {
          status = ErIncidentStatus.rejected;
        } else {
          status = ErIncidentStatus.notVerified;
        }

        // Get submitted by - prefer completedBy, fallback to userId or "Unknown"
        final submittedBy = task.completedBy?.isNotEmpty == true
            ? task.completedBy!
            : (userTask.userId.isNotEmpty ? userTask.userId : 'Unknown');

        // Format submitted date - prefer completedAt, fallback to startedAt
        String submittedDate = 'N/A';
        if (task.completedAt != null && task.completedAt!.isNotEmpty) {
          submittedDate = AppDateUtils.formatDate(task.completedAt!);
        } else if (task.startedAt != null && task.startedAt!.isNotEmpty) {
          submittedDate = AppDateUtils.formatDate(task.startedAt!);
        }

        // Format time elapsed - timeTaken is in seconds from the API
        String timeElapsed = 'N/A';
        if (task.timeTaken != null && task.timeTaken!.isNotEmpty) {
          final seconds = int.tryParse(task.timeTaken!);
          if (seconds != null && seconds > 0) {
            timeElapsed =
                DateTimeFormatter.formatTimeTakenAsDuration(task.timeTaken);
          }
        }


        // Get title with proper fallback
        final title = task.taskName.isNotEmpty
            ? task.taskName
            : (task.taskDetails.isNotEmpty ? task.taskDetails : 'Task');

        final incident = ErIncidentModel(
          id: task.taskId,
          title: title,
          incidentCode: tasksData.incidentId,
          submittedBy: submittedBy,
          submittedDate: submittedDate,
          timeElapsed: timeElapsed,
          status: status,
          isSelected: _isIncidentSelected(task.taskId),
        );

        allIncidents.add(incident);
      }
    }

    return allIncidents;
  }
  

  Widget _buildHeaderSection() {
    return BlocBuilder<
      ErTeamApproverDashboardCubit,
      ErTeamApproverDashboardState
    >(
      bloc: _cubit,
      builder: (context, state) {
        final incidentId =
            state.incidentTasksData?.incidentId ?? widget.incidentId;

        // Get incident timer from API response
        final incidentTimer = state.incidentTasksData?.timer;

        // Build the timer widget based on incident timer state
        Widget timerWidget;

        if (incidentTimer?.startTime != null &&
            incidentTimer!.startTime!.isNotEmpty) {

          // Check if incident is closed (has endTime)
          final bool isIncidentClosed = incidentTimer.endTime != null &&
              incidentTimer.endTime!.isNotEmpty;

          if (isIncidentClosed) {
            // CLOSED INCIDENT: Show static time using timeTaken
            final formattedTime = DateTimeFormatter.formatIncidentTimer(
                  startTime: incidentTimer.startTime,
                  endTime: incidentTimer.endTime,
                  timeTaken: incidentTimer.timeTaken,
                ) ??
                'N/A';
            timerWidget = TimerWidget(
              time: formattedTime,
              status: ErIncidentStatus.verified,
              isMainTimer: true,
            );
          } else {
            // ACTIVE INCIDENT: Show live timer
            try {
              // Parse the UTC start time
              final startTimeUtc = DateTime.parse(incidentTimer.startTime!);
              // Get current UTC time
              final nowUtc = DateTime.now().toUtc();
              // Calculate duration
              final initialDuration = nowUtc.difference(startTimeUtc);

              // Debug logging
              debugPrint('--- INCIDENT TIMER DEBUG ---');
              debugPrint('StartTime (raw): ${incidentTimer.startTime}');
              debugPrint('StartTime (parsed UTC): $startTimeUtc');
              debugPrint('Now (UTC): $nowUtc');
              debugPrint('Duration: ${initialDuration.inHours}h ${initialDuration.inMinutes % 60}m ${initialDuration.inSeconds % 60}s');

              timerWidget = _buildLiveTimerWidget(
                initialDuration.isNegative ? Duration.zero : initialDuration,
              );
            } catch (e) {
              debugPrint('Timer parse error: $e');
              timerWidget = TimerWidget(
                time: 'N/A',
                status: ErIncidentStatus.notVerified,
                isMainTimer: true,
              );
            }
          }
        } else {
          // No timer data available
          timerWidget = TimerWidget(
            time: 'N/A',
            status: ErIncidentStatus.notVerified,
            isMainTimer: true,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Back Arrow (styled)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ColorHelper.white.withValues(alpha: 0.3),
                    border: Border.all(color: ColorHelper.white),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: ColorHelper.black,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      back();
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Title and Timer
                Expanded(
                  child: Row(
                    children: [
                      // LEFT: Title (takes remaining space)
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Incident #$incidentId -\n',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: ColorHelper.organizationStructure,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              TextSpan(
                                text: 'Overview & Approval',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: ColorHelper.organizationStructure,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // RIGHT: Timer (from incident API)
                      timerWidget,
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Green Action Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF3DA229), Color(0xFF147B00)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.push(
                        '${Routes.chatScreen}?incidentId=${widget.incidentId}',
                      );
                    },
                    icon: Image.asset(
                      Assets.chat,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.6), // light green bg
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ColorHelper.white,
        ),
      ),
      child: Center(
        child: Text(
          'No Tasks Available.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }

  /// Build a live timer widget that updates every second
  Widget _buildLiveTimerWidget(Duration startDuration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF005B8B)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: live_timer.TimerWidget(
        startDuration: startDuration,
        timerColor: const Color(0xFF005B8B),
        shouldRun: true,
        showBorder: false,
        iconAsset: Assets.tasktime,
        iconSize: 8,
        padding: EdgeInsets.zero,
        borderWidth: 0,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF005B8B),
          fontSize: 10,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    // Get selected task IDs
    final selectedTaskIds = selectedIncidents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final hasSelectedTasks = selectedTaskIds.isNotEmpty;
    final canVerifyAll = _showSelectAllCheckbox && hasSelectedTasks;

    return BlocBuilder<
      ErTeamApproverDashboardCubit,
      ErTeamApproverDashboardState
    >(
      bloc: _cubit,
      buildWhen: (previous, current) =>
          previous.isVerifyingTask != current.isVerifyingTask ||
          previous.isExportingPdf != current.isExportingPdf,
      builder: (context, state) {
        final isVerifying = state.isVerifyingTask;
        final isExportingPdf = state.isExportingPdf;
        final isLoading = isVerifying || isExportingPdf;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF3CA128)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : _handleExportPdf,
                      borderRadius: BorderRadius.circular(8),
                      child: Center(
                        child: isExportingPdf
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ColorHelper.primaryColor2,
                                ),
                              )
                            : Text(
                                TextHelper.exportAsPdf,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: ColorHelper.primaryColor2,
                                    ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (PermissionHelper.hasEditPermission(
                moduleName: "ER Team Approval",
                featureName: "Status of Report & Report Download",
              ))
                Expanded(
                  child: isVerifying
                      ? const Center(
                          child: SizedBox(
                            height: 40,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      : EmergexButton(
                          text: TextHelper.verifyAll,
                          buttonHeight: 40,
                          textSize: 14,
                          fontWeight: FontWeight.w500,
                          disabled: !canVerifyAll || isLoading,
                          onPressed: canVerifyAll && !isLoading
                              ? () => _handleVerifyAll(selectedTaskIds)
                              : null,
                        ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleVerifyAll(List<String> taskIds) {
    if (taskIds.isEmpty) {
      showSnackBar(
        context,
        'Please select at least one task to verify',
        isSuccess: false,
      );
      return;
    }

    _cubit.verifyTask(
      incidentId: widget.incidentId,
      taskIds: taskIds,
      status: 'Verified',
    );
  }

  void _handleExportPdf() {
    _cubit.exportIncidentPdf(incidentId: widget.incidentId);
  }

  void _openPdfViewer(String pdfUrl) {
    if (pdfUrl.isEmpty) {
      showSnackBar(context, 'Invalid PDF URL', isSuccess: false);
      return;
    }

    // Extract filename from URL or use default
    final fileName = pdfUrl.split('/').last.isNotEmpty
        ? pdfUrl.split('/').last
        : 'incident_${widget.incidentId}.pdf';

    // Open PDF viewer dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: PdfViewerDialog(pdfUrl: pdfUrl, fileName: fileName),
      ),
    );
  }
}
