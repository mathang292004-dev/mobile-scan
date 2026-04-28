import 'dart:ui';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart' show loaderService;
import 'package:emergex/presentation/user_onboarding/cubit/add_single_user_cubit.dart';
import 'package:emergex/presentation/user_onboarding/widgets/add_single_user_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class AddSingleUserUtils {
  /// Shows the Add Single User dialog with blur backdrop.
  static Future<bool?> showDialog(BuildContext context) {
    AppDI.addSingleUserCubit.resetState();
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'AddSingleUserDialog',
      barrierColor: ColorHelper.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: const Center(child: AddSingleUserDialog()),
        );
      },
    );
  }

  /// Handles the Add User button submit.
  static void handleSubmit(BuildContext context) {
    AppDI.addSingleUserCubit.addUser();
  }

  /// Picks a profile image and updates the cubit.
  static Future<void> pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        AppDI.addSingleUserCubit.setProfileImage(
          file,
          result.files.first.path!,
        );
      }
    } catch (_) {}
  }

  /// Clears the selected profile image.
  static void clearProfileImage() {
    AppDI.addSingleUserCubit.clearProfileImage();
  }

  /// Handles state listener events (loading, success, error).
  static void handleStateChange(
    BuildContext context,
    AddSingleUserState state,
  ) {
    if (state.status == AddSingleUserStatus.loading) {
      loaderService.showLoader();
    } else if (state.status == AddSingleUserStatus.success) {
      loaderService.hideLoader();
      if (context.mounted) {
        // Close the add user dialog first
        back();
        // Show success dialog
        CustomDialog.showSuccess(
          context: context,
          title: TextHelper.userAddedSuccessfully,
        );
        // load users
        AppDI.userManagementCubit.loadUsers();
      }
    } else if (state.status == AddSingleUserStatus.error) {
      loaderService.hideLoader();
      if (context.mounted) {
        CustomDialog.showError(
          context: context,
          title: TextHelper.anErrorOccurred,
          subtitle: Text(
            state.errorMessage ?? TextHelper.anErrorOccurred,
            textAlign: TextAlign.center,
          ),
          primaryButtonText: TextHelper.ok,
          secondaryButtonText: TextHelper.tryAgainText,
          onPrimaryPressed: () {
            // Navigate back to previous screen
            back();
          },
          onSecondaryPressed: () {
            // Try again
            back();
            AppDI.addSingleUserCubit.addUser();
          },
        );
      }
    }
  }
}
