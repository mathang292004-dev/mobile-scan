import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/case_report/cubit/dashboard_filter_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardFilterDialog extends StatelessWidget {
  final Function(String? status, Map<String, String>? daterange) onApply;
  final VoidCallback onReset;

  const DashboardFilterDialog({
    super.key,
    required this.onApply,
    required this.onReset,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String? status, Map<String, String>? daterange) onApply,
    required VoidCallback onReset,
    String? currentStatus,
    DateTime? currentFromDate,
    DateTime? currentToDate,
  }) async {
    final initialState = DashboardFilterState(
      selectedStatus: currentStatus,
      fromDate: currentFromDate,
      toDate: currentToDate,
    );
    await showBlurredDialog(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => DashboardFilterCubit(initialState: initialState),
        child: DashboardFilterDialog(onApply: onApply, onReset: onReset),
      ),
    );
  }

  static const List<_StatusOption> _statusOptions = [
    _StatusOption(label: TextHelper.allStatus, value: null),
    _StatusOption(label: TextHelper.inProgress, value: 'inprogress'),
    _StatusOption(label: TextHelper.approvalPending, value: 'approvalpending'),
    _StatusOption(label: TextHelper.closedStatus, value: 'closed'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardFilterCubit, DashboardFilterState>(
      builder: (context, state) {
        final cubit = context.read<DashboardFilterCubit>();

        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: ColorHelper.white, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogTitleBar(
                  title: TextHelper.filters,
                  onClose: () => back(),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(context, TextHelper.statusLabel),
                        const SizedBox(height: 10),
                        _buildStatusChips(context, state, cubit),
                        const SizedBox(height: 20),
                        _sectionLabel(context, TextHelper.fromDateLabel),
                        const SizedBox(height: 8),
                        _buildDateField(
                          context: context,
                          controller: cubit.fromDateController,
                          hint: TextHelper.fromDateLabel,
                          selectedDate: state.fromDate,
                          onDateSelected: cubit.setFromDate,
                          firstDate: DateTime(2000),
                          lastDate: state.toDate ?? DateTime.now(),
                        ),
                        const SizedBox(height: 16),
                        _sectionLabel(context, TextHelper.toDateLabel),
                        const SizedBox(height: 8),
                        _buildDateField(
                          context: context,
                          controller: cubit.toDateController,
                          hint: TextHelper.toDateLabel,
                          selectedDate: state.toDate,
                          onDateSelected: cubit.setToDate,
                          firstDate: state.fromDate ?? DateTime(2000),
                          lastDate: DateTime.now(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmergexButton(
                      text: TextHelper.reset,
                      colors: const [
                        ColorHelper.surfaceColor,
                        ColorHelper.surfaceColor,
                      ],
                      width: 100,
                      buttonHeight: 36,
                      textColor: ColorHelper.primaryColor,
                      borderRadius: 24,
                      borderColor: ColorHelper.transparent,
                      fontWeight: FontWeight.w600,
                      onPressed: () {
                        cubit.reset();
                        onReset();
                        back();
                      },
                    ),
                    const SizedBox(width: 16),
                    EmergexButton(
                      text: TextHelper.applyFilters,
                      width: 160,
                      buttonHeight: 36,
                      borderRadius: 24,
                      fontWeight: FontWeight.w600,
                      disabled: !cubit.hasChanges(),
                      onPressed: cubit.hasChanges()
                          ? () {
                              onApply(state.selectedStatus, cubit.dateRangeMap);
                              cubit.markApplied();
                              back();
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChips(
    BuildContext context,
    DashboardFilterState state,
    DashboardFilterCubit cubit,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statusOptions.map((option) {
        final isSelected = state.selectedStatus == option.value;
        return GestureDetector(
          onTap: () => cubit.setStatus(option.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorHelper.primaryColor
                  : ColorHelper.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? ColorHelper.primaryColor
                    : ColorHelper.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Text(
              option.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? ColorHelper.white : ColorHelper.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return AppTextField(
      controller: controller,
      readOnly: true,
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
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onDateSelected(picked);
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.dateStatusColor,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _StatusOption {
  final String label;
  final String? value;
  const _StatusOption({required this.label, required this.value});
}
