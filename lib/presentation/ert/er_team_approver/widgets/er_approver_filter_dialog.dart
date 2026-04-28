import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:emergex/presentation/ert/er_team_approver/cubit/er_filter_cubit.dart';
import 'package:emergex/presentation/ert/er_team_approver/utils/er_approver_filter_utils.dart';

class ErApproverFilterDialog extends StatelessWidget {
  const ErApproverFilterDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final initialState = ErApproverFilterUtils.getInitialFilterState();

    await showBlurredDialog(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => ErApproverFilterCubit(initialState: initialState),
        child: const ErApproverFilterDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErApproverFilterCubit, ErApproverFilterState>(
      builder: (context, state) {
        final cubit = context.read<ErApproverFilterCubit>();
final bool isApplyEnabled = cubit.hasChanges();

        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogTitleBar(title: 'Filters', onClose: () => back()),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Reported By'),
                        _textField(
                          cubit.reportedCtrl,
                          'Enter Name',
                          onChanged: (_) => cubit.markChanged(),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EmergexButton(
                              text: 'Reset',
                              onPressed: () {
                                cubit.reset(context);
                                back();
                              },
                              borderRadius: 35,
                              borderColor: ColorHelper.white,
                              colors: const [
                                ColorHelper.white,
                                ColorHelper.white,
                              ],
                              textColor: ColorHelper.primaryColor,
                            ),
                            const SizedBox(width: 16),

                            /// 🟢 APPLY (already correct)
                            EmergexButton(
                              text: 'Apply Filters',
                              onPressed: isApplyEnabled
                                  ? () {
                                      ErApproverFilterUtils.applyFilters(context, state);
                                      cubit.markApplied(); // 🔥 REQUIRED
                                      back();
                                    }
                                  : null,
                              borderRadius: 35,
                              colors: const [
                                ColorHelper.primaryColor,
                                ColorHelper.primaryColor,
                              ],
                              textColor: ColorHelper.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// -------- UI HELPERS --------

  static Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          t,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  static Widget _textField(
    TextEditingController controller,
    String hint, {
    ValueChanged<String>? onChanged,
  }) =>
      AppTextField(
        controller: controller,
        hint: hint,
        onChanged: onChanged,
        fillColor: ColorHelper.white.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      );
}
