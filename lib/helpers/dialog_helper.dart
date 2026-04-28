import 'dart:ui';

import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_observer.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<T?> showBlurredDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 200),
    useRootNavigator: true,
    pageBuilder:
        (
          BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return Material(
            type: MaterialType.transparency,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.black.withValues(alpha: 0.2),
                child: Center(child: builder(buildContext)),
              ),
            ),
          );
        },
  );
}

Future<void> showVerificationSuccessDialog({
  required BuildContext context,
  required VoidCallback onContinue,
}) {
  return showBlurredDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 🔹 Dialog content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32), // space below icon

                  Text(
                    'Report Approved Successfully!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'The Report has been Approved successfully.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF3DA229),
                            Color(0xFF247814),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onContinue();
                        },
                        child: Text(
                          'Continue',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: -32,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer faded circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x3351AC3F),
                      ),
                    ),

                    // Inner solid circle
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorHelper.primaryColor,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/report_aprovel/success_tick.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showSuccessDialog(
  BuildContext? context,
  VoidCallback onPressPrimary,
  String? incidentId,
) {
  // Use NavObserver to get a safe context instead of the potentially deactivated one
  final safeContext = NavObserver.getCtx() ?? context;
  if (safeContext == null) return;

  CustomDialog.showSuccess(
    context: safeContext,
    incidentId: incidentId,
    title: TextHelper.reportCreatedSuccessfully,
    subtitle: Text(
      TextHelper.reportCreatedSuccessfullyMessage,
      textAlign: TextAlign.center,
      style: Theme.of(safeContext).textTheme.bodyMedium?.copyWith(
        color: ColorHelper.textSecondary,
        height: 1.4,
      ),
    ),
    primaryButtonColor: ColorHelper.primaryColor,
    primaryButtonTextColor: ColorHelper.white,
    primaryButtonBorderColor: ColorHelper.primaryColor,
    onPressed: onPressPrimary,
  );
}

void showErrorDialog(
  BuildContext context,
  VoidCallback? onPrimaryPressed,
  VoidCallback? onSecondaryPressed,
  String? title,
  String? subtitle,
  String? primaryButtonText,
  String? secondaryButtonText,
) {
  CustomDialog.showError(
    context: context,
    title: title ?? '',
    subtitle: Text(
      subtitle ?? '',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: ColorHelper.textSecondary,
        height: 1.4,
      ),
    ),
    primaryButtonText: primaryButtonText ?? '',
    secondaryButtonText: secondaryButtonText ?? '',
    onPrimaryPressed: onPrimaryPressed ?? () => back(),
    onSecondaryPressed: onSecondaryPressed ?? () => back(),
  );
}

void showDeleteFileDialog(BuildContext context, VoidCallback onConfirm) {
  showBlurredDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => CustomDialog(
      context: dialogContext,
      type: DialogType.error,
      title: TextHelper.deleteFile,
      subtitle: Text(
        TextHelper.deleteFileWarning,
        textAlign: TextAlign.center,
        style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
          color: ColorHelper.textSecondary,
          height: 1.4,
        ),
      ),
      primaryButtonText: TextHelper.continueText,
      secondaryButtonText: TextHelper.cancel,
      onPrimaryPressed: () {
        Navigator.pop(dialogContext);
        onConfirm();
      },
      onSecondaryPressed: () => Navigator.pop(dialogContext),
      showCloseButton: true,
    ),
  );
}

void showLeavePageDialog(BuildContext context, VoidCallback onLeave) {
  showBlurredDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => CustomDialog(
      context: dialogContext,
      type: DialogType.error,
      title: TextHelper.areYouWantToLeaveThisPage,
      primaryButtonText: TextHelper.leavePage,
      secondaryButtonText: TextHelper.stayOnThisPage,
      onPrimaryPressed: () {
        Navigator.pop(dialogContext);
        onLeave();
      },
      onSecondaryPressed: () => Navigator.pop(dialogContext),
      showCloseButton: true,
    ),
  );
}

void showSnackBar(
  BuildContext context,
  String message, {
  bool isSuccess = true,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? ColorHelper.successColor : ColorHelper.red,
        content: Text(message),
        action: action,
        duration: duration,
      ),
    );
  }
}
