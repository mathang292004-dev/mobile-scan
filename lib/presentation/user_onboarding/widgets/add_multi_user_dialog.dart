import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart'
    show loaderService;
import 'package:emergex/presentation/user_onboarding/cubit/add_multi_user_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

const String _sampleDocumentUrl =
    'https://emergex-dev.s3.ap-southeast-1.amazonaws.com/files/Sample.xlsx';

class AddMultiUserDialog extends StatelessWidget {
  const AddMultiUserDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.addMultiUserCubit;
    cubit.resetForm();

    return BlocListener<AddMultiUserCubit, AddMultiUserState>(
      bloc: cubit,
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == AddMultiUserStatus.uploading ||
            state.status == AddMultiUserStatus.validating) {
          loaderService.showLoader();
        } else if (state.status == AddMultiUserStatus.success) {
          loaderService.hideLoader();
          Navigator.pop(context, true);
        } else {
          loaderService.hideLoader();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: BlocBuilder<AddMultiUserCubit, AddMultiUserState>(
          bloc: cubit,
          builder: (context, state) {
            final isFileUploaded = state.isFileUploaded;
            final hasValidUsers = state.validUsers.isNotEmpty;
            final canAddUsers =
                state.status == AddMultiUserStatus.validated && hasValidUsers;
            final noValidUsersError =
                state.status == AddMultiUserStatus.validated && !hasValidUsers;
            final showError = state.hasUploadError || noValidUsersError;
            final errorMsg = state.errorMessage ?? TextHelper.noDataAvailable;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ColorHelper.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16.77),
                border: Border.all(color: ColorHelper.white, width: 0.7),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title + Add Files button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          TextHelper.addMultiUser,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: ColorHelper.black4,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                        ),
                        EmergexButton(
                          onPressed: isFileUploaded ? null : cubit.pickFile,
                          text: TextHelper.addFiles,
                          textColor: ColorHelper.primaryColor,
                          textSize: 14,
                          disabled: isFileUploaded,
                          colors: [ColorHelper.white, ColorHelper.white],
                          leadingIcon: Icon(
                            Icons.add,
                            size: 16,
                            color: ColorHelper.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // File type info
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        TextHelper.onlySupportCsvXlsx,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.textColorDefault,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Error message — positioned between subtitle and Sample Documents
                    if (showError) _buildErrorSection(context, errorMsg),
                    if (showError) const SizedBox(height: 10),

                    // Sample Documents — download only
                    _buildSection(
                      context,
                      title: TextHelper.sampleDocuments,
                      child: _buildFileRow(
                        context,
                        fileName: 'List of user details .CSV',
                        fileSize: '8KB',
                        showDownload: true,
                        onTap: () async {
                          final uri = Uri.parse(_sampleDocumentUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Upload File section — heading always visible
                    _buildSection(
                      context,
                      title: TextHelper.uploadFile,
                      child: state.selectedFile != null
                          ? _buildFileRow(
                              context,
                              fileName: state.selectedFile!.name,
                              fileSize: cubit.formatFileSize(
                                state.selectedFile!.size,
                                filePath: state.selectedFile!.path,
                              ),
                              showDelete: true,
                              onDelete: cubit.removeFile,
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EmergexButton(
                          onPressed: () => back(),
                          text: TextHelper.cancel,
                          textColor: ColorHelper.primaryColor,
                          colors: [
                            ColorHelper.white.withValues(alpha: 0.5),
                            ColorHelper.white.withValues(alpha: 0.5),
                          ],
                          textSize: 14,
                          borderRadius: 24,
                        ),
                        const SizedBox(width: 8),
                        EmergexButton(
                          onPressed: canAddUsers ? cubit.uploadUsers : null,
                          text: TextHelper.addUser,
                          textSize: 14,
                          borderRadius: 24,
                          disabled: !canAddUsers,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context, String? errorMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorHelper.uploadErrorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline,
              size: 24,
              color: ColorHelper.uploadErrorText,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TextHelper.uploadFailedTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ColorHelper.uploadErrorText,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  errorMessage ?? TextHelper.uploadFailedMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.uploadErrorText,
                    fontSize: 12,
                  ),
                ),
                // Only show the retry hint when no backend message is present,
                // because the backend error already includes this text.
                if (errorMessage == null)
                  Text(
                    TextHelper.uploadFailedRetryMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.uploadErrorText,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: ColorHelper.black4,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildFileRow(
    BuildContext context, {
    required String fileName,
    required String fileSize,
    bool showDownload = false,
    bool showDelete = false,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Image.asset(
              Assets.csvFileIcon,
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.insert_drive_file,
                size: 20,
                color: ColorHelper.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 5.59),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.textPrimary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSize.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    fileSize,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.textColorDefault,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showDownload)
            GestureDetector(
              onTap: onTap,
              child: Image.asset(Assets.downloadIcon,width: 22,height: 22,),
            ),
          if (showDelete)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.cancel_outlined,
                size: 18,
                color: ColorHelper.deleteIconColor,
              ),
            ),
        ],
      ),
    );
  }
}
