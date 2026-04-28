import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/inputs/phone_input_field.dart';
import 'package:emergex/presentation/user_onboarding/cubit/add_single_user_cubit.dart';
import 'package:emergex/presentation/user_onboarding/utils/add_single_user_utils.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddSingleUserDialog extends StatelessWidget {
  const AddSingleUserDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddSingleUserCubit, AddSingleUserState>(
      bloc: AppDI.addSingleUserCubit,
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) =>
          AddSingleUserUtils.handleStateChange(context, state),
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.isFormValid != curr.isFormValid ||
          prev.nameError != curr.nameError ||
          prev.emailError != curr.emailError ||
          prev.phoneError != curr.phoneError ||
          prev.selectedCountry != curr.selectedCountry ||
          prev.profileImage != curr.profileImage ||
          prev.profileImagePath != curr.profileImagePath,
      builder: (context, state) {
        final isLoading = state.status == AddSingleUserStatus.loading;

        return AlertDialog(
          backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: ColorHelper.white, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
          insetPadding: const EdgeInsets.all(16),
          title: _buildTitle(context, isLoading),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.55,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildProfileSection(context, state),
                  const SizedBox(height: 24),
                  _buildField(
                    context,
                    label: TextHelper.fullName,
                    hint: TextHelper.userManagementHintFullName,
                    errorText: state.nameError,
                    isRequired: true,
                    controller: AppDI.addSingleUserCubit.nameController,
                    onChanged: AppDI.addSingleUserCubit.updateName,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    context,
                    label: TextHelper.emailAddress,
                    hint: TextHelper.userManagementHintEmail,
                    errorText: state.emailError,
                    isRequired: true,
                    controller: AppDI.addSingleUserCubit.emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: AppDI.addSingleUserCubit.updateEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildPhoneField(context, state),
                  const SizedBox(height: 16),
                  _buildField(
                    context,
                    label: TextHelper.status,
                    hint: TextHelper.inactive,
                    isDisabled: true,
                    initialValue: TextHelper.inactive,
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [_buildActions(context, state, isLoading)],
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          TextHelper.addSingleUser,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ColorHelper.black4,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: isLoading ? null : () => back(),
          child: const Icon(
            Icons.cancel_outlined,
            size: 24,
            color: ColorHelper.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, AddSingleUserState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: AddSingleUserUtils.pickProfileImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ColorHelper.white, width: 4),
                  ),
                  child: ClipOval(child: _buildProfileImage(state)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: state.hasImage
                      ? AddSingleUserUtils.clearProfileImage
                      : AddSingleUserUtils.pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: state.hasImage
                          ? ColorHelper.recycleBin
                          : ColorHelper.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: state.hasImage
                            ? ColorHelper.recycleBin
                            : ColorHelper.primaryColor,
                        width: 4,
                      ),
                    ),
                    child: state.hasImage
                        ? Image.asset(
                            Assets.reportIncidentRecycleBin,
                            color: ColorHelper.white,
                            width: 14,
                            height: 14,
                          )
                        : const Icon(
                            Icons.add,
                            color: ColorHelper.white,
                            size: 14,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            TextHelper.userProfile,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: ColorHelper.black4,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(AddSingleUserState state) {
    if (state.profileImage != null) {
      return Image.file(
        state.profileImage!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: ColorHelper.cardColor,
      child: const Icon(
        Icons.person,
        size: 40,
        color: ColorHelper.tertiaryColor,
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    AddSingleUserState state,
    bool isLoading,
  ) {
    final isButtonEnabled = !isLoading && state.isFormValid;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        EmergexButton(
          width: 100,
          buttonHeight: 36,
          fontWeight: FontWeight.w600,
          borderRadius: 24,
          borderColor: ColorHelper.white,
          text: TextHelper.cancel,
          textColor: ColorHelper.primaryColor,
          colors: const [ColorHelper.white, ColorHelper.white],
          onPressed: isLoading ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        Opacity(
          opacity: isButtonEnabled ? 1.0 : 0.5,
          child: EmergexButton(
            width: 100,
            buttonHeight: 36,
            fontWeight: FontWeight.w600,
            borderRadius: 24,
            text: TextHelper.addUser,
            textColor: ColorHelper.textLight,
            onPressed: isButtonEnabled
                ? () => AddSingleUserUtils.handleSubmit(context)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required String hint,
    String? errorText,
    bool isRequired = false,
    bool isDisabled = false,
    String? initialValue,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.draftColor,
              ),
            ),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '*',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AppTextField(
          dismissKeyboardOnTapOutside: false,
          controller: controller,
          hint: hint,
          fillColor: ColorHelper.white,
          isEditable: !isDisabled,
          initialValue: controller == null ? initialValue : null,
          keyboardType: keyboardType,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: errorText != null
                ? const BorderSide(color: ColorHelper.starColor, width: 1)
                : BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          onChanged: onChanged,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColorHelper.starColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneField(BuildContext context, AddSingleUserState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              TextHelper.phoneNumber,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.draftColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '*',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColorHelper.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PhoneInputField(
          controller: AppDI.addSingleUserCubit.phoneController,
          selectedCountry: state.selectedCountry,
          onCountryChanged: AppDI.addSingleUserCubit.updateCountry,
          onChanged: AppDI.addSingleUserCubit.updatePhone,
          hint: TextHelper.userManagementHintPhone,
          errorText: state.phoneError,
        ),
      ],
    );
  }
}
