import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:emergex/presentation/case_report/report_emergex/utils/file_upload_manager.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/file_upload_progress_card.dart';
import 'package:emergex/presentation/case_report/utils/case_report_formatter_utils.dart';
import 'package:flutter/material.dart';

class FileItemWidget extends StatelessWidget {
  final FileUploadItem item;
  final Function(String?) onDelete;

  const FileItemWidget({
    super.key,
    required this.item,
    required this.onDelete,
  });

  /// Get readable filename (from fileName or from fileUrl fallback)
  String get decodedFileName =>
      CaseReportFormatterUtils.resolveFileName(item.fileName, item.fileUrl);

  @override
  Widget build(BuildContext context) {
    // Show progress card during upload/paused
    if (item.status == UploadStatus.uploading ||
        item.status == UploadStatus.paused) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorHelper.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ColorHelper.appBarDark.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ProgressSectionWidget(
          progress: item.progress * 100.0, // Convert from 0-1 to 0-100
          fileName: decodedFileName,
        ),
      );
    }

    // Normal completed upload state
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorHelper.surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Image.asset(
            FileUploadManager.getFileIconData(item.fileType ?? ''),
            width: 24,
            height: 24,
            color: ColorHelper.buttonColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  decodedFileName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ColorHelper.textPrimary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.fileSize != null && item.fileSize! > 0)
                  Text(
                    CaseReportFormatterUtils.formatFileSizeAuto(item.fileSize),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorHelper.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onDelete(item.key),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ColorHelper.errorColor, width: 1),
              ),
              child: const Icon(
                Icons.close,
                color: ColorHelper.errorColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
