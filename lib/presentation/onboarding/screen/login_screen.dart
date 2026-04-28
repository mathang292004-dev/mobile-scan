import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/onboarding/cubit/login_cubit.dart';
import 'package:emergex/presentation/onboarding/utils/onboarding_utils.dart';
import 'package:emergex/helpers/widgets/inputs/toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final cubit = AppDI.loginCubit;

    return AppScaffold(
      showDrawer: false,
      showEndDrawer: false,
      useGradient: true,
      gradientBegin: Alignment.topRight,
      gradientEnd: Alignment.bottomLeft,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Image.asset(Assets.loginScreenImage),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Form(
                  key: cubit.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.04),
                        child: Image.asset(
                          Assets.loginLogo,
                          height: screenHeight * 0.045,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.01,
                          top: screenHeight * 0.25,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TextHelper.niceToSeeYouAgain,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: ColorHelper.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              TextHelper
                                  .logInToAccessEmergencyResponseCoordination,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.white.withValues(),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.04,
                        ),
                        decoration: BoxDecoration(
                          color: ColorHelper.loginBackground,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.06,
                          ),
                          border: Border.all(
                            color: ColorHelper.white,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: screenWidth * 0.04,
                              ),
                              child: Text(
                                TextHelper.email,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            AppTextField(
                              hint: TextHelper.enterYourEmail,
                              controller: cubit.emailController,
                              keyboardType: TextInputType.emailAddress,
                              fillColor: ColorHelper.surfaceColor,
                              textInputAction: TextInputAction.next,
                              validator: OnboardingUtils.validateEmail,
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Padding(
                              padding: EdgeInsets.only(
                                left: screenWidth * 0.04,
                              ),
                              child: Text(
                                TextHelper.password,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            BlocBuilder<LoginCubit, EmergexAppState>(
                              bloc: cubit,
                              builder: (context, state) {
                                return AppTextField(
                                  hint: TextHelper.enterYourPassword,
                                  controller: cubit.passwordController,
                                  obscureText: state.isPasswordVisible,
                                  fillColor: ColorHelper.surfaceColor,
                                  textInputAction: TextInputAction.done,
                                  validator: OnboardingUtils.validatePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      state.isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: ColorHelper.textSecondary,
                                    ),
                                    onPressed: cubit.togglePasswordVisibility,
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            BlocBuilder<LoginCubit, EmergexAppState>(
                              bloc: cubit,
                              builder: (context, state) {
                                return Row(
                                  children: [
                                    ToggleButton(
                                      handleToggle: (_) =>
                                          cubit.toggleRememberMe(),
                                      checked: state.rememberMe,
                                      innerCircleColor:
                                          ColorHelper.primaryColor,
                                    ),
                                    SizedBox(width: screenWidth * 0.04),
                                    Expanded(
                                      child: Text(
                                        TextHelper.rememberMe,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorHelper.textPrimary,
                                            ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        openScreen(Routes.forgotPassword);
                                      },
                                      child: Text(
                                        TextHelper.forgotPasswordLogin,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorHelper.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            SizedBox(
                              width: double.infinity,
                              height: screenHeight * 0.05,
                              child: EmergexButton(
                                borderRadius: screenWidth * 0.06,
                                onPressed: () => cubit.handleLogin(context),
                                text: TextHelper.loginButtonLabel,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
