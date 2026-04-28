import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_form_cubit/role_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/permission_constants.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/organization/column_row_togglebutton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Permission dropdown widget for role creation
class PermissionDropdownWidget extends StatelessWidget {
  const PermissionDropdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<RoleFormCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.white),
      ),
      child: BlocBuilder<RoleFormCubit, RoleFormState>(
        builder: (context, state) {
          if (state.isLoadingFeatures) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.featuresError != null) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                state.featuresError!,
                style: TextStyle(color: ColorHelper.errorColor),
              ),
            );
          }

          if (state.modulesWithFeatures.isEmpty) {
            return Column(
              children: [
                Text(
                  'No features found',
                  style: TextStyle(color: ColorHelper.errorColor),
                ),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: state.modulesWithFeatures
                    .map(
                      (module) => Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ColorHelper.white),
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          collapsedShape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          title: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              module['moduleName'] as String,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: ColorHelper.black4,
                                  ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: (module['features'] as List).map((
                                  section,
                                ) {
                                  final featureTitle =
                                      section['title'] as String;
                                  final isFullAccessOnly =
                                      isFullAccessOnlyFeature(featureTitle);

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: ToggleSectionWidget(
                                      title: featureTitle,
                                      toggles: section['toggles'] as List<bool>,
                                      isFullAccessOnly: isFullAccessOnly,
                                      onToggleChanged: (index, value) {
                                        // Use featureId from section
                                        final featureId =
                                            section['featureId'] as String?;
                                        if (featureId != null &&
                                            featureId.isNotEmpty) {
                                          formCubit.togglePermission(
                                            featureId,
                                            index,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
