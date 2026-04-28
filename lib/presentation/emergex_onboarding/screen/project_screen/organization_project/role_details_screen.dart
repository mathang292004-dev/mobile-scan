import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_details_cubit/role_details_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/ai_insights_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/organization/role_permissions_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/organization/role_assigned_users_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import '../../../widgets/er_team/org_erteam_header.dart';

class EmployeeTeamScreen extends StatelessWidget {
  final String? roleId;
  const EmployeeTeamScreen({super.key, this.roleId});

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.roleDetailsCubit;

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
            backgroundColor: ColorHelper.textLight.withValues(alpha: 0.2),
            child: SafeArea(
              child: BlocConsumer<RoleDetailsCubit, RoleDetailsState>(
                listener: (context, state) {
                  if (state.processState == ProcessState.loading) {
                    loaderService.showLoader();
                  } else if (state.processState == ProcessState.error ||
                      state.processState == ProcessState.done) {
                    loaderService.hideLoader();
                    if (state.processState == ProcessState.error) {
                      showSnackBar(
                        context,
                        state.errorMessage ?? '',
                        isSuccess: false,
                      );
                    }
                  }
                },
                builder: (context, state) {
                  if (roleId != null &&
                      roleId!.isNotEmpty &&
                      state.processState == ProcessState.none) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      cubit.getRoleDetails(roleId!);
                    });
                  }
                  if (state.processState == ProcessState.error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.errorMessage ?? 'Failed to load role details',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (roleId != null) {
                                cubit.getRoleDetails(roleId!);
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final roleDetails = state.roleDetailsResponse?.roleDetails;
                  final assignedUsers =
                      state.roleDetailsResponse?.assignedUsers ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrganizationHeader(
                        title: roleDetails?.roleName ?? '',
                        onAddPressed: () {},
                        roleId: roleId,
                        showEditAction: true,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildRoleDetails(context, roleDetails),
                              const SizedBox(height: 6),
                              RolePermissionsWidget(
                                roleDetails: roleDetails,
                                isReadOnly: true,
                              ),
                              const SizedBox(height: 16),
                              RoleAssignedUsersWidget(
                                hasAssignedUsers: assignedUsers.isNotEmpty,
                                assignedUsers: assignedUsers,
                                isReadOnly: true,
                                showDeleteIcon: false,
                                projectId: roleDetails?.projectId,
                                roleId: roleId,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          MovableFloatingButton(
            onPressed: () {
              final roleDetails =
                  AppDI.roleDetailsCubit.state.roleDetailsResponse?.roleDetails;
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                builder: (context) {
                  return AiInsightsCard(
                    showAlternateContent: true,
                    aiAnalysis: roleDetails?.aiAnalysis,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDetails(BuildContext context, RoleDetails? roleDetails) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.white.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TextHelper.roledetails,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorHelper.black4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorHelper.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorHelper.white.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleDetails?.roleName ?? 'N/A',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: ColorHelper.textPrimary,
                  ),
                ),
                if (roleDetails?.designation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    roleDetails!.designation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: ColorHelper.textSecondary,
                    ),
                  ),
                ],
                if (roleDetails?.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    roleDetails!.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: ColorHelper.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
