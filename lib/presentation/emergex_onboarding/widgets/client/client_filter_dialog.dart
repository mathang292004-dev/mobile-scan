import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/filter_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/client_utils.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/custom_drop_down_field.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientFilterDialog extends StatelessWidget {
  const ClientFilterDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final initialState = ClientUtils.getInitialFilterState();

    await showBlurredDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => FilterCubit(initialState: initialState),
        child: const ClientFilterDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = ['Active', 'InActive', 'Archived'];
    final industries = AppDI.clientCubit.state.industries;
    final locations = AppDI.clientCubit.state.locations;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: ColorHelper.white, width: 2),
        ),

        contentPadding: const EdgeInsets.all(16),
        insetPadding: const EdgeInsets.all(8),
        content: SizedBox(
          width: 500,
          height: 600,
          child: BlocBuilder<FilterCubit, FilterState>(
            builder: (context, state) {
              final cubit = context.read<FilterCubit>();

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
                              hintText: 'Select Status',
                              fieldHeight: 35,
                              value: state.selectedStatus,
                              items: statusOptions,
                              onChanged: (value) => cubit.setStatus(value),
                              labelBuilder: (item) => item == 'InActive' ? 'Inactive' : item,
                            ),
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
                          _buildSectionLabel(context, 'Industries'),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: ColorHelper.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(35),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: state.selectedIndustries.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              'Select industries',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: ColorHelper
                                                        .black4
                                                        .withValues(alpha: 0.5),
                                                  ),
                                            ),
                                          )
                                        : Row(
                                            children: state.selectedIndustries.map((
                                              industry,
                                            ) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
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
                                                      industry,
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
                                                      onTap: () => cubit
                                                          .removeIndustry(industry),
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
                                  icon: Icon(
                                    state.showIndustries
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: ColorHelper.primaryColor,
                                  ),
                                  onPressed: () {
                                    cubit.toggleIndustriesList();
                                  },
                                ),
                              ],
                            ),
                          ),
                 
                          if (state.showIndustries) ...[
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: ColorHelper.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Column(
                                children: industries.map((industry) {
                                  final isSelected = state.selectedIndustries
                                      .contains(industry);
                                  return CheckboxListTile(
                                    side: BorderSide(
                                      color: ColorHelper.grey.withValues(
                                        alpha: 0.6,
                                      ),
                                      width: 1,
                                    ),

                                    title: Text(
                                      industry,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: ColorHelper.grey4),
                                    ),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      cubit.toggleIndustry(
                                        industry,
                                        value ?? false,
                                      );
                                    },
                                    activeColor: ColorHelper.primaryColor,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildSectionLabel(context, 'Location'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: CustomDropdownField<String>(
                              fieldHeight: 35,
                              hintText: 'Select Location',
                              value: state.location,
                              items: locations,
                              onChanged: (value) => cubit.setLocation(value),
                            ),
                          ),
                          const SizedBox(height: 35),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EmergexButton(
                        text: TextHelper.reset,
                        colors: [
                          ColorHelper.surfaceColor,
                          ColorHelper.surfaceColor,
                        ],
                        width: 100, 
                        buttonHeight: 36,
                        textColor: ColorHelper.primaryColor,
                        onPressed: () {
                          if (cubit.isInitialStateEmpty()) {
                            back();
                          } else {
                            cubit.reset(context);
                            back();
                          }
                        },
                        borderRadius: 24,
                        borderColor: ColorHelper.transparent,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(width: 16),
                      EmergexButton(
                        text: TextHelper.applyFilters,
                        width: 160, 
                        buttonHeight: 36,
                        onPressed: cubit.hasChanges()
                            ? () => ClientUtils.applyFilters(context, state)
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

  Widget _buildTextFieldLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: ColorHelper.calender,
        fontWeight: FontWeight.w400,
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
