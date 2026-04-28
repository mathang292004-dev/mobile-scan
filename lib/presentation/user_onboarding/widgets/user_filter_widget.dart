import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/user_onboarding/cubit/user_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserFilterWidget extends StatelessWidget {
  const UserFilterWidget({super.key});

  static UserFilterState? _getInitialFilterState() {
    final mgmtState = AppDI.userManagementCubit.state;
    if (mgmtState.filterName.isEmpty &&
        mgmtState.filterRole.isEmpty &&
        mgmtState.filterEmail.isEmpty &&
        mgmtState.filterProject.isEmpty) {
      return null;
    }
    return UserFilterState(
      userName: mgmtState.filterName,
      role: mgmtState.filterRole,
      mailId: mgmtState.filterEmail,
      project: mgmtState.filterProject,
    );
  }

  static Future<void> show(BuildContext context) async {
    final initialState = _getInitialFilterState();
    await showBlurredDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (_) => UserFilterCubit(initialState: initialState),
        child: const UserFilterWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: ColorHelper.white, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        insetPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 500,
          child: BlocBuilder<UserFilterCubit, UserFilterState>(
            builder: (context, state) {
              final cubit = context.read<UserFilterCubit>();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Filters + Reset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TextHelper.filters,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: ColorHelper.black4,
                        ),
                      ),
                     GestureDetector(
                      onTap: () {
                        back();
                      },
                      child: Icon(
                        Icons.cancel_outlined,
                        color: ColorHelper.black4,
                      ),
                     )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // EmergeX Users
                  _buildSectionLabel(context, TextHelper.emergeXUsers),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: cubit.userNameController,
                    hint: TextHelper.enterEmergeXUsers,
                    onChanged: cubit.updateUserName,
                    fillColor: ColorHelper.white.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide(
                        color: ColorHelper.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role
                  _buildSectionLabel(context, TextHelper.role),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: cubit.roleController,
                    hint: TextHelper.enterRole,
                    onChanged: cubit.updateRole,
                    fillColor: ColorHelper.white.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide(
                        color: ColorHelper.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mail ID
                  _buildSectionLabel(context, TextHelper.mailId),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: cubit.mailIdController,
                    hint: TextHelper.enterMailId,
                    onChanged: cubit.updateMailId,
                    fillColor: ColorHelper.white.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide(
                        color: ColorHelper.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Project
                  _buildSectionLabel(context, TextHelper.projects),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: cubit.projectController,
                    hint: TextHelper.enterProject,
                    onChanged: cubit.updateProject,
                    fillColor: ColorHelper.white.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                      borderSide: BorderSide(
                        color: ColorHelper.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Apply Filters Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EmergexButton(
                        text: TextHelper.reset,
                        borderRadius: 24,
                        fontWeight: FontWeight.w600,
                        textColor: ColorHelper.primaryColor,
                        colors: [
                          ColorHelper.surfaceColor,
                          ColorHelper.surfaceColor,
                        ],
                        borderColor: ColorHelper.transparent,
                        onPressed: () {
                          if (cubit.isInitialStateEmpty()) {
                            back();
                          } else {
                            cubit.resetFilters();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      EmergexButton(
                        text: TextHelper.applyFilters,
                        width: 180,
                        buttonHeight: 40,
                        onPressed: cubit.hasChanges()
                            ? () => cubit.applyFilters()
                            : null,
                        disabled: !cubit.hasChanges(),
                        borderRadius: 24,
                        fontWeight: FontWeight.w600,
                      ),
                     
                    ],
                  ),
                ],
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
        color: ColorHelper.dateStatusColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
