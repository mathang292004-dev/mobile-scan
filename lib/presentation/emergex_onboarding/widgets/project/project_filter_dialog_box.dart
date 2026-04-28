import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/project_view_cubit/project_filter_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/client_utils.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:emergex/presentation/emergex_onboarding/widgets/common/custom_drop_down_field.dart';

class ProjectFilterDialog extends StatelessWidget {
  const ProjectFilterDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final initialState = ClientUtils.getInitialProjectFilterState();

    await showBlurredDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => ProjectFilterCubit(initialState: initialState),
        child: const ProjectFilterDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = ['Active', 'InActive'];
    final workSites = AppDI.projectCubit.state.workSites;
    final locations = AppDI.projectCubit.state.locations;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: ColorHelper.white, width: 2),
        ),
        contentPadding: const EdgeInsets.only(
          top: 10,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        insetPadding: const EdgeInsets.all(2),
        content: SizedBox(
          width: 600,
          height: 750,
          child: BlocBuilder<ProjectFilterCubit, ProjectFilterState>(
            builder: (context, state) {
              final cubit = context.read<ProjectFilterCubit>();

              return Column(
                children: [
                  DialogTitleBar(
                    title: TextHelper.filters,
                    onClose: () => back(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildSectionLabel(context, 'Status'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: CustomDropdownField<String>(
                              fieldHeight: 30,
                              hintText: 'Select Status',
                              value: state.selectedStatus,
                              items: statusOptions,
                              onChanged: (value) => cubit.setStatus(value),
                              fillColor: ColorHelper.white,
                              labelBuilder: (item) => item == 'InActive' ? 'Inactive' : item,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel(context, 'Project ID'),
                          const SizedBox(height: 10),
                          AppTextField(
                            hint: "Enter Project ID",

                            controller: cubit.projectIdController,
                            fillColor: ColorHelper.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(35),
                              borderSide: const BorderSide(
                                color: ColorHelper.white,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            onChanged: (value) => cubit.setProjectId(value),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel(context, 'Date'),
                          const SizedBox(height: 10),
                          _buildTextFieldLabel(context, 'From'),
                          const SizedBox(height: 8),
                          _buildDatePickerField(
                            context: context,
                            controller: cubit.fromDateController,
                            hint: 'Select From Date',
                            selectedDate: state.fromDate,
                            onDateSelected: (date) => cubit.setFromDate(date),
                            isFromDate: true,
                            fromDate: null,
                            toDate: state.toDate,
                          ),
                          const SizedBox(height: 15),
                          _buildTextFieldLabel(context, 'To'),
                          const SizedBox(height: 8),
                          _buildDatePickerField(
                            context: context,
                            controller: cubit.toDateController,
                            hint: 'Select To Date',
                            selectedDate: state.toDate,
                            onDateSelected: (date) => cubit.setToDate(date),
                            isFromDate: false,
                            fromDate: state.fromDate,
                            toDate: null,
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel(context, 'WorkSites'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: CustomDropdownField<String>(
                              fieldHeight: 30,
                              hintText: 'Select Work Sites',
                              value:
                                  state.selectedWorkSite != null &&
                                      workSites.contains(state.selectedWorkSite)
                                  ? state.selectedWorkSite
                                  : null,
                              items: workSites,
                              onChanged: (value) => cubit.setWorkSite(value),
                              fillColor: ColorHelper.white,
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionLabel(context, 'Location'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: CustomDropdownField<String>(
                              fieldHeight: 30,
                              hintText: 'Select Location',
                              value:
                                  state.location != null &&
                                      locations.contains(state.location)
                                  ? state.location
                                  : null,
                              items: locations,
                              onChanged: (value) => cubit.setLocation(value),
                              fillColor: ColorHelper.white,
                            ),
                          ),

                          const SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EmergexButton(
                        text: TextHelper.reset,
                        borderRadius: 24,
                        
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
                            cubit.reset(context);
                            back();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      EmergexButton(
                        text: TextHelper.applyFilters,
                        onPressed: cubit.hasChanges()
                            ? () => ClientUtils.applyProjectFilters(
                                context,
                                state,
                              )
                            : null,
                        disabled: !cubit.hasChanges(),
                        borderRadius: 24,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: ColorHelper.dateStatusColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextFieldLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: ColorHelper.grey,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    required bool isFromDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return AppTextField(
      controller: controller,
      readOnly: true,
      onTap: () => ClientUtils.showClientDatePicker(
        context: context,
        onDateSelected: onDateSelected,
        initialDate: selectedDate,
        isFromDate: isFromDate,
        fromDate: fromDate,
        toDate: toDate,
      ),
      hint: hint,
      fillColor: ColorHelper.white.withValues(alpha: 0.4),
      suffixIcon: Image.asset(Assets.calendarIcon, width: 20, height: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(35),
        borderSide: BorderSide(
          color: ColorHelper.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
