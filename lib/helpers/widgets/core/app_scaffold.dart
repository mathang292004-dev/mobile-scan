import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_drawer_widget.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool showDrawer;
  final bool showEndDrawer;
  final Widget? floatingActionButton;
  final Widget? bottomSheet;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool useGradient;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool showBottomNav;
  final int? navSelectedIndex;

  const AppScaffold({
    super.key,
    required this.child,
    this.floatingActionButton,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.showDrawer = false,
    this.showEndDrawer = true,
    this.bottomSheet,
    this.appBar,
    this.backgroundColor,
    this.foregroundColor,
    this.useGradient = false,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.showBottomNav = false,
    this.navSelectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    Widget scaffoldBody = child;

    // Apply gradient background if requested
    if (useGradient) {
      scaffoldBody = Container(
        decoration: BoxDecoration(
          gradient: useGradient
              ? LinearGradient(
                  begin: gradientBegin ?? Alignment.topRight,
                  end: gradientEnd ?? Alignment.bottomLeft,
                  colors:
                      gradientColors ??
                      [
                        ColorHelper.primaryBackground,
                        ColorHelper.secondaryBackground,
                      ],
                )
              : null,
        ),
        child: child,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar:
          appBar ??
          (title != null
              ? AppBarWidget(title: title!, actions: actions ?? [])
              : null),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: useGradient
              ? LinearGradient(
                  begin: gradientBegin ?? Alignment.topRight,
                  end: gradientEnd ?? Alignment.bottomLeft,
                  colors:
                      gradientColors ??
                      [
                        ColorHelper.primaryBackground,
                        ColorHelper.secondaryBackground,
                      ],
                )
              : null,
        ),
        child: GestureDetector(
          // Use onTap instead of onTapDown for more reliable focus handling
          // Use UnfocusDisposition.scope to ensure complete focus removal
          // This prevents the keyboard from reappearing when drawer opens
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: scaffoldBody,
        ),
      ),
      drawer: showDrawer ? drawer : null,
      endDrawer: showEndDrawer ? (endDrawer ?? const AppDrawerWidget()) : null,
      drawerEnableOpenDragGesture: showDrawer,
      endDrawerEnableOpenDragGesture: showEndDrawer,
      // Fix: Unfocus any text fields when drawer opens (handles swipe gesture)
      // This prevents the search bar from auto-focusing when drawer opens via swipe
      onEndDrawerChanged: showEndDrawer
          ? (bool isOpened) {
              if (isOpened) {
                // Clear focus when drawer opens - works for both swipe AND button tap
                final currentFocus = FocusManager.instance.primaryFocus;
                if (currentFocus != null && currentFocus.hasFocus) {
                  currentFocus.unfocus();
                }
              }
            }
          : null,
      floatingActionButton: floatingActionButton,
      bottomSheet: bottomSheet,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }

  Widget appTitle(BuildContext context) {
    return Column(children: [
        
      ],
    );
  }
}
