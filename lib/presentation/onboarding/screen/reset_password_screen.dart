import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/onboarding/cubit/password_reset_cubit.dart';
import 'package:emergex/presentation/onboarding/widget/auth_form_card.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_header.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    AppDI.passwordResetCubit.clearPasswordFields();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.passwordResetCubit;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<PasswordResetCubit, PasswordResetState>(
      bloc: cubit,
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == PasswordResetStatus.passwordUpdated) {
          CustomDialog.showSuccess(
            context: context,
            title: TextHelper.passwordResetSuccessful,
            subtitle: Text(TextHelper.passwordUpdatedSuccessfully),
            buttonText: TextHelper.goToLogin,
            onPressed: () {
              back();
              AppDI.passwordResetCubit.reset();
              context.go(Routes.login);
            },
          );
        } else if (state.status == PasswordResetStatus.error &&
            state.errorSource == 'updatePassword') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Failed to update password. Try again.',
              ),
              backgroundColor: ColorHelper.errorColor,
            ),
          );
        }
      },
      child: AuthScreenLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthScreenHeader(
              title: TextHelper.resetYourPassword,
              subtitle: Text(
                TextHelper.createNewPassword,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.white.withValues(),
                    ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            BlocBuilder<PasswordResetCubit, PasswordResetState>(
              bloc: cubit,
              buildWhen: (prev, curr) =>
                  prev.status != curr.status ||
                  prev.obscureNewPassword != curr.obscureNewPassword ||
                  prev.obscureConfirmPassword != curr.obscureConfirmPassword,
              builder: (context, state) {
                return AuthFormCard(
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.01),

                        // ── New Password ─────────────────────────────────
                        Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.04),
                          child: Text(
                            TextHelper.newPassword,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AppTextField(
                            hint: TextHelper.enterNewPassword,
                            controller: cubit.newPasswordController,
                            obscureText: state.obscureNewPassword,
                            fillColor: ColorHelper.surfaceColor,
                            textInputAction: TextInputAction.next,
                            validator: cubit.validateNewPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                state.obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: ColorHelper.textSecondary,
                              ),
                              onPressed: cubit.toggleObscureNew,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),

                        // ── Confirm Password ─────────────────────────────
                        Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.04),
                          child: Text(
                            TextHelper.confirmNewPassword,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AppTextField(
                            hint: TextHelper.confirmYourPassword,
                            controller: cubit.confirmPasswordController,
                            obscureText: state.obscureConfirmPassword,
                            fillColor: ColorHelper.surfaceColor,
                            textInputAction: TextInputAction.done,
                            validator: cubit.validateConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                state.obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: ColorHelper.textSecondary,
                              ),
                              onPressed: cubit.toggleObscureConfirm,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // ── Submit button ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.05,
                          child: EmergexButton(
                            borderRadius: screenWidth * 0.06,
                            onPressed: state.isLoading
                                ? null
                                : () => cubit.validateAndUpdatePassword(_passwordFormKey),
                            text: TextHelper.updatePassword,
                            fontWeight: FontWeight.bold,
                            disabled: state.isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }
}
