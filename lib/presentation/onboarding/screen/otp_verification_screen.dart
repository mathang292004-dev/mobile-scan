import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/onboarding/cubit/password_reset_cubit.dart';
import 'package:emergex/presentation/onboarding/widget/auth_form_card.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_header.dart';
import 'package:emergex/presentation/onboarding/widget/auth_screen_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  @override
  void initState() {
    super.initState();
    AppDI.passwordResetCubit.clearOtpFields();
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
        if (state.status == PasswordResetStatus.otpVerified) {
          openScreen(Routes.resetPassword,clearOldStacks: true);
        } else if (state.status == PasswordResetStatus.error &&
            state.errorSource == 'verifyOtp') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Invalid or expired OTP'),
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
              title: TextHelper.enterYourCode,
              subtitle: BlocBuilder<PasswordResetCubit, PasswordResetState>(
                bloc: cubit,
                buildWhen: (prev, curr) => prev.email != curr.email,
                builder: (context, state) {
                  return Text(
                    '${TextHelper.weSentCodeTo} ${state.email}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: ColorHelper.white),
                  );
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── 6 OTP boxes ─────────────────────────────────────────
                  BlocBuilder<PasswordResetCubit, PasswordResetState>(
                    bloc: cubit,
                    buildWhen: (prev, curr) =>
                        prev.otpUpdateCount != curr.otpUpdateCount,
                    builder: (context, state) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) {
                          final filled =
                              cubit.otpControllers[i].text.isNotEmpty;
                          return SizedBox(
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.13,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (e) => cubit.onOtpKeyEvent(e, i),
                              child: TextFormField(
                                controller: cubit.otpControllers[i],
                                focusNode: cubit.otpFocusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                // No maxLength — Flutter truncates pasted text
                                // to maxLength before onChanged fires, which
                                // breaks paste-to-fill. Length is enforced in
                                // onOtpChanged instead.
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (v) => cubit.onOtpChanged(v, i),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: ColorHelper.surfaceColor,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.015,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: filled
                                          ? ColorHelper.primaryColor
                                          : ColorHelper.surfaceColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: filled
                                          ? ColorHelper.primaryColor
                                          : ColorHelper.surfaceColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: ColorHelper.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.025),

                  // ── Resend row ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        TextHelper.dontReceiveEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColorHelper.textSecondary,
                            ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      GestureDetector(
                        onTap: cubit.handleResend,
                        child: Text(
                          TextHelper.clickToResend,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ColorHelper.textPrimary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // ── Verify button ──────────────────────────────────────
                  BlocBuilder<PasswordResetCubit, PasswordResetState>(
                    bloc: cubit,
                    buildWhen: (prev, curr) =>
                        prev.status != curr.status ||
                        prev.otpUpdateCount != curr.otpUpdateCount,
                    builder: (context, state) {
                      final canVerify =
                          cubit.isOtpComplete && !state.isLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.05,
                        child: EmergexButton(
                          borderRadius: screenWidth * 0.06,
                          onPressed: canVerify
                              ? () => cubit.verifyOtp(cubit.currentOtp)
                              : null,
                          text: TextHelper.verifyOTP,
                          fontWeight: FontWeight.bold,
                          disabled: !canVerify,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }
}
