import 'package:flutter/material.dart';

class NavObserver extends NavigatorObserver {
  NavObserver._();

  static NavObserver instance = NavObserver._();

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navKey.currentContext;

  static BuildContext? getCtx([BuildContext? ctx]) {
    return navKey.currentContext ?? ctx;
  }
} 