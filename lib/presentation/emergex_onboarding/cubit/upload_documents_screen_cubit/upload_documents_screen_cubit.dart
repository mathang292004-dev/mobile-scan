import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/upload_documents_utils.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UploadDocumentsScreenState {
  final bool isDialogShowing;
  final BuildContext? dialogContext;
  final bool shouldNavigateBackOnDraftComplete;

  const UploadDocumentsScreenState({
    this.isDialogShowing = false,
    this.dialogContext,
    this.shouldNavigateBackOnDraftComplete = false,
  });

  UploadDocumentsScreenState copyWith({
    bool? isDialogShowing,
    BuildContext? dialogContext,
    bool clearDialogContext = false,
    bool? shouldNavigateBackOnDraftComplete,
  }) {
    return UploadDocumentsScreenState(
      isDialogShowing: isDialogShowing ?? this.isDialogShowing,
      dialogContext: clearDialogContext ? null : (dialogContext ?? this.dialogContext),
      shouldNavigateBackOnDraftComplete: shouldNavigateBackOnDraftComplete ?? this.shouldNavigateBackOnDraftComplete,
    );
  }
}

class UploadDocumentsScreenCubit extends Cubit<UploadDocumentsScreenState> {
  final OnboardingOrganizationStructureCubit _organizationCubit;

  UploadDocumentsScreenCubit(this._organizationCubit)
      : super(const UploadDocumentsScreenState());

  OnboardingOrganizationStructureCubit get organizationCubit => _organizationCubit;

  void showDialog(BuildContext context, BuildContext dialogContext) {
    if (state.isDialogShowing) return;

    emit(state.copyWith(
      isDialogShowing: true,
      dialogContext: dialogContext,
    ));
  }

  void _showUploadDialog(BuildContext context) {
    if (state.isDialogShowing) return;

    UploadDocumentsUtils.showUploadDialog(
      context,
      _organizationCubit,
      (dialogContext) {
        // Store dialog context when dialog is shown
        emit(state.copyWith(
          isDialogShowing: true,
          dialogContext: dialogContext,
        ));
      },
      () {
        emit(state.copyWith(
          isDialogShowing: false,
          clearDialogContext: true,
        ));
      },
    );
  }

  void dismissDialog(BuildContext context) {
    if (!state.isDialogShowing) return;

    UploadDocumentsUtils.dismissUploadDialog(context, state.dialogContext);
    emit(state.copyWith(
      isDialogShowing: false,
      clearDialogContext: true,
    ));
  }

  void setShouldNavigateBackOnDraftComplete(bool value) {
    emit(state.copyWith(shouldNavigateBackOnDraftComplete: value));
  }

  void handleStateChanges(
    BuildContext context,
    OnboardingOrganizationStructureState state,
  ) {
    // Show error snackbar
    if (state.processState == ProcessState.error &&
        state.errorMessage != null &&
        state.errorMessage!.isNotEmpty) {
      showSnackBar(context, state.errorMessage!, isSuccess: false);
    }

    // Show upload dialog when document upload starts (continue button)
    if (state.isUploadingDocument && !this.state.isDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentState = _organizationCubit.state;
        if (currentState.isUploadingDocument && !this.state.isDialogShowing) {
          _showUploadDialog(context);
        }
      });
    }

    // Dismiss dialog when document upload completes
    if (!state.isUploadingDocument &&
        this.state.isDialogShowing &&
        state.isLoading == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentState = _organizationCubit.state;
        if (!currentState.isUploadingDocument &&
            !currentState.isLoading &&
            this.state.isDialogShowing) {
          dismissDialog(context);
        }
      });
    }

    // Dismiss dialog when file upload completes
    if (!state.isLoading &&
        !state.isUploadingDocument &&
        this.state.isDialogShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentState = _organizationCubit.state;
        if (!currentState.isLoading &&
            !currentState.isUploadingDocument &&
            this.state.isDialogShowing) {
          dismissDialog(context);
        }
      });
    }

    // Handle navigation back after draft save completes
    if (this.state.shouldNavigateBackOnDraftComplete &&
        !state.isUploadingDocument &&
        !state.isLoading &&
        (state.processState == ProcessState.done ||
            state.processState == ProcessState.error)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentState = _organizationCubit.state;
        if (this.state.shouldNavigateBackOnDraftComplete &&
            !currentState.isUploadingDocument &&
            !currentState.isLoading &&
            (currentState.processState == ProcessState.done ||
                currentState.processState == ProcessState.error)) {
          // Reset flag
          emit(this.state.copyWith(shouldNavigateBackOnDraftComplete: false));
          // Navigate back
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      });
    }
  }
}

