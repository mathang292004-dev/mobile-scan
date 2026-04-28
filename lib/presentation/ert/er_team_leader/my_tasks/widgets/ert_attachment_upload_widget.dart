import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:flutter/material.dart';

class ErtAttachmentUploadWidget extends StatelessWidget {
  final FileUploadItem item;
  final VoidCallback onDelete;

  const ErtAttachmentUploadWidget({
    super.key,
    required this.item,
    required this.onDelete,
  });

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final sizeLabel = _formatFileSize(item.fileSize);
    final isUploading = item.status == UploadStatus.uploading;
    final isFailed = item.status == UploadStatus.failed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 20,
                color: ColorHelper.successColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0B0B0B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sizeLabel.isNotEmpty)
                      Text(
                        sizeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isUploading && !isFailed)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF6D6D6D)),
                ),
              if (isFailed)
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red,
                ),
            ],
          ),
          if (isUploading) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: item.progress / 100,
                backgroundColor: const Color(0xFFEFEFEF),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorHelper.successColor,
                ),
                minHeight: 5.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Uploading ${item.progress.toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ],
          if (isFailed) ...[
            const SizedBox(height: 4),
            Text(
              item.errorMessage ?? 'Upload failed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColorHelper.errorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
