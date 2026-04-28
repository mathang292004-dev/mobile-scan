import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/case_report/report_emergex/cubit/incident_file_handle_cubit.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:emergex/presentation/case_report/utils/case_report_formatter_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileRowWidget extends StatelessWidget {
  final FileUploadItem recording;
  final bool isPlaying;
  final Function(FileUploadItem) onPlayAudio;
  final Function(bool) onDeleted;

  const FileRowWidget({
    super.key,
    required this.recording,
    required this.isPlaying,
    required this.onPlayAudio,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 120,
          maxWidth: 140, // allow a bit more room for long filenames
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorHelper.fileRowBackground.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with icon + delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ColorHelper.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(Assets.mp3, width: 28, height: 28),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: ColorHelper.recycleBinBackground,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    icon: Image.asset(
                      Assets.reportIncidentRecycleBin,
                      width: 16, // your desired width
                      height: 16, // your desired height
                    ),
                    onPressed: () async {
                      bool isDeleted = await context
                          .read<IncidentFileHandleCubit>()
                          .deleteFileFromServer(
                            recording.infoId!,
                            'audio',
                            false,
                          );
                      onDeleted(isDeleted);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Title (filename)
            Flexible(
              child: Text(
                recording.fileName,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ColorHelper.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // File size
            Text(
              CaseReportFormatterUtils.formatFileSize(recording.fileSize ?? 0),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ColorHelper.fileRowText),
            ),
          ],
        ),
      ),
    );
  }

}
