import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_documents_screen_cubit/upload_documents_screen_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/upload_documents_utils.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/file_upload/category_tabs_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/file_upload/file_tile_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/file_upload/important_notes_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/file_upload/upload_instructions_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/file_upload_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../generated/color_helper.dart';
import '../../../../../helpers/routes.dart';
import '../../../../../helpers/text_helper.dart';
import '../../../../../helpers/widgets/core/app_bar_widget.dart';
import '../../../../../helpers/widgets/feedback/app_loader.dart';
import '../../../../../helpers/widgets/core/app_scaffold.dart';
import '../../../../../helpers/widgets/inputs/emergex_button.dart';

class UploadDocumentsScreen extends StatelessWidget {
  final String? selectedCategory;
  const UploadDocumentsScreen({super.key, this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final organizationCubit = AppDI.onboardingOrganizationStructureCubit;

    // Set selected category if provided and different from current state
    // Always use postFrameCallback to avoid mutating state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentCategory = organizationCubit.state.selectedCategory;
      final targetCategory = selectedCategory ?? 'Project Specific';
      if (currentCategory != targetCategory) {
        organizationCubit.selectCategory(targetCategory);
      }
    });

    return BlocProvider.value(
      value: organizationCubit,
      child: BlocProvider(
        create: (_) => UploadDocumentsScreenCubit(organizationCubit),
        child:
            BlocConsumer<
              OnboardingOrganizationStructureCubit,
              OnboardingOrganizationStructureState
            >(
              listener: (context, state) {
                final cubit = context.read<UploadDocumentsScreenCubit>();
                cubit.handleStateChanges(context, state);

                // General loader for other loading states (excluding file uploads and document uploads)
                // Show loader when:
                // - processState is loading
                // - NOT uploading document (continue button has its own dialog)
                // - NOT uploading files (file uploads have inline progress indicators)
                final isFileUploading = state.fileUploadProgress.isNotEmpty;
                final isDocumentUploading = state.isUploadingDocument;

                if (state.processState == ProcessState.loading &&
                    !isDocumentUploading &&
                    !isFileUploading) {
                  loaderService.showLoader();
                } else if (state.processState == ProcessState.done ||
                    state.processState == ProcessState.error) {
                  // Only hide loader if it's not a file or document upload
                  if (!isDocumentUploading && !isFileUploading) {
                    loaderService.hideLoader();
                  }
                }
              },
              builder: (context, state) {
                final screenCubit = context.read<UploadDocumentsScreenCubit>();
                final cubit = screenCubit.organizationCubit;
                return AppScaffold(
                  useGradient: true,
                  extendBody: true,
                  gradientBegin: Alignment.topCenter,
                  gradientEnd: Alignment.bottomCenter,
                  showDrawer: false,
                  showBottomNav: false,
                  appBar: const AppBarWidget(
                    showNotificationIcon: false,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (cubit
                                        .state
                                        .filesForSelectedCategory
                                        .isNotEmpty) {
                                      showErrorDialog(
                                        context,
                                        () {
                                          cubit.clearFiles();

                                          back();

                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                back();
                                              });
                                        },
                                        () {
                                          back(); // NO → just close dialog
                                        },
                                        TextHelper.areYouSure,
                                        TextHelper.areYouWantToLeaveThisPage,
                                        TextHelper.yes,
                                        TextHelper.no,
                                      );

                                      return;
                                    }
                                    // Just navigate back - no need to clear state
                                    back();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorHelper.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: ColorHelper.textLight,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_left,
                                      size: 24,
                                      color: ColorHelper.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Upload Documents',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            ColorHelper.organizationStructure,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: ColorHelper.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: ColorHelper.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'File Upload by Category',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: ColorHelper.black4,
                                                ),
                                          ),
                                          const SizedBox(height: 15),
                                          CategoryTabsWidget(
                                            selectedCategory: selectedCategory,
                                          ),
                                          const SizedBox(height: 25),
                                          UploadInstructionsWidget(
                                            cubit: cubit,
                                          ),
                                          const SizedBox(height: 20),
                                          BlocBuilder<
                                            OnboardingOrganizationStructureCubit,
                                            OnboardingOrganizationStructureState
                                          >(
                                            builder: (context, state) {
                                              final filesForCategory = state
                                                  .filesForSelectedCategory;

                                              // if (filesForCategory.isEmpty) {
                                              //   return const SizedBox.shrink();
                                              // }
                                              return Column(
                                                children: [
                                                  // File list
                                                  ...List.generate(filesForCategory.length, (
                                                    index,
                                                  ) {
                                                    final file =
                                                        filesForCategory[index];
                                                    final fileName = file
                                                        .fileName
                                                        .split('/')
                                                        .last;
                                                    final fileSize =
                                                        UploadDocumentsUtils.formatFileSize(
                                                          file.fileSize,
                                                        );
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 12.0,
                                                          ),
                                                      child: FileTileWidget(
                                                        fileName: fileName,
                                                        fileSize: fileSize,
                                                        fileUrl: file.fileUrl,
                                                        onRemove: () => cubit
                                                            .removeFile(index),
                                                        onTap: () {
                                                          final url = file.fileUrl;
                                                          if (url.isEmpty) return;
                                                          final ext = fileName
                                                              .toLowerCase()
                                                              .split('.')
                                                              .last;
                                                          if (ext == 'pdf' ||
                                                              file.fileType.toLowerCase() == 'pdf') {
                                                            UploadDocumentsUtils.showPdfViewerDialog(
                                                              context,
                                                              url,
                                                              fileName,
                                                            );
                                                          } else if (ext == 'doc' ||
                                                              ext == 'docx') {
                                                            UploadDocumentsUtils.openDocumentFile(
                                                              context,
                                                              url,
                                                              fileName,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  }),
                                                  // Inline progress loaders for individual file uploads
                                                  // Show separate progress indicator for each file being uploaded
                                                  // Only show progress for files in the current category
                                                  Builder(
                                                    builder: (context) {
                                                      final filteredProgress = cubit
                                                          .getFileUploadProgressForCategory(
                                                            state
                                                                .selectedCategory,
                                                          );
                                                      if (filteredProgress
                                                          .isEmpty) {
                                                        return const SizedBox.shrink();
                                                      }
                                                      return Column(
                                                        children: filteredProgress.entries.map((
                                                          entry,
                                                        ) {
                                                          final filePath =
                                                              entry.key;
                                                          final progress =
                                                              entry.value;
                                                          final fileName =
                                                              state
                                                                  .uploadingFileNames[filePath] ??
                                                              filePath
                                                                  .split('/')
                                                                  .last;

                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 12.0,
                                                                ),
                                                            child: ProgressSectionWidget(
                                                              progress:
                                                                  (progress *
                                                                          100)
                                                                      .clamp(
                                                                        0.0,
                                                                        100.0,
                                                                      ),
                                                              fileName:
                                                                  fileName,
                                                              onCancel: () {
                                                                cubit
                                                                    .cancelFileUploadById(
                                                                      filePath,
                                                                    );
                                                              },
                                                            ),
                                                          );
                                                        }).toList(),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    const ImportantNotesWidget(),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: ColorHelper.surfaceColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  EmergexButton(
                                    disabled: cubit
                                          .state
                                          .filesForSelectedCategory
                                          .isEmpty,
                                    text: TextHelper.saveasdraft,
                                    borderRadius: 12,
                                    textColor: ColorHelper.primaryColor,
                                    colors: [
                                      ColorHelper.surfaceColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      ColorHelper.surfaceColor.withValues(
                                        alpha: 0.6,
                                      ),
                                    ],
                                    onPressed: () {
                                      final orgCubit = AppDI
                                          .onboardingOrganizationStructureCubit;
                                      final projectId =
                                          orgCubit.state.selectedProjectId;

                                      if (cubit
                                          .state
                                          .filesForSelectedCategory
                                          .isEmpty) {
                                        return;
                                      }

                                      // Set flag to navigate back when draft save completes
                                      final screenCubit = context
                                          .read<UploadDocumentsScreenCubit>();
                                      screenCubit
                                          .setShouldNavigateBackOnDraftComplete(
                                            true,
                                          );

                                      if (selectedCategory == 'General Docs') {
                                        // For General Docs, upload to all projects
                                        final projects =
                                            AppDI
                                                .emergexAppCubit
                                                .state
                                                .userPermissions
                                                ?.projects ??
                                            [];
                                        final projectIds = projects
                                            .map((p) => p.projectId)
                                            .toList();

                                        if (projectIds.isEmpty) {
                                          return;
                                        }

                                        cubit.uploadDocsForAllProjects(
                                          projectIds,
                                          true,
                                        );
                                      } else {
                                        // For other categories, upload to single project
                                        if (projectId == null ||
                                            projectId.isEmpty) {
                                          return;
                                        }
                                        cubit.uploadDocument(projectId, true);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  EmergexButton(
                                    disabled: cubit
                                            .state
                                            .filesForSelectedCategory
                                            .isEmpty ||
                                        state.fileUploadProgress.isNotEmpty ||
                                        state.isUploadingDocument,
                                    text: TextHelper.continue_,
                                    textColor: ColorHelper.white,
                                    borderRadius: 12,

                                    onPressed: () async {
                                      final orgCubit = AppDI
                                          .onboardingOrganizationStructureCubit;
                                      final projectId =
                                          orgCubit.state.selectedProjectId;
                                      final screenCubit = context
                                          .read<UploadDocumentsScreenCubit>();

                                      if (cubit
                                          .state
                                          .filesForSelectedCategory
                                          .isEmpty) {
                                        return;
                                      }

                                      if (selectedCategory == 'General Docs') {
                                        // For General Docs, upload to all projects
                                        final projects =
                                            AppDI
                                                .emergexAppCubit
                                                .state
                                                .userPermissions
                                                ?.projects ??
                                            [];
                                        final projectIds = projects
                                            .map((p) => p.projectId)
                                            .toList();

                                        if (projectIds.isEmpty) {
                                          return;
                                        }

                                        await cubit.uploadDocsForAllProjects(
                                          projectIds,
                                          false,
                                        );

                                        // Ensure dialog is dismissed before navigation
                                        if (context.mounted) {
                                          screenCubit.dismissDialog(context);
                                        }

                                        // Navigate to project screen after successful upload
                                        if (cubit.state.processState ==
                                            ProcessState.done) {
                                          openScreen(
                                            Routes.viewprojectscreen,
                                            shouldReplace: true,
                                          );
                                        }
                                      } else {
                                        // For other categories, upload to single project
                                        if (projectId == null ||
                                            projectId.isEmpty) {
                                          return;
                                        }
                                        await cubit.uploadDocument(
                                          projectId,
                                          false,
                                        );

                                        // Ensure dialog is dismissed before navigation
                                        if (context.mounted) {
                                          screenCubit.dismissDialog(context);
                                        }

                                        // Navigate to roles screen for other categories
                                        if (cubit.state.processState ==
                                            ProcessState.done) {
                                          openScreen(
                                            Routes.rolesScreen,
                                            shouldReplace: true,
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
