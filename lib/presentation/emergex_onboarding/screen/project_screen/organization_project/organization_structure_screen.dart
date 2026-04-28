import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/organization_structure_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../helpers/text_helper.dart';
import '../../../widgets/er_team/org_erteam_header.dart';
import '../../../widgets/organization/role_card_widget.dart';
import '../../../widgets/common/ai_insights_widget.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.onboardingOrganizationStructureCubit;

    // Listen to global project changes from EmergexAppCubit
    return BlocProvider.value(
      value: cubit,
      child: Stack(
        children: [
          AppScaffold(
            useGradient: true,
            gradientBegin: Alignment.topCenter,
            gradientEnd: Alignment.bottomCenter,
            showDrawer: false,
            appBar: const AppBarWidget(hasNotifications: true),
            showBottomNav: false,
            child: SafeArea(
              child:
                  BlocConsumer<
                    OnboardingOrganizationStructureCubit,
                    OnboardingOrganizationStructureState
                  >(
                    listener: (context, state) {
                      // Handle side effects here (snackbars, dialogs, navigation)
                      if (state.processState == ProcessState.loading) {
                        loaderService.showLoader();
                      } else if (state.processState == ProcessState.done ||
                          state.processState == ProcessState.error) {
                        loaderService.hideLoader();

                        if (state.processState == ProcessState.error) {
                          showSnackBar(
                            context,
                            state.errorMessage!,
                            isSuccess: false,
                          );
                        }
                      }
                    },
                    builder: (context, state) {
                      // Convert cubit roles to map format
                      final rolesData =
                          OrganizationStructureUtils.convertRolesToMap(
                            state.onboardingOrganizationStructure?.roles,
                          );

                      // Use mock data as fallback if no cubit data
                      final displayRoles = rolesData;

                      return RefreshIndicator(
                        onRefresh: () async {
                          // Use local project ID for refresh if available, else global
                          final projectId =
                              cubit.state.selectedProjectId ??
                              AppDI.emergexAppCubit.state.selectedProjectId;
                          if (projectId != null && projectId.isNotEmpty) {
                            cubit.fetchRoles(projectId);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            OrganizationHeader(
                              title: TextHelper.organizationStructure,
                              onBackPressed: () {
                                if (cubit.state.navigationSource ==
                                    'projectListScreen') {
                                  AppDI.projectCubit.refreshProjects();
                                }
                                back();
                              },
                            ),

                            if (state
                                    .onboardingOrganizationStructure
                                    ?.roles
                                    ?.isNotEmpty ==
                                true)
                              Expanded(
                                child: RoleListWidget(roledata: displayRoles),
                              )
                            else
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          Assets.noClientImg,
                                          height: 150,
                                          width: 150,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'No Roles found',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineLarge,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ),

          MovableFloatingButton(
            onPressed: () {
              final cubit = AppDI.onboardingOrganizationStructureCubit;
              final aiInsights = cubit.state.fetchedRoles?.aiInsights;
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                builder: (context) {
                  return AiInsightsCard(
                    showAlternateContent: aiInsights == null,
                    aiInsights: aiInsights,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
