import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/onboarding/cubit/password_reset_cubit.dart';
import 'package:emergex/presentation/onboarding/widget/auth_form_card.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_header.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    AppDI.passwordResetCubit.reset();
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
        if (state.status == PasswordResetStatus.otpSent) {
          openScreen(Routes.otpVerification);
        } else if (state.status == PasswordResetStatus.error &&
            state.errorSource == 'sendOtp') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to send OTP'),
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
              title: TextHelper.forgotPasswordTitle,
              subtitle: Text(
                TextHelper.forgotPasswordSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorHelper.white.withValues(),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            AuthFormCard(
              child: Form(
                key: _emailFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
                      child: Text(
                        TextHelper.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    AppTextField(
                      hint: TextHelper.enterYourEmail,
                      controller: cubit.emailController,
                      keyboardType: TextInputType.emailAddress,
                      fillColor: ColorHelper.surfaceColor,
                      textInputAction: TextInputAction.done,
                      validator: cubit.validateEmail,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    BlocBuilder<PasswordResetCubit, PasswordResetState>(
                      bloc: cubit,
                      buildWhen: (prev, curr) => prev.status != curr.status,
                      builder: (context, state) {
                        return SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.05,
                          child: EmergexButton(
                            borderRadius: screenWidth * 0.06,
                            onPressed: state.isLoading
                                ? null
                                : () => cubit.validateAndSendOtp(_emailFormKey),
                            text: TextHelper.confirm,
                            fontWeight: FontWeight.bold,
                            disabled: state.isLoading,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: ColorHelper.primaryColor,
                              size: screenHeight * 0.02,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              TextHelper.backToLogin,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ColorHelper.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
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
}
