import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/widgets/feedback/doc_viewer_dialog.dart';
import 'package:emergex/helpers/widgets/feedback/pdf_viewer_dialog.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/file_upload/upload_progress_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Utility class for upload documents screen dialog management
class UploadDocumentsUtils {
  /// Get progress message based on upload progress
  static String getProgressMessage(double progress, {bool isFileUpload = false}) {
    if (isFileUpload) {
      if (progress < 0.3) {
        return 'Preparing files...';
      } else if (progress < 0.6) {
        return 'Uploading files...';
      } else if (progress < 1.0) {
        return 'Processing files...';
      } else {
        return 'Upload complete!';
      }
    } else {
      if (progress < 0.3) {
        return 'Preparing documents...';
      } else if (progress < 0.6) {
        return 'Structuring responsibilities...';
      } else if (progress < 1.0) {
        return 'Analyzing organization structure...';
      } else {
        return 'Upload complete!';
      }
    }
  }

  /// Show upload dialog for document uploads (continue button)
  static void showUploadDialog(
    BuildContext context,
    OnboardingOrganizationStructureCubit cubit,
    Function(BuildContext) onDialogShown,
    VoidCallback onDialogDismissed,
  ) {
    showBlurredDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Call onDialogShown with dialogContext
        onDialogShown(dialogContext);
        return BlocProvider.value(
          value: cubit,
          child: PopScope(
            canPop: false,
            child: BlocBuilder<
              OnboardingOrganizationStructureCubit,
              OnboardingOrganizationStructureState
            >(
              builder: (context, currentState) {
                // Use UploadProgressLoader for document uploads (continue button)
                return UploadProgressLoader(
                  progress: currentState.uploadProgress,
                  message: getProgressMessage(
                    currentState.uploadProgress,
                    isFileUpload: false,
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      onDialogDismissed();
    });
  }

  /// Dismiss upload dialog
  static void dismissUploadDialog(
    BuildContext context,
    BuildContext? dialogContext,
  ) {
    // Try to dismiss using stored dialog context first
    if (dialogContext != null) {
      try {
        if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }
      } catch (e) {
        // Fallback to main context if dialog context fails
        try {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } catch (_) {
          // If both fail, try without rootNavigator
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } else {
      // Fallback: try to pop from main context
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  /// Show PDF viewer in dialog
  static void showPdfViewerDialog(
    BuildContext context,
    String pdfUrl,
    String fileName,
  ) {
    showBlurredDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => PdfViewerDialog(
        pdfUrl: pdfUrl,
        fileName: fileName,
      ),
    );
  }

  /// Open a DOC/DOCX file in-app via Google Docs Viewer (no external app needed).
  static void openDocumentFile(
    BuildContext context,
    String fileUrl,
    String fileName,
  ) {
    showBlurredDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => DocViewerDialog(
        fileUrl: fileUrl,
        fileName: fileName,
      ),
    );
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
