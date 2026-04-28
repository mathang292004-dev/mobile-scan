import 'dart:math';
import 'dart:ui';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/project_view_cubit/project_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/project_view_cubit/project_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/common/dialog_title_bar.dart';
import 'package:emergex/data/model/user_role_permission/user_permissions_response.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';

class ProjectDialogBox extends StatelessWidget {
  final String? title;
  final String? code;
  final String? workSite;
  final String? location;
  final String? description;
  final bool isEditMode;
  final List<UserFeaturePermission> permissions;

  const ProjectDialogBox({
    super.key,
    this.title,
    this.code,
    this.workSite,
    this.location,

    this.description,
    required this.permissions,
  }) : isEditMode = title != null;

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: title ?? '');
    final codeController = TextEditingController(text: code ?? '');
    final workSiteController = TextEditingController(text: workSite ?? '');
    final locationController = TextEditingController(text: location ?? '');
    final descriptionController = TextEditingController(
      text: description ?? '',
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProjectFormCubit(
            initialProjectName: title,
            initialLocation: location,
            initialWorkSites: workSite,
            initialDescription: description,
          ),
        ),
      ],
      child: BlocConsumer<ProjectCubit, ProjectState>(
        listener: (context, state) {
          if (state.processState == ProcessState.done &&
              !state.isLoading &&
              state.successMessage != null &&
              state.successMessage!.isNotEmpty) {
            // Success - show success message and close dialog
            if (context.mounted) {
              // After adding, check permissions for navigation
              if (!isEditMode) {
                final uploadPermission = permissions.firstWhere(
                  (p) => p.name == 'Upload or Reupload files',
                  orElse: () => const UserFeaturePermission(
                    name: '',
                    featureId: '',
                    desc: '',
                    permissions: PermissionActions(),
                  ),
                );

                final hasUploadPermission =
                    (uploadPermission.permissions.create ?? false) ||
                    (uploadPermission.permissions.edit ?? false) ||
                    (uploadPermission.permissions.fullAccess ?? false);

                // Show message and clear immediately
                showSnackBar(
                  context,
                  state.successMessage!,
                  isSuccess: true,
                );
                AppDI.projectCubit.clearError();

                // Close dialog after clearing message
                back();

                if (hasUploadPermission) {
                  // Has permission → Navigate to upload screen
                  AppDI.onboardingOrganizationStructureCubit.viewDetails(
                    codeController.text.trim(),
                    'docs',
                  );
                  openScreen(Routes.uploadDocumentsScreen);
                }
              } else {
                // Edit mode - show message, clear, and close
                showSnackBar(
                  context,
                  state.successMessage!,
                  isSuccess: true,
                );
                AppDI.projectCubit.clearError();
                back();
              }
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

          return PopScope(
            canPop: !isLoading,
            child: AlertDialog(
              backgroundColor: ColorHelper.white.withValues(alpha: 0.9),
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: DialogTitleBar(
                title: isEditMode
                    ? TextHelper.editProject
                    : TextHelper.addNewProject,
                onClose: isLoading ? () {} : () => back(),
              ),
              content: SizedBox(
                width: 400,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabeledField(
                        context,
                        'Project Name',
                        titleController,
                        isRequired: true,
                        fieldType: 'projectName',
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledField(
                        context,
                        'Project ID',
                        codeController,
                        isDisabled: true,
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledField(
                        context,
                        'Project Location',
                        locationController,
                        isRequired: true,
                        fieldType: 'location',
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledField(
                        context,
                        'Work Sites',
                        workSiteController,
                        isRequired: true,
                        fieldType: 'workSites',
                      ),
                      const SizedBox(height: 12),
                      _buildLabeledField(
                        context,
                        'Description',
                        descriptionController,
                        isRequired: true,
                        mixLength: 5,
                        fieldType: 'description',
                      ),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmergexButton(
                      onPressed: isLoading ? null : () => back(),
                      text: TextHelper.cancel,
                      textColor: ColorHelper.primaryColor,
                      buttonHeight: 40,
                      borderRadius: 35,
                      fontWeight: FontWeight.bold,
                      borderColor: ColorHelper.white,
                      colors: [ColorHelper.white, ColorHelper.white],
                    ),
                    const SizedBox(width: 10),
                    BlocBuilder<ProjectFormCubit, ProjectFormState>(
                      builder: (context, formState) {
                        final isButtonEnabled =
                            !isLoading &&
                            _isButtonEnabled(
                              formState: formState,
                              isEditMode: isEditMode,
                              projectName: title,
                              location: location,
                              workSite: workSite,
                              description: description,
                            );

                        return Opacity(
                          opacity: isButtonEnabled ? 1.0 : 0.5,
                          child: EmergexButton(
                            onPressed: isButtonEnabled
                                ? () {
                                    // Validate form using cubit
                                    final formCubit = context
                                        .read<ProjectFormCubit>();
                                    if (!formCubit.validateForm()) {
                                      return;
                                    }

                                    // Get clientId from ProjectCubit state or ClientCubit
                                    final projectCubit = AppDI.projectCubit;
                                    final clientCubit = AppDI.clientCubit;

                                    String? clientId;
                                    if (projectCubit.state.clientId != null &&
                                        projectCubit
                                            .state
                                            .clientId!
                                            .isNotEmpty) {
                                      clientId = projectCubit.state.clientId;
                                    } else if (clientCubit
                                        .state
                                        .clients
                                        .isNotEmpty) {
                                      clientId = clientCubit
                                          .state
                                          .clients
                                          .first
                                          .clientId;
                                    }

                                    if (clientId == null || clientId.isEmpty) {
                                      showSnackBar(
                                        context,
                                        'Client ID is required',
                                        isSuccess: false,
                                      );
                                      return;
                                    }
                                    // Create ProjectRequest
                                    final projectRequest = ProjectRequest(
                                      clientId: clientId,
                                      projectName: formState.projectName.trim(),
                                      projectId: codeController.text.trim(),
                                      location: formState.location.trim(),
                                      workSites: formState.workSites.trim(),
                                      description: formState.description.trim(),
                                    );

                                    // Call add or update based on edit mode
                                    if (isEditMode) {
                                      projectCubit.updateProject(
                                        projectRequest,
                                      );
                                    } else {
                                      projectCubit.addProject(projectRequest);
                                    }
                                  }
                                : null,
                            text: isEditMode
                                ? TextHelper.savechanges
                                : TextHelper.add,
                            textColor: ColorHelper.white,
                            buttonHeight: 40,
                            borderRadius: 35,
                            fontWeight: FontWeight.bold,
                          ),
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

  /// Check if button should be enabled based on current form state
  bool _isButtonEnabled({
    required ProjectFormState formState,
    required bool isEditMode,
    required String? projectName,
    required String? location,
    required String? workSite,
    required String? description,
  }) {
    if (isEditMode) {
      // In edit mode: button enabled only if something changed
      final projectNameChanged =
          formState.projectName.trim() != (projectName ?? '');
      final locationChanged = formState.location.trim() != (location ?? '');
      final workSitesChanged = formState.workSites.trim() != (workSite ?? '');
      final descriptionChanged =
          formState.description.trim() != (description ?? '');

      return projectNameChanged ||
          locationChanged ||
          workSitesChanged ||
          descriptionChanged;
    } else {
      // In add mode: button enabled only if all required fields are filled
      final projectNameFilled = formState.projectName.trim().isNotEmpty;
      final locationFilled = formState.location.trim().isNotEmpty;
      final workSitesFilled = formState.workSites.trim().isNotEmpty;
      final descriptionFilled = formState.description.trim().isNotEmpty;

      return projectNameFilled &&
          locationFilled &&
          workSitesFilled &&
          descriptionFilled;
    }
  }

  Widget _buildLabeledField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    String? hintText,
    int? mixLength,
    bool isDisabled = false,
    String? fieldType, // 'projectName', 'location', 'workSites', 'description'
  }) {
    if (isDisabled && controller.text.isEmpty) {
      // Generate unique project ID in format: proXXX
      final timestamp = DateTime.now().millisecondsSinceEpoch
          .toRadixString(36)
          .toUpperCase();
      final randomPart = Random().nextInt(999).toRadixString(36).toUpperCase();
      controller.text = 'PRO-$timestamp$randomPart';
    }
    return BlocBuilder<ProjectFormCubit, ProjectFormState>(
      builder: (context, formState) {
        String? errorText;
        if (fieldType == 'projectName') {
          errorText = formState.projectNameError;
        } else if (fieldType == 'location') {
          errorText = formState.locationError;
        } else if (fieldType == 'workSites') {
          errorText = formState.workSitesError;
        } else if (fieldType == 'description') {
          errorText = formState.descriptionError;
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
                    color: ColorHelper.black4,
                  ),
                ),
                if (isRequired)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '*',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorHelper.starColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            AppTextField(
              controller: controller,
              hint: hintText ?? 'Enter $label',
              fillColor: ColorHelper.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(35),
                borderSide: errorText != null
                    ? BorderSide(color: ColorHelper.starColor, width: 1)
                    : BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              minLines: mixLength ?? 1,
              maxLines: mixLength ?? 1,
              isEditable: !isDisabled,
              onChanged: (value) {
                // Update form cubit when text changes
                final formCubit = context.read<ProjectFormCubit>();
                if (fieldType == 'projectName') {
                  formCubit.updateProjectName(value);
                } else if (fieldType == 'location') {
                  formCubit.updateLocation(value);
                } else if (fieldType == 'workSites') {
                  formCubit.updateWorkSites(value);
                } else if (fieldType == 'description') {
                  formCubit.updateDescription(value);
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

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? title,
    String? code,
    String? workSite,
    String? location,
    String? employees,
    String? createdDate,
    String? status,
    String? description,
    required List<UserFeaturePermission> permissions,
  }) async {
    return showGeneralDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      barrierColor: ColorHelper.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 200),
      barrierLabel: "ProjectDetailsDialog",
      pageBuilder: (context, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(
            child: ProjectDialogBox(
              title: title,
              code: code,
              workSite: workSite,
              location: location,
              description: description,
              permissions: permissions,
            ),
          ),
        );
      },
    );
  }
}
