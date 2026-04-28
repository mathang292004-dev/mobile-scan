import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';

class IncidentErrorState extends StatelessWidget {
  final String? incidentId;
  final String errorMessage;

  const IncidentErrorState({
    super.key,
    this.incidentId,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, dashboardState) {
        return BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
          builder: (context, incidentState) {
            final isDashboardLoading = dashboardState is DashboardLoaded &&
                dashboardState.processState == ProcessState.loading;
            final isIncidentLoading = incidentState is IncidentDetailsLoading;
            final isLoading = isDashboardLoading || isIncidentLoading;
            final isOnline = dashboardState is DashboardLoaded
                ? dashboardState.isOnline
                : true;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Image.asset(Assets.networkError),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isOnline
                        ? TextHelper.networkError
                        : TextHelper.noInternetConnection,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: ColorHelper.successColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOnline
                        ? errorMessage
                        : TextHelper.checkInternetConnection,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (isOnline) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 120.0),
                      child: EmergexButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                AppDI.dashboardCubit.loadInitialData();
                                AppDI.incidentDetailsCubit.clearCache();
                                if (incidentId != null &&
                                    incidentId!.isNotEmpty) {
                                  AppDI.incidentDetailsCubit.getIncidentById(
                                    incidentId!,
                                  );
                                }
                              },
                        text: isLoading
                            ? TextHelper.loading
                            : TextHelper.reload,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
