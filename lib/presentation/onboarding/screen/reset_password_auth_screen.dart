import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/onboarding/cubit/reset_password_auth_cubit.dart';
import 'package:emergex/presentation/onboarding/widget/auth_form_card.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_header.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordAuthScreen extends StatefulWidget {
  const ResetPasswordAuthScreen({super.key});

  @override
  State<ResetPasswordAuthScreen> createState() => _ResetPasswordAuthScreenState();
}

class _ResetPasswordAuthScreenState extends State<ResetPasswordAuthScreen> {
  @override
  void initState() {
    super.initState();
    AppDI.resetPasswordAuthCubit.clearFields();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.resetPasswordAuthCubit;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<ResetPasswordAuthCubit, ResetPasswordAuthState>(
      bloc: cubit,
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ProcessState.done) {
          CustomDialog.showSuccess(
            context: context,
            title: TextHelper.passwordResetSuccessful,
            subtitle: Text(TextHelper.passwordUpdatedSuccessfully),
            buttonText: TextHelper.goToLogin,
            onPressed: () {
              back(); // Close dialog
              cubit.reset();
              context.go(Routes.login);
            },
          );
        } else if (state.status == ProcessState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
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
                      color: ColorHelper.white,
                    ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            AuthFormCard(
              child: Form(
                key: cubit.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(TextHelper.currentPassword, screenWidth),
                    SizedBox(height: screenHeight * 0.01),
                    BlocBuilder<ResetPasswordAuthCubit, ResetPasswordAuthState>(
                      bloc: cubit,
                      buildWhen: (prev, curr) => prev.obscureCurrentPassword != curr.obscureCurrentPassword,
                      builder: (context, state) {
                        return AppTextField(
                          hint: TextHelper.enterYourPassword,
                          controller: cubit.currentPasswordController,
                          obscureText: state.obscureCurrentPassword,
                          validator: cubit.validateCurrentPassword,
                          fillColor: ColorHelper.surfaceColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              state.obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                              color: ColorHelper.textSecondary,
                            ),
                            onPressed: cubit.toggleObscureCurrent,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    _buildLabel(TextHelper.newPassword, screenWidth),
                    SizedBox(height: screenHeight * 0.01),
                    BlocBuilder<ResetPasswordAuthCubit, ResetPasswordAuthState>(
                      bloc: cubit,
                      buildWhen: (prev, curr) => prev.obscureNewPassword != curr.obscureNewPassword,
                      builder: (context, state) {
                        return AppTextField(
                          hint: TextHelper.enterNewPassword,
                          controller: cubit.newPasswordController,
                          obscureText: state.obscureNewPassword,
                          validator: cubit.validateNewPassword,
                          fillColor: ColorHelper.surfaceColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              state.obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                              color: ColorHelper.textSecondary,
                            ),
                            onPressed: cubit.toggleObscureNew,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    _buildLabel(TextHelper.confirmNewPassword, screenWidth),
                    SizedBox(height: screenHeight * 0.01),
                    BlocBuilder<ResetPasswordAuthCubit, ResetPasswordAuthState>(
                      bloc: cubit,
                      buildWhen: (prev, curr) => prev.obscureConfirmPassword != curr.obscureConfirmPassword,
                      builder: (context, state) {
                        return AppTextField(
                          hint: TextHelper.confirmYourPassword,
                          controller: cubit.confirmPasswordController,
                          obscureText: state.obscureConfirmPassword,
                          validator: cubit.validateConfirmPassword,
                          fillColor: ColorHelper.surfaceColor,
                          suffixIcon: IconButton(
                            icon: Icon(
                              state.obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: ColorHelper.textSecondary,
                            ),
                            onPressed: cubit.toggleObscureConfirm,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    BlocBuilder<ResetPasswordAuthCubit, ResetPasswordAuthState>(
                      bloc: cubit,
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.05,
                          child: EmergexButton(
                            borderRadius: screenWidth * 0.06,
                            onPressed: state.status == ProcessState.loading ? null : cubit.handleResetPassword,
                            text: TextHelper.updatePassword,
                            fontWeight: FontWeight.bold,
                            disabled: state.status == ProcessState.loading,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(left: screenWidth * 0.04),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: ColorHelper.textSecondary,
            ),
      ),
    );
  }
}
