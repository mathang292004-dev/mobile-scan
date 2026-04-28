import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_observer.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/approver/cubit/approval_view_manager_cubit.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation and action helpers extracted from case_report screens/widgets.
class CaseReportNavigationUtils {
  CaseReportNavigationUtils._();

  // ---------------------------------------------------------------------------
  // Incident approval screen
  // ---------------------------------------------------------------------------

  /// Whether the approval dropdown should display.
  static bool shouldShowDropdown(
    IncidentDetailsState currentState,
    String incidentId,
    bool isEditRequired,
  ) {
    if (!isEditRequired) return false;
    if (currentState is! IncidentDetailsLoaded) return false;
    return currentState.incident.incidentId == incidentId;
  }

  /// Back-button handler for the incident approval screen.
  ///
  /// Navigates to the dashboard the user came from (Case Approver Dashboard
  /// for approver flow, Member Dashboard otherwise).
  static Future<void> handleApprovalBack(
    BuildContext context,
    IncidentDetailsState state, {
    required bool isApprover,
  }) async {
    final hasChanged = await AppDI.incidentDetailsCubit.checkDataChanged();

    void goBackToOriginDashboard() {
      performDashboardSearch();
      if (isApprover) {
        openScreen(Routes.caseApproverDashboard, clearOldStacks: true);
      } else {
        openScreen(Routes.homeScreen, clearOldStacks: true);
      }
    }

    if (hasChanged && context.mounted) {
      showErrorDialog(
        context,
        () {
          AppDI.incidentDetailsCubit.checkDataInitial();
          back();
          goBackToOriginDashboard();
        },
        () => back(),
        TextHelper.areYouSureYouWantToCancelEditedText,
        '',
        TextHelper.yesCancel,
        TextHelper.goBack,
      );
      return;
    }

    if (context.mounted) goBackToOriginDashboard();
  }

  /// Handles dropdown value change on the approval screen.
  static Future<void> handleDropdownChanged(
    BuildContext context,
    ApprovalViewManagerCubit cubit,
    IncidentDetailsState state,
    String? value, {
    required String incidentId,
    required bool isEditRequired,
  }) async {
    if (state is! IncidentDetailsLoaded) return;

    String? targetView;
    if (value == TextHelper.intervention) {
      targetView = 'intervention';
    } else if (value == TextHelper.incident) {
      targetView = 'approval';
    } else if (value == TextHelper.observation) {
      targetView = 'observation';
    }
    if (targetView == null) return;

    final hasChanged = AppDI.incidentDetailsCubit.isAnyEditActive();
    if (hasChanged) {
      showErrorDialog(
        context,
        () async {
          back();
          AppDI.incidentDetailsCubit.checkDataInitial();
          await cubit.switchView(
            targetView!,
            incidentId: incidentId,
            currentState: state,
            isEditRequired: isEditRequired,
          );
        },
        () => back(),
        TextHelper.areYouSureYouWantToCancelEditedText,
        '',
        TextHelper.yesCancel,
        TextHelper.goBack,
      );
      return;
    }

    await cubit.switchView(
      targetView,
      incidentId: incidentId,
      currentState: state,
      isEditRequired: isEditRequired,
    );
  }

  // ---------------------------------------------------------------------------
  // Incident action buttons
  // ---------------------------------------------------------------------------

  /// Shows a cancel-confirmation dialog and navigates home on confirm.
  static void handleActionCancel(BuildContext context) {
    showErrorDialog(
      context,
      () {
        performDashboardSearch();
        back();
        final validContext = NavObserver.getCtx();
        if (validContext != null && validContext.mounted) {
          validContext.go(Routes.homeScreen);
        }
      },
      () => back(),
      TextHelper.areYouSure,
      TextHelper.areYouWantToLeaveThisPage,
      TextHelper.yesCancel,
      TextHelper.goBack,
    );
  }

  /// Submits incident approval after checking tasks and unsaved edits.
  static Future<void> handleActionSubmit(
    BuildContext context, {
    required String? incidentId,
    required String selectedView,
    required IncidentDetails? incidentDetails,
  }) async {
    if (hasIncompleteTasks(incidentDetails)) {
      showSnackBar(
        context,
        'Please complete all assigned tasks before submitting the report',
        isSuccess: false,
      );
      return;
    }

    try {
      final id = incidentId;
      if (id == null || id.isEmpty) {
        if (context.mounted) {
          showSnackBar(context, 'Invalid incident id', isSuccess: false);
        }
        return;
      }

      final dropdownValue = ApprovalViewManagerCubit.getCurrentDropdownValue(
        selectedView,
      );
      final hasChanged = await AppDI.incidentDetailsCubit.checkDataChanged();

      if (hasChanged && context.mounted) {
        showErrorDialog(
          context,
          () async {
            back();
            final ok = await AppDI.incidentDetailsCubit.incidentApproval(
              id,
              dropdownValue,
            );
            if (ok) {
              showSuccessDialog(null, () {
                AppDI.incidentDetailsCubit.checkDataInitial();
                back();
                performDashboardSearch();
                final validContext = NavObserver.getCtx();
                if (validContext != null && validContext.mounted) {
                  validContext.go(Routes.homeScreen);
                }
              }, id);
            } else {
              context.mounted
                  ? showSnackBar(
                      context,
                      'Failed to approve incident. Please try again later',
                      isSuccess: false,
                    )
                  : null;
            }
          },
          () => back(),
          TextHelper.areYouSureYouWantToCancelEditedText,
          '',
          TextHelper.yesCancel,
          TextHelper.goBack,
        );
        return;
      }

      final ok = await AppDI.incidentDetailsCubit.incidentApproval(
        id,
        dropdownValue,
      );
      if (ok) {
        showSuccessDialog(null, () {
          performDashboardSearch();
          final validContext = NavObserver.getCtx();
          if (validContext != null && validContext.mounted) {
            validContext.go(Routes.homeScreen);
            back();
          }
        }, id);
      } else {
        context.mounted
            ? showSnackBar(
                context,
                'Failed to approve incident. Please try again later',
                isSuccess: false,
              )
            : null;
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(
        context,
        'Something went wrong. Please try again later',
        isSuccess: false,
      );
    }
  }
}
