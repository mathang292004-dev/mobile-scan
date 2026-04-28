import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:flutter/material.dart';

/// Upload Instructions Widget
class UploadInstructionsWidget extends StatelessWidget {
  final OnboardingOrganizationStructureCubit cubit;

  const UploadInstructionsWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plans, reports, and technical files.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: ColorHelper.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                TextHelper.onlySupportPdfDocDocx,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: ColorHelper.textColorDefault,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => cubit.pickFiles(cubit.state.selectedCategory),
          icon: const Icon(
            Icons.add,
            size: 20,
            color: ColorHelper.successColor,
          ),
          label: Text(
            'Add Files',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorHelper.primaryColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorHelper.newClient.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(
                color: ColorHelper.addMemberColor,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}

