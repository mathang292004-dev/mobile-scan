import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/helpers/widgets/inputs/custom_dropdown.dart';
import 'package:emergex/presentation/case_report/approver/cubit/approval_view_manager_cubit.dart';
import 'package:emergex/presentation/case_report/approver/widgets/ai_insights_overlay.dart';
import 'package:emergex/presentation/case_report/approver/widgets/approver_guide_dialog.dart';
import 'package:emergex/presentation/case_report/approver/widgets/incident_approval_view_manager.dart';
import 'package:emergex/presentation/case_report/utils/case_report_navigation_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IncidentApprovalScreen extends StatelessWidget {
  final String incidentId;
  final String? initialDropdownValue;
  final bool isEditRequired;
  final GlobalKey eyeKey = GlobalKey();

  /// `true` when the user reached this screen from the Case Approver
  /// Dashboard. Drives both the back-button destination and any approver-only
  /// affordances inside the view manager.
  final bool isApprover;

  IncidentApprovalScreen({
    super.key,
    required this.incidentId,
    this.initialDropdownValue,
    this.isEditRequired = true,
    this.isApprover = false,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDI.incidentDetailsCubit.getIncidentById(incidentId);
    });

    return BlocProvider(
      create: (_) {
        final cubit = ApprovalViewManagerCubit();
        cubit.initializeFromDropdownValue(initialDropdownValue);
        return cubit;
      },
      child: BlocConsumer<IncidentDetailsCubit, IncidentDetailsState>(
          listener: (context, state) {
            if (state is IncidentDetailsLoaded && state.errorMessage != null) {
              if (state.errorMessage!.isNotEmpty) {
                showSnackBar(context, state.errorMessage!, isSuccess: false);
                AppDI.incidentDetailsCubit.clearErrorMessage();
              }
            }
          },
          builder: (context, state) {
            return BlocBuilder<
              ApprovalViewManagerCubit,
              ApprovalViewManagerState
            >(
              builder: (context, viewState) {
                final viewCubit = context.read<ApprovalViewManagerCubit>();
                final selectedView = viewState.selectedView;
                final currentDropdownValue =
                    ApprovalViewManagerCubit.getCurrentDropdownValue(
                      selectedView,
                    );

                final loaded = state is IncidentDetailsLoaded ? state : null;
                final isCurrentIncident =
                    loaded != null && loaded.incident.incidentId == incidentId;

                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) return;
                    await CaseReportNavigationUtils.handleApprovalBack(
                      context, state, isApprover: isApprover);
                  },
                  child: AppScaffold(
                    useGradient: true,
                    gradientBegin: Alignment.topCenter,
                    gradientEnd: Alignment.bottomCenter,
                    appBar: AppBarWidget(
                      hasNotifications: true,
                      showBottomBackButton: true,
                      bottomTitle: isCurrentIncident
                          ? loaded.incident.incidentId ?? ''
                          : '',
                      bottomTitleSuffix: '– Approval Panel',
                      onPressed: () async => CaseReportNavigationUtils.handleApprovalBack(
                        context, state, isApprover: isApprover),
                      showEyeIcon: true,
                      eyeIconKey: eyeKey,
                      onEyeIconPressed: () => ApproverGuideDialog.show(context, eyeKey),
                    ),
                    floatingActionButton: MovableFloatingButton(onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: ColorHelper.transparent,
                        isScrollControlled: true,
                        builder: (context) =>
                            AiInsightsOverlay(incident: loaded?.incident),
                      );
                    }),
                    child: Stack(
                      // Expand so the MovableFloatingButton (whose internal
                      // Stack only contains Positioned children) inherits the
                      // full body bounds and stays on-screen.
                      fit: StackFit.expand,
                      children: [
                        Column(
                          children: [
                            // Dropdown sits at the top of the screen body
                            // (Figma node 32:103525), not inside the AppBar.
                            if (CaseReportNavigationUtils.shouldShowDropdown(
                                state, incidentId, isEditRequired)) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  6,
                                  16,
                                  6,
                                ),
                                child: CustomDropdown(
                                  items: const [
                                    TextHelper.incident,
                                    TextHelper.intervention,
                                    TextHelper.observation,
                                  ],
                                  initialValue: currentDropdownValue,
                                  isFullWidth: true,
                                  onChanged: (value) async {
                                    await CaseReportNavigationUtils
                                        .handleDropdownChanged(
                                      context,
                                      viewCubit,
                                      state,
                                      value,
                                      incidentId: incidentId,
                                      isEditRequired: isEditRequired,
                                    );
                                  },
                                ),
                              ),
                            ],
                            Expanded(
                              child: IncidentApprovalViewManager(
                                incidentId: incidentId,
                                initialDropdownValue: initialDropdownValue,
                                state: state,
                                isEditRequired: isEditRequired,
                                selectedView: selectedView,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
    );
  }

}
