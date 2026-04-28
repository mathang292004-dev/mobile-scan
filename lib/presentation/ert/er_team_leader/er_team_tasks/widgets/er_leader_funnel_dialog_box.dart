import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/cubit/er_leader_filter_cubit.dart';
import 'package:emergex/di/app_di.dart';

class ErLeaderFunnelDialogBox extends StatelessWidget {
  final Function({
    String? project,
    String? title,
    String? status,
    List<String>? severityLevels,
    String? priority,
  })?
  onApplyFilters;

  const ErLeaderFunnelDialogBox({super.key, this.onApplyFilters});

  static Future<void> show(
    BuildContext context, {
    Function({
      String? project,
      String? title,
      String? status,
      List<String>? severityLevels,
      String? priority,
    })?
    onApplyFilters,
  }) async {
    // Get current filters from dashboard cubit
    final currentFilters = AppDI.erTeamLeaderDashboardCubit.state.filters;
    final initialState = ErLeaderFilterState.fromDashboardFilters(
      currentFilters,
    );

    await showBlurredDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => ErLeaderFilterCubit(initialState: initialState),
        child: ErLeaderFunnelDialogBox(onApplyFilters: onApplyFilters),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final severityOptions = ['Low', 'Medium', 'High'];

    return AlertDialog(
      backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(16),
      insetPadding: const EdgeInsets.all(3),
      content: SizedBox(
        width: 600,
        child: BlocBuilder<ErLeaderFilterCubit, ErLeaderFilterState>(
          builder: (context, state) {
            final cubit = context.read<ErLeaderFilterCubit>();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DialogTitleBar(title: "Filters", onClose: () => back()),
                  const SizedBox(height: 8),
                  _buildSectionLabel(context, 'Severity Level'),
                  const SizedBox(height: 10),

                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(35),
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: ColorHelper.white,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: ColorHelper.white, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: state.selectedSeverities.isEmpty
                                    ? [
                                        Text(
                                          'Select Severities',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: ColorHelper.selectstatus
                                                    .withValues(alpha: 0.5),
                                              ),
                                        ),
                                      ]
                                    : state.selectedSeverities.map((sev) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ColorHelper.primaryColor
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                sev,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: ColorHelper
                                                          .primaryColor,
                                                    ),
                                              ),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () {
                                                  cubit.removeSeverity(sev);
                                                },
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color:
                                                      ColorHelper.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                              ),
                            ),
                          ),
                          IconButton(
                            iconSize: 32,
                            icon: Icon(
                              state.showSeverityList
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: ColorHelper.primaryColor,
                            ),
                            onPressed: () {
                              cubit.toggleSeverityList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state.showSeverityList) ...[
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: ColorHelper.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: ColorHelper.white,
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Column(
                        children: severityOptions.map((sev) {
                          final isSelected = state.selectedSeverities.contains(
                            sev,
                          );
                          return CheckboxListTile(
                            title: Text(
                              sev,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? ColorHelper.black
                                        : ColorHelper.black,
                                  ),
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              cubit.toggleSeverity(sev);
                            },
                            activeColor: ColorHelper.primaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EmergexButton(
                        text: TextHelper.reset,
                        onPressed: () {
                          cubit.reset();
                          AppDI.erTeamLeaderDashboardCubit.resetFiltersOnly();

                          back();
                        },
                        borderRadius: 35,
                        colors: [ColorHelper.white, ColorHelper.white],
                        fontWeight: FontWeight.w600,
                        textColor: ColorHelper.primaryColor,
                        borderColor: ColorHelper.white,
                        textSize: 14,
                      ),

                      const SizedBox(width: 16),
                      EmergexButton(
                        text: TextHelper.applyFilters,
                        onPressed: cubit.shouldAllowApply()
                            ? () {
                                // Get filter values - explicitly pass null for empty values
                                final project =
                                    state.project != null &&
                                        state.project!.trim().isNotEmpty
                                    ? state.project!.trim()
                                    : null;
                                final title =
                                    state.title != null &&
                                        state.title!.trim().isNotEmpty
                                    ? state.title!.trim()
                                    : null;
                                final severityLevels =
                                    state.selectedSeverities.isNotEmpty
                                    ? state.selectedSeverities.toList()
                                    : null;

                                // Use explicit apply to ensure cleared values are properly applied
                                AppDI.erTeamLeaderDashboardCubit
                                    .applyFiltersExplicit(
                                      project: project,
                                      title: title,
                                      status: state.selectedStatus,
                                      severityLevels: severityLevels,
                                      priority: state.selectedPriority,
                                    );

                                // Also call the callback if provided (for backward compatibility)
                                onApplyFilters?.call(
                                  project: project,
                                  title: title,
                                  status: state.selectedStatus,
                                  severityLevels: severityLevels,
                                  priority: state.selectedPriority,
                                );
                                back();
                              }
                            : null,
                        disabled: !cubit.shouldAllowApply(),
                        borderRadius: 35,
                        colors: [ColorHelper.green, ColorHelper.green],
                        textSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: ColorHelper.grey4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
