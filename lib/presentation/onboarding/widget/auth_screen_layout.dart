import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:flutter/material.dart';

/// Common scaffold wrapper used by every auth flow screen.
/// Provides: gradient scaffold → scrollable → background image → SafeArea → padded column.
class AuthScreenLayout extends StatelessWidget {
  final Widget child;

  const AuthScreenLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topRight,
      gradientEnd: Alignment.bottomLeft,
      showEndDrawer: false,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Image.asset(Assets.loginScreenImage),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
