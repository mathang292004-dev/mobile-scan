import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart' show loaderService;
import 'package:emergex/presentation/user_onboarding/cubit/user_management_cubit.dart';
import 'package:emergex/presentation/user_onboarding/cubit/user_management_state.dart';
import 'package:emergex/presentation/user_onboarding/utils/add_single_user_utils.dart';
import 'package:emergex/presentation/user_onboarding/widgets/add_multi_user_dialog.dart';
import 'package:emergex/presentation/user_onboarding/widgets/add_user_options_dialog.dart';
import 'package:flutter/material.dart';

class UserManagementUtils {
  /// Handles cubit state changes — show/hide loader, show error snackbar.
  static void handleStateChange(
    BuildContext context,
    UserManagementState state,
  ) {
    if (state.processState == UserManagementProcessState.loading) {
      loaderService.showLoader();
    } else {
      loaderService.hideLoader();
      if (state.processState == UserManagementProcessState.error &&
          state.errorMessage != null &&
          state.errorMessage!.isNotEmpty &&
          context.mounted) {
        showSnackBar(context, state.errorMessage!, isSuccess: false);
      }
    }
  }

  /// Shows the add user options dialog (single / multi).
  static void showAddUserOptionsDialog(BuildContext context) {
    final cubit = AppDI.userManagementCubit;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddUserOptionsDialog(
        onAddSingleUser: () => showAddSingleUserDialog(ctx, cubit),
        onUploadMultiUser: () => showAddMultiUserDialog(ctx, cubit),
      ),
    );
  }

  /// Shows the add single user dialog.
  static void showAddSingleUserDialog(
    BuildContext context,
    UserManagementCubit cubit,
  ) {
    AddSingleUserUtils.showDialog(context).then((result) {
      if (result == true) cubit.loadUsers();
    });
  }

  /// Shows the add multiple users dialog.
  static void showAddMultiUserDialog(
    BuildContext context,
    UserManagementCubit cubit,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddMultiUserDialog(),
    ).then((result) {
      if (result == true) cubit.loadUsers();
    });
  }

  /// Confirms and deletes a user.
  static void confirmDeleteUser(
    BuildContext context,
    String userId,
  ) {
    final cubit = AppDI.userManagementCubit;
    showErrorDialog(
      context,
      () async {
        back();
        final success = await cubit.deleteUser(userId);
        if (context.mounted) {
          if (success) {
            showSnackBar(context, TextHelper.userDeletedSuccessfully,
                isSuccess: true);
          } else {
            showSnackBar(context, TextHelper.failedToDeleteUser,
                isSuccess: false);
          }
        }
      },
      () => back(),
      TextHelper.areyousure,
      TextHelper.userError,
      TextHelper.delete,
      TextHelper.cancel,
    );
  }

  /// Formats a number with comma separator for display.
  static String formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }

}
