import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/presentation/onboarding/cubit/splash_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashCubit()..initialize(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: handleSplashState,
        child: AppScaffold(
          showEndDrawer: false,
          child: Image.asset(Assets.splashScreen, fit: BoxFit.fill),
        ),
      ),
    );
  }
}
