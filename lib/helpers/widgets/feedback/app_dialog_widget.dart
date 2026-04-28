import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';

enum DialogType { success, error, warning }

class CustomDialog extends StatelessWidget {
  final BuildContext context;
  final DialogType type;
  final String title;
  final Widget? subtitle;
  final List<String>? bulletPoints;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final Color? primaryButtonTextColor;
  final Color? secondaryButtonTextColor;
  final Color? primaryButtonColor;
  final Color? secondaryButtonColor;
  final Color? primaryButtonBorderColor;
  final Color? secondaryButtonBorderColor;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onClosePressed;
  final bool showCloseButton;
  final Color? customColor;
  final double? width;
  final double? height;
  final MainAxisAlignment? buttonAlignment;
  final String? incidentId;

  const CustomDialog({
    super.key,
    required this.context,
    required this.type,
    required this.title,
    this.subtitle,
    this.bulletPoints,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.primaryButtonTextColor,
    this.secondaryButtonTextColor,
    this.primaryButtonColor,
    this.secondaryButtonColor,
    this.primaryButtonBorderColor,
    this.secondaryButtonBorderColor,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.onClosePressed,
    this.showCloseButton = true,
    this.customColor,
    this.width,
    this.height,
    this.buttonAlignment,
    this.incidentId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      elevation: 0,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 40), // leaves space for the icon
            padding: EdgeInsets.symmetric(vertical: 30),
            width: width ?? 400,
            constraints: BoxConstraints(
              maxHeight: height ?? MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // spacing for the icon area
                _buildContent(),
                if (_hasButtons()) _buildButtons(),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Center(
              child: Image.asset(_getIconData(), width: 70, height: 70),
            ),
          ),
        ],
      ),
    );
  }

  String _getIconData() {
    switch (type) {
      case DialogType.success:
        return Assets.successDialog;
      case DialogType.error:
        return Assets.errorDialog;
      case DialogType.warning:
        return Assets.errorDialog;
    }
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (incidentId != null) ...[
            const SizedBox(height: 12),
            Text(
              incidentId!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: ColorHelper.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              color: ColorHelper.textPrimary,
              height: 1.4,
            ),
          ),
          if (subtitle != null) ...[const SizedBox(height: 12), subtitle!],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    bool onlyPrimaryButton =
        primaryButtonText != null && secondaryButtonText == null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: onlyPrimaryButton ? 70 : 32),
      child: Row(
        mainAxisAlignment: buttonAlignment ?? MainAxisAlignment.center,
        children: [
          if (secondaryButtonText != null) ...[
            Expanded(child: _buildSecondaryButton()),
            const SizedBox(width: 16),
          ],
          if (primaryButtonText != null) Expanded(child: _buildPrimaryButton()),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    Color defaultTextColor = Colors.white;

    return EmergexButton(
      onPressed: () => onPrimaryPressed?.call(),
      text: primaryButtonText ?? TextHelper.continueText,
      colors: [ColorHelper.primaryColor, ColorHelper.buttonColor],
      textColor: primaryButtonTextColor ?? defaultTextColor,
      width: double.infinity,
    );
  }

  Widget _buildSecondaryButton() {
    return EmergexButton(
      onPressed: () => onSecondaryPressed?.call(),
      text: secondaryButtonText ?? TextHelper.cancel,
      colors: [Colors.white, Colors.white],
      textColor: ColorHelper.successColor,
      width: double.infinity,
    );
  }

  bool _hasButtons() {
    return primaryButtonText != null || secondaryButtonText != null;
  }

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    Widget? subtitle,
    String primaryButtonText = TextHelper.logOutText,
    String secondaryButtonText = TextHelper.cancelText,
    Color? primaryButtonColor,
    Color? secondaryButtonColor,
    Color? primaryButtonTextColor,
    Color? secondaryButtonTextColor,
    Color? primaryButtonBorderColor,
    Color? secondaryButtonBorderColor,
  }) {
    return showBlurredDialog<bool>(
      context: context,
      builder: (context) => CustomDialog(
        context: context,
        type: DialogType.warning,
        title: title,
        subtitle: subtitle,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        primaryButtonColor: primaryButtonColor ?? ColorHelper.red,
        secondaryButtonColor: secondaryButtonColor ?? ColorHelper.primaryColor,
        primaryButtonTextColor: primaryButtonTextColor ?? Colors.white,
        secondaryButtonTextColor: secondaryButtonTextColor ?? Colors.white,
        primaryButtonBorderColor: primaryButtonBorderColor,
        secondaryButtonBorderColor: secondaryButtonBorderColor,
        onPrimaryPressed: () => back(result: true),
        onSecondaryPressed: () => back(result: false),
        showCloseButton: true,
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    Widget? subtitle,
    String buttonText = TextHelper.continueText,
    Color? primaryButtonColor,
    Color? primaryButtonTextColor,
    Color? primaryButtonBorderColor,
    VoidCallback? onPressed,
    String? incidentId,
  }) {
    return showBlurredDialog(
      context: context,
      builder: (context) => CustomDialog(
        context: context,
        type: DialogType.success,
        incidentId: incidentId,
        title: title,
        subtitle: subtitle,
        primaryButtonText: buttonText,
        primaryButtonColor: primaryButtonColor ?? ColorHelper.successColor,
        primaryButtonTextColor: primaryButtonTextColor ?? Colors.white,
        primaryButtonBorderColor: primaryButtonBorderColor,
        onPrimaryPressed: onPressed ?? () => back(result: true),
        showCloseButton: true,
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    Widget? subtitle,
    List<String>? bulletPoints,
    String primaryButtonText = TextHelper.tryAgainText,
    String secondaryButtonText = TextHelper.startOverText,
    Color? primaryButtonColor,
    Color? primaryButtonTextColor,
    Color? primaryButtonBorderColor,
    Color? secondaryButtonColor,
    Color? secondaryButtonTextColor,
    Color? secondaryButtonBorderColor,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showBlurredDialog(
      context: context,
      builder: (context) => CustomDialog(
        context: context,
        type: DialogType.error,
        title: title,
        subtitle: subtitle,
        bulletPoints: bulletPoints,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        primaryButtonColor: primaryButtonColor ?? ColorHelper.successColor,
        secondaryButtonColor: secondaryButtonColor ?? Colors.white,
        primaryButtonTextColor: primaryButtonTextColor ?? Colors.white,
        secondaryButtonTextColor:
            secondaryButtonTextColor ?? ColorHelper.successColor,
        primaryButtonBorderColor: primaryButtonBorderColor,
        secondaryButtonBorderColor:
            secondaryButtonBorderColor ?? ColorHelper.successColor,
        onPrimaryPressed: onPrimaryPressed ?? () => back(),
        onSecondaryPressed: onSecondaryPressed ?? () => back(),
        showCloseButton: true,
      ),
    );
  }
}
