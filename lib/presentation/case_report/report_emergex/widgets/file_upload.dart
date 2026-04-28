import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/file_item_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/file_upload_progress_card.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/image_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/di/app_di.dart';

class FileUpload extends StatelessWidget {
  const FileUpload({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.incidentFileHandleCubit;

    return BlocConsumer<IncidentFileHandleCubit, IncidentState>(
      listener: (context, state) {
        // Handle state changes if needed
      },
      builder: (context, state) {
        final incident = state.data.isNotEmpty ? state.data.first : null;
        final bool isUploading = state.fileProcessState == ProcessState.loading;
        final Map<String, double> uploadProgress = state.uploadProgress;
        final Map<String, String> uploadingFileNames = state.uploadingFileNames;
        // Combine all server files into a single list for display
        final List<FileUploadItem> allFiles = [];
        if (incident?.uploadedFiles != null) {
          if (incident!.uploadedFiles!.images.isNotEmpty) {
            allFiles.addAll(
              incident.uploadedFiles!.images.map(
                (file) => FileUploadItem(
                  id: file.key ?? UniqueKey().toString(),
                  fileName: file.fileName ?? '',
                  filePath: file.fileUrl ?? '',
                  fileType: 'image',
                  key: file.key,
                  fileUrl: file.fileUrl,
                  fileSize: file.fileSize,
                  status: UploadStatus.completed,
                  infoId: file.infoId,
                ),
              ),
            );
          }
          if (incident.uploadedFiles!.video.isNotEmpty) {
            allFiles.addAll(
              incident.uploadedFiles!.video.map(
                (file) => FileUploadItem(
                  id: file.key ?? UniqueKey().toString(),
                  fileName: file.fileName ?? '',
                  filePath: file.fileUrl ?? '',
                  fileType: 'video',
                  key: file.key,
                  fileUrl: file.fileUrl,
                  fileSize: file.fileSize,
                  status: UploadStatus.completed,
                  infoId: file.infoId,
                ),
              ),
            );
          }
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFileUploadCard(
                context,
                cubit,
                allFiles,
                isUploading,
                uploadProgress,
                uploadingFileNames,
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  /// Builds the main card for adding and viewing files.
  Widget _buildFileUploadCard(
    BuildContext context,
    IncidentFileHandleCubit cubit,
    List<FileUploadItem> allFiles,
    bool isUploading,
    Map<String, double> uploadProgress,
    Map<String, String> uploadingFileNames,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorHelper.surfaceColor.withAlpha(128),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TextHelper.fileUpload,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ColorHelper.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TextHelper.afterRecording,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorHelper.tertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Disable the "Add Files" button during an upload
              EmergexButton(
                colors: [ColorHelper.surfaceColor, ColorHelper.surfaceColor],
                onPressed: cubit.pickAndUploadFiles,
                text: TextHelper.addFiles,
                leadingIcon:
                    // isUploading
                    //     ? const SizedBox(
                    //         width: 16,
                    //         height: 16,
                    //         child: CircularProgressIndicator(strokeWidth: 2),
                    //       )
                    //     :
                    const Icon(Icons.add),
                textColor: ColorHelper.selectedIconBackground,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            TextHelper.onlySupport,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
          ),
          const SizedBox(height: 24),

          // Show progress widgets for each file being uploaded
          if (isUploading && uploadProgress.isNotEmpty)
            ...uploadProgress.entries.map((entry) {
              final fileId = entry.key;
              final progress = entry.value;
              final fileName = uploadingFileNames[fileId] ?? 'Unknown file';
              return ProgressSectionWidget(
                key: ValueKey(fileId),
                progress: progress,
                fileName: fileName,
                onCancel: () => cubit.cancelFileUpload(fileId),
              );
            }),

          // Show uploaded files (always show if there are any, even while uploading others)
          if (allFiles.isNotEmpty)
            Column(
              children: allFiles.asMap().entries.map((entry) {
                final int index = entry.key;
                final FileUploadItem item = entry.value;

                return GestureDetector(
                  onTap: () {
                    // Show the new image preview dialog with navigation
                    showBlurredDialog(
                      context: context,
                      builder: (context) => ImagePreviewDialog(
                        images: allFiles,
                        initialIndex: index,
                        onDelete: (fileKey) {
                          if (fileKey != null) {
                            cubit.deleteFileFromServer(
                              item.infoId!,
                              "file",
                              false,
                            );
                          }
                        },
                      ),
                    );
                  },
                  child: FileItemWidget(
                    item: item,
                    onDelete: (fileKey) {
                      if (fileKey != null) {
                        cubit.deleteFileFromServer(item.infoId!, "file", false);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
