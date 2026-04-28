import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

/// Logo + title + optional subtitle header used by every auth flow screen.
/// [subtitle] accepts any widget so callers can pass plain [Text] or a [BlocBuilder].
class AuthScreenHeader extends StatelessWidget {
  final String title;
  final Widget? subtitle;

  const AuthScreenHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
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
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ColorHelper.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: screenHeight * 0.01),
                subtitle!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
