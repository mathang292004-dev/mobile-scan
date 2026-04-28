import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/client_utils.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:emergex/presentation/ert/er_team_leader/my_tasks/cubit/my_task_filter_cubit.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class ErLeaderCustomDialogWidget extends StatelessWidget {
  final List<String> statusOptions = [
    'Completed',
    'In Progress',
    'Pause',
    'Draft',
  ];

  ErLeaderCustomDialogWidget({super.key});

  static Future<void> show(BuildContext context) async {
    final initialState = _getInitialFilterState();

    await showBlurredDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => MyTaskFilterCubit(initialState: initialState),
        child: ErLeaderCustomDialogWidget(),
      ),
    );
  }

  static MyTaskFilterState? _getInitialFilterState() {
    final myTaskCubit = AppDI.myTaskCubit;
    final state = myTaskCubit.state;

    if (state.appliedStatuses == null &&
        (state.appliedFromDate == null || state.appliedFromDate!.isEmpty) &&
        (state.appliedToDate == null || state.appliedToDate!.isEmpty)) {
      return null;
    }

    String? uiStatus;
    if (state.appliedStatuses != null && state.appliedStatuses!.isNotEmpty) {
      uiStatus = state.appliedStatuses!
          .map((s) {
        switch (s.trim().toLowerCase()) {
          case 'inprogress':
            return 'In Progress';
          case 'completed':
          case 'complete':
            return 'Completed';
          case 'paused':
          case 'pause':
            return 'Pause';
          case 'draft':
            return 'Draft';
          default:
            return s;
        }
      })
          .join(', ');
    }

    return MyTaskFilterState(
      selectedStatus: uiStatus,
      fromDate: state.appliedFromDate,
      toDate: state.appliedToDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyTaskFilterCubit, MyTaskFilterState>(
      builder: (context, state) {
        final cubit = context.read<MyTaskFilterCubit>();

        return AlertDialog(
          backgroundColor: ColorHelper.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(16),
          insetPadding: const EdgeInsets.all(3),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DialogTitleBar(title: "Filters", onClose: () => back()),
                  const SizedBox(height: 16),
                  Text(
                    "Status",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.grey4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- STATUS SELECTION BAR ---
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(35),
                    color: ColorHelper.white,
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                          child: KeyedSubtree(
                          key: const ValueKey('selected_status_chips'),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                children: (state.selectedStatus == null ||
                                    state.selectedStatus!.isEmpty)
                                    ? [
                                  Text(
                                    "Select Status",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      color: ColorHelper.selectstatus
                                          .withValues(alpha:0.5),
                                    ),
                                  ),
                                ]
                                    : state.selectedStatus!
                                    .split(',')
                                    .where((s) => s.isNotEmpty)
                                    .map((status) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ColorHelper.primaryColor
                                          .withValues(alpha:0.15),
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(status,
                                            style: const TextStyle(
                                                color: ColorHelper.primaryColor,
                                                fontSize: 13)),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                              final List<String> items = state.selectedStatus!
                                                  .split(',')
                                                  .map((e) => e.trim())
                                                  .where((s) => s.isNotEmpty)
                                                  .toList();

                                              items.remove(status.trim());
                                              cubit.setStatus(items.isEmpty ? null : items.join(', '));
                                          },
                                          child: const Icon(Icons.close,
                                              size: 14,
                                              color: ColorHelper.primaryColor),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          ),
                          IconButton(
                            icon: Icon(
                              state.showStatusList
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: ColorHelper.primaryColor,
                            ),
                            onPressed: () => cubit.toggleStatusVisibility(),
                          ),
                        ],
                      ),
                    ),
                  ),


                  // --- 2. SEPARATE CHECKBOX LIST ---
                  if (state.showStatusList) ...[
                    const SizedBox(height: 12),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      color: ColorHelper.white,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            children: statusOptions.map((option) {
                              // Convert current string to a real list, cleaning whitespace
                              final List<String> currentItems = (state.selectedStatus == null || state.selectedStatus!.trim().isEmpty)
                                  ? []
                                  : state.selectedStatus!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                              final bool isSelected = currentItems.contains(option);

                              return InkWell(
                                onTap: () {
                                  List<String> updatedItems = List.from(currentItems);
                                  if (isSelected) {
                                    updatedItems.remove(option);
                                  } else {
                                    updatedItems.add(option);
                                  }

                                  // If updatedItems is empty, we MUST send null to disable the button
                                  cubit.setStatus(updatedItems.isEmpty ? null : updatedItems.join(', '));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: isSelected ? ColorHelper.primaryColor : Colors.grey.shade400,
                                              width: 2),
                                          borderRadius: BorderRadius.circular(4),
                                          color: isSelected ? ColorHelper.primaryColor : Colors.transparent,
                                        ),
                                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        option,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: ColorHelper.grey4),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // --- DATE SECTION ---
                  const Text(
                    "Date",
                    style: TextStyle(
                      color: ColorHelper.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "From",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorHelper.grey4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "To",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorHelper.grey4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          color: ColorHelper.white,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: const InputDecorationTheme(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                            child: _buildDatePickerField(
                              context: context,
                              controller: cubit.fromDateController,
                              hint: "From Date",
                              isFromDate: true,
                              fromDate: null,
                              toDate: state.toDate != null
                                  ? ClientUtils.parseDateFromString(state.toDate!)
                                  : null,
                              onDateSelected: (date) => cubit.setFromDate(date),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          color: ColorHelper.white,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: const InputDecorationTheme(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                            child: _buildDatePickerField(
                              context: context,
                              controller: cubit.toDateController,
                              hint: "To Date",
                              isFromDate: false,
                              fromDate: state.fromDate != null
                                  ? ClientUtils.parseDateFromString(state.fromDate!)
                                  : null,
                              toDate: null,
                              onDateSelected: (date) => cubit.setToDate(date),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- BUTTONS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: ColorHelper.primaryColor,
                          backgroundColor: ColorHelper.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        onPressed: () {
                          if (!cubit.isInitialStateEmpty() || cubit.hasChanges()) {
                            cubit.reset();
                          }
                          back();
                        },
                        child: Text(
                          TextHelper.reset,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 16),
                      EmergexButton(
                        width: 150,
                        buttonHeight: 48,
                        text: TextHelper.applyFilters,
                        textSize: 14,
                        fontWeight: FontWeight.w600,
                        onPressed: cubit.hasChanges()
                            ? () {
                          final statuses = cubit.getApiStatuses();
                          AppDI.myTaskCubit.loadMyTasks(
                            statuses: statuses,
                            fromDate: state.fromDate,
                            toDate: state.toDate,
                          );
                          back();
                        }
                            : null,
                        disabled: !cubit.hasChanges(),
                        borderRadius: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required bool isFromDate,
    DateTime? fromDate,
    DateTime? toDate,
    required ValueChanged<String> onDateSelected,
  }) {
    return AppTextField(
      controller: controller,
      readOnly: true,
      onTap: () => ClientUtils.showClientDatePicker(
        context: context,
        onDateSelected: (selectedDate) {
          final formattedDate = ClientUtils.formatDate(selectedDate);
          if (formattedDate != null) {
            onDateSelected(formattedDate);
          }
        },
        initialDate: null,
        isFromDate: isFromDate,
        fromDate: fromDate,
        toDate: toDate,
      ),
      hint: hint,
      suffixIcon: Image.asset(Assets.calendarIcon, height: 18, width: 18),
    );
  }
}