import 'dart:ui';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/client_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/image_picker_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/client_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/client_utils.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _Controllers {
  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController emailController;
  final TextEditingController industryController;
  final TextEditingController locationController;

  _Controllers._({
    required this.nameController,
    required this.idController,
    required this.emailController,
    required this.industryController,
    required this.locationController,
  });

  static final Map<BuildContext, _Controllers> _cache = {};

  static _Controllers _getOrCreateControllers(
    BuildContext context, {
    String? clientName,
    String? clientId,
    String? email,
    String? industry,
    String? location,
  }) {
    if (!_cache.containsKey(context)) {
      _cache[context] = _Controllers._(
        nameController: TextEditingController(text: clientName ?? ''),
        idController: TextEditingController(text: clientId ?? ''),
        emailController: TextEditingController(text: email ?? ''),
        industryController: TextEditingController(text: industry ?? ''),
        locationController: TextEditingController(text: location ?? ''),
      );
    }
    return _cache[context]!;
  }

  static void _dispose(BuildContext context) {
    final controllers = _cache.remove(context);
    controllers?.nameController.dispose();
    controllers?.idController.dispose();
    controllers?.emailController.dispose();
    controllers?.industryController.dispose();
    controllers?.locationController.dispose();
  }
}

class ClientSearchDialog extends StatelessWidget {
  final String? clientName;
  final String? clientId;
  final String? email;
  final String? industry;
  final String? location;
  final String? profileUrl;
  final String? status;
  final bool isEditMode;

  const ClientSearchDialog({
    super.key,
    this.clientName,
    this.clientId,
    this.email,
    this.industry,
    this.location,
    this.profileUrl,
    this.status,
  }) : isEditMode = clientName != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ImagePickerCubit()..setInitialImage(profileUrl),
        ),
        BlocProvider(
          create: (context) => ClientFormCubit(
            initialName: clientName,
            initialEmail: email,
            initialIndustry: industry,
            initialLocation: location,
            initialStatus: status,
          ),
        ),
      ],
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (context, state) {
          if (state.processState == ProcessState.done && !state.isLoading) {
            // Success - show success message and close dialog
            if (context.mounted) {
              showSnackBar(
                context,
                isEditMode
                    ? 'Client updated successfully'
                    : 'Client added successfully',
                isSuccess: true,
              );
              back();
              // Dispose controllers after dialog is fully closed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (context.mounted) {
                    _Controllers._dispose(context);
                  }
                });
              });
            }
          } else if (state.processState == ProcessState.error &&
              !state.isLoading) {
            // Error - show error message
            if (state.errorMessage != null &&
                state.errorMessage!.isNotEmpty &&
                context.mounted) {
              showSnackBar(context, state.errorMessage!, isSuccess: false);
            }
          }
        },
        builder: (context, state) {
          final isLoading = state.isLoading;

          // Create controllers lazily and cache them
          final controllers = _Controllers._getOrCreateControllers(
            context,
            clientName: clientName,
            clientId: clientId,
            email: email,
            industry: industry,
            location: location,
          );

          return PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: ColorHelper.surfaceColor.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: ColorHelper.white, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              insetPadding: const EdgeInsets.all(16),
              title: DialogTitleBar(
                title: isEditMode
                    ? TextHelper.editClient
                    : TextHelper.addNewClient,
                onClose: () {
                  back();
                  // Dispose controllers after dialog is fully closed
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (context.mounted) {
                        _Controllers._dispose(context);
                      }
                    });
                  });
                },
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => true,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 16
                          : 0,
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        BlocBuilder<ImagePickerCubit, ImagePickerState>(
                          builder: (context, imageState) {
                            final hasImage =
                                imageState.selectedImage != null ||
                                imageState.imagePath != null;

                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => context
                                            .read<ImagePickerCubit>()
                                            .pickImage(),
                                        child: Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: ColorHelper.white,
                                              width: 8,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: ClientUtils.buildImage(
                                              imageState,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: hasImage
                                              ? () {
                                                  // Delete image
                                                  context
                                                      .read<ImagePickerCubit>()
                                                      .clearImage();
                                                }
                                              : () {
                                                  // Pick image
                                                  context
                                                      .read<ImagePickerCubit>()
                                                      .pickImage();
                                                },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: hasImage
                                                  ? ColorHelper.recycleBin
                                                  : ColorHelper.primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: hasImage
                                                    ? ColorHelper.recycleBin
                                                    : ColorHelper.primaryColor,
                                                width: 6,
                                              ),
                                            ),
                                            child: hasImage
                                                ? Image.asset(
                                                    Assets
                                                        .reportIncidentRecycleBin,
                                                    color: ColorHelper.white,
                                                    width: 16,
                                                    height: 16,
                                                  )
                                                : Icon(
                                                    Icons.add,
                                                    color: ColorHelper.white,
                                                    size: 16,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Client Logo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: ColorHelper.black4,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        _buildLabeledField(
                          context,
                          'Client Name',
                          controllers.nameController,
                          isRequired: true,
                          fieldType: 'name',
                        ),
                        const SizedBox(height: 16),

                        _buildLabeledField(
                          context,
                          'Mail ID',
                          controllers.emailController,
                          hintText: 'Enter email address',
                          isRequired: true,
                          fieldType: 'email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildLabeledField(
                          context,
                          'Client ID',
                          controllers.idController,
                          hintText: 'TCGA-G3-A3CG',
                          isDisabled: true,
                        ),
                        const SizedBox(height: 16),

                        _buildLabeledField(
                          context,
                          'Industry',
                          controllers.industryController,
                          isRequired: true,
                          fieldType: 'industry',
                        ),
                        const SizedBox(height: 16),

                        _buildLocationField(
                          context,
                          controllers.locationController,
                        ),

                        // Status dropdown — only shown in edit mode
                        if (isEditMode) ...<Widget>[
                          const SizedBox(height: 16),
                          _buildStatusDropdown(context),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,

              actions: [
                Row(
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
                      colors: [ColorHelper.white, ColorHelper.white],
                      onPressed: isLoading
                          ? null
                          : () {
                              back();
                              // Dispose controllers after dialog is fully closed
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () {
                                    if (context.mounted) {
                                      _Controllers._dispose(context);
                                    }
                                  },
                                );
                              });
                            },
                    ),
                    const SizedBox(width: 16),

                    BlocBuilder<ClientFormCubit, ClientFormState>(
                      builder: (context, formState) {
                        return BlocBuilder<ImagePickerCubit, ImagePickerState>(
                          builder: (context, imageState) {
                            final isButtonEnabled =
                                !isLoading &&
                                ClientUtils.isButtonEnabled(
                                  formState: formState,
                                  profileFile: imageState.selectedImage,
                                  imagePath: imageState.imagePath,
                                  isEditMode: isEditMode,
                                  clientName: clientName,
                                  email: email,
                                  industry: industry,
                                  location: location,
                                  profileUrl: profileUrl,
                                  initialStatus: status,
                                );

                            return Opacity(
                              opacity: isButtonEnabled ? 1.0 : 0.5,
                              child: EmergexButton(
                                width: 100,
                                buttonHeight: 36,
                                fontWeight: FontWeight.w600,
                                borderRadius: 24,
                                onPressed: isButtonEnabled
                                    ? () {
                                        // Validate form using cubit
                                        final formCubit = context
                                            .read<ClientFormCubit>();
                                        if (!formCubit.validateForm()) {
                                          return;
                                        }

                                        ClientUtils.handleSubmit(
                                          context: context,
                                          nameController:
                                              controllers.nameController,
                                          idController:
                                              controllers.idController,
                                          emailController:
                                              controllers.emailController,
                                          industryController:
                                              controllers.industryController,
                                          locationController:
                                              controllers.locationController,
                                          profileFile: imageState.selectedImage,
                                          isEditMode: isEditMode,
                                          status: formState.status,
                                          imagePath: imageState.imagePath,
                                          profileUrl: profileUrl,
                                        );
                                      }
                                    : null,
                                text: isEditMode
                                    ? TextHelper.save
                                    : TextHelper.add,
                                textColor: ColorHelper.textLight,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color? _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ColorHelper.primaryDark;
      case 'inactive':
        return ColorHelper.errorColor;
      case 'archived':
        return ColorHelper.erteamleaderprogress;
      default:
        return null;
    }
  }

  /// Status dropdown field — shown only in edit mode
  Widget _buildStatusDropdown(BuildContext context) {
    const statusOptions = ['Active', 'Inactive', 'Archived'];

    return BlocBuilder<ClientFormCubit, ClientFormState>(
      builder: (context, formState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.draftColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorHelper.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: ColorHelper.black.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: formState.status,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: ColorHelper.primaryColor,
                    size: 20,
                  ),
                  selectedItemBuilder: (context) => statusOptions
                      .map(
                        (item) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _statusColor(formState.status) ??
                                  ColorHelper.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  items: statusOptions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ClientFormCubit>().updateStatus(value);
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabeledField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    String? hintText,
    bool isDisabled = false,
    String? fieldType, // 'name', 'email', 'industry', 'location'
    TextInputType? keyboardType,
  }) {
    // Generate unique ID if field is disabled and controller is empty
    if (isDisabled && controller.text.isEmpty) {
      controller.text = ClientUtils.generateUniqueClientId();
    }

    return BlocBuilder<ClientFormCubit, ClientFormState>(
      builder: (context, formState) {
        String? errorText;
        if (fieldType == 'name') {
          errorText = formState.nameError;
        } else if (fieldType == 'email') {
          errorText = formState.emailError;
        } else if (fieldType == 'industry') {
          errorText = formState.industryError;
        }

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
              hint: hintText ?? 'Enter $label',
              fillColor: ColorHelper.white,
              keyboardType: keyboardType ?? TextInputType.text,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: errorText != null
                    ? BorderSide(color: ColorHelper.starColor, width: 1)
                    : BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isEditable: !isDisabled,
              onChanged: (value) {
                final formCubit = context.read<ClientFormCubit>();
                if (fieldType == 'name') {
                  formCubit.updateName(value);
                } else if (fieldType == 'email') {
                  formCubit.updateEmail(value);
                } else if (fieldType == 'industry') {
                  formCubit.updateIndustry(value);
                }
              },
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
      },
    );
  }

  Widget _buildLocationField(
    BuildContext context,
    TextEditingController controller,
  ) {
    return BlocBuilder<ClientCubit, ClientState>(
      builder: (context, state) {
        final locations = state.locations;

        return BlocBuilder<ClientFormCubit, ClientFormState>(
          builder: (context, formState) {
            final errorText = formState.locationError;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Location',
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

                // Combined Autocomplete widget for dropdown and text input
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return locations;
                    }
                    return locations.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  displayStringForOption: (String option) => option,
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        // Initialize text from controller if needed
                        if (controller.text.isNotEmpty &&
                            textEditingController.text != controller.text) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (textEditingController.text != controller.text) {
                              textEditingController.text = controller.text;
                            }
                          });
                        }

                        return AppTextField(
                          dismissKeyboardOnTapOutside: false,
                          controller: textEditingController,
                          hint: 'Enter location',
                          fillColor: ColorHelper.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: errorText != null
                                ? BorderSide(
                                    color: ColorHelper.starColor,
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onChanged: (value) {
                            controller.text = value;
                            // Update form cubit when location changes
                            context.read<ClientFormCubit>().updateLocation(
                              value,
                            );
                          },
                        );
                      },
                  onSelected: (String selection) {
                    controller.text = selection;
                    // Update form cubit when location is selected
                    context.read<ClientFormCubit>().updateLocation(selection);
                  },
                  optionsViewBuilder:
                      (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                      ) {
                        if (options.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(12),
                            color: ColorHelper.white,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) => true,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final String option = options.elementAt(
                                          index,
                                        );
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Text(
                                              option,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        ColorHelper.draftColor,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
          },
        );
      },
    );
  }

  static Future<Map<String, String>?> show(
    BuildContext context, {
    String? clientName,
    String? clientId,
    String? email,
    String? industry,
    String? location,
    String? profileUrl,
    String? status,
  }) async {
    return showGeneralDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      barrierLabel: "ClientSearchDialog",
      barrierColor: ColorHelper.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(
            child: ClientSearchDialog(
              clientName: clientName,
              clientId: clientId,
              email: email,
              industry: industry,
              location: location,
              profileUrl: profileUrl,
              status: status,
            ),
          ),
        );
      },
    );
  }
}
