import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

/// White-bordered card container used by every auth flow screen.
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenHeight * 0.04,
      ),
      decoration: BoxDecoration(
        color: ColorHelper.loginBackground,
        borderRadius: BorderRadius.circular(screenWidth * 0.06),
        border: Border.all(color: ColorHelper.white, width: 1),
      ),
      child: child,
    );
  }
}
