import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Category Tabs Widget
class CategoryTabsWidget extends StatelessWidget {
  final String? selectedCategory;
  const CategoryTabsWidget({super.key, this.selectedCategory});

  static const List<String> categories = [
    'Project Specific',
    "Client's Internal",
    'Client Reports',
    'General Docs',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.onboardingOrganizationStructureCubit;

    return BlocBuilder<
      OnboardingOrganizationStructureCubit,
      OnboardingOrganizationStructureState
    >(
      builder: (context, state) {
        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == state.selectedCategory;
              final isDisabled = selectedCategory == 'General Docs';

              return GestureDetector(
                onTap: isDisabled ? null : () => cubit.selectCategory(category),
                child: Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorHelper.uploadfilebackground.withValues(
                              alpha: 0.4,
                            )
                          : ColorHelper.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? ColorHelper.primaryColor
                            : ColorHelper.white,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDisabled
                                  ? ColorHelper.textColorDefault
                                  : ColorHelper.black5,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

