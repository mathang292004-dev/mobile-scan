import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/investigation/tl_team_setup/cubit/investigation_team_setup_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvestigationTeamSetupScreen extends StatelessWidget {
  const InvestigationTeamSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load team data if not already loaded
    final cubit = AppDI.investigationTeamSetupCubit;
    if (cubit.state.teamMembers.isEmpty &&
        cubit.state.processState != ProcessState.loading) {
      cubit.loadTeam();
    }

    return BlocProvider.value(
      value: AppDI.investigationTeamSetupCubit,
      child: AppScaffold(
        useGradient: true,
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        showDrawer: false,
        appBar: const AppBarWidget(
          title: TextHelper.investigationTeamSetup,
          showBackButton: true,
          hasNotifications: true,
        ),
        showBottomNav: false,
        child: BlocConsumer<InvestigationTeamSetupCubit,
            InvestigationTeamSetupState>(
          listener: (context, state) {
            if (state.processState == ProcessState.error &&
                state.errorMessage != null &&
                state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            if (state.processState == ProcessState.loading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ColorHelper.primaryColor,
                ),
              );
            }

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TextHelper.teamMembers,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.teamMembers.length} members assigned',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ColorHelper.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: state.teamMembers.isEmpty
                            ? Center(
                                child: Text(
                                  TextHelper.noDataYet,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: ColorHelper.textSecondary,
                                      ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: state.teamMembers.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final member = state.teamMembers[index];
                                  return _buildTeamMemberCard(
                                      context, member);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      // Add member action — UI only
                      if (state.availableMembers.isNotEmpty) {
                        AppDI.investigationTeamSetupCubit
                            .addMember(state.availableMembers.first['id']!);
                      }
                    },
                    backgroundColor: ColorHelper.primaryColor,
                    icon: const Icon(Icons.add, color: ColorHelper.white),
                    label: Text(
                      TextHelper.addMember,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ColorHelper.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(
      BuildContext context, Map<String, String> member) {
    return AppContainer(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ColorHelper.primaryColor.withValues(alpha: 0.15),
            child: Text(
              (member['name'] ?? 'U')[0].toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ColorHelper.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['role'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['email'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorHelper.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member['status'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  AppDI.investigationTeamSetupCubit
                      .removeMember(member['id'] ?? '');
                },
                child: Text(
                  TextHelper.removeMember,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorHelper.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
