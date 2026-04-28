import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/preference_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';

class NoAccessScreen extends StatelessWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final PreferenceHelper preferenceHelper = PreferenceHelper();
    return AppScaffold(
      useGradient: true,
      showEndDrawer: false,
      gradientBegin: Alignment.topRight,
      gradientEnd: Alignment.bottomLeft,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image placeholder - you can replace with an appropriate asset
                Icon(
                  Icons.lock_outline,
                  size: 120,
                  color: ColorHelper.textSecondary,
                ),
                SizedBox(height: screenHeight * 0.04),
                // Title
                Text(
                  TextHelper.noAccess,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorHelper.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02),
                // Message
                Text(
                  TextHelper.noScreenToAccess,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ColorHelper.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.06),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.05,
                  child: EmergexButton(
                    borderRadius: screenWidth * 0.06,
                    onPressed: () async {
                      await preferenceHelper.removeUserToken();
                      await preferenceHelper.removeRefreshToken();
                      openScreen(Routes.login, clearOldStacks: true);
                    },
                    text: TextHelper.logOutText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
