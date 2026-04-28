import 'package:flutter/material.dart';
import '../../models/chat_attachment_model.dart';
import '../../utils/chat_file_helper.dart';

/// Widget for displaying document/file attachments in chat
/// Matches the design from the reference screenshot
class ChatDocumentAttachmentWidget extends StatefulWidget {
  final ChatAttachment attachment;
  final bool isMe;
  final VoidCallback? onTap;

  const ChatDocumentAttachmentWidget({
    super.key,
    required this.attachment,
    required this.isMe,
    this.onTap,
  });

  @override
  State<ChatDocumentAttachmentWidget> createState() =>
      _ChatDocumentAttachmentWidgetState();
}

class _ChatDocumentAttachmentWidgetState
    extends State<ChatDocumentAttachmentWidget> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _downloadDocument() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final filePath = await ChatFileHelper.downloadFile(
      url: widget.attachment.url,
      fileName: widget.attachment.filename,
      context: context,
      onProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
        });
      },
    );

    setState(() {
      _isDownloading = false;
    });

    if (filePath != null && mounted) {
      ChatFileHelper.showDownloadSuccess(context, filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _downloadDocument,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isMe
              ? const Color(0xFF3DA229)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Document icon with folded corner design
            Container(
              width: 40,
              height: 48,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Main document body
                  Center(
                    child: _isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: _downloadProgress > 0
                                  ? _downloadProgress
                                  : null,
                              strokeWidth: 2,
                              color: widget.isMe ? Colors.white : Colors.grey[600],
                            ),
                          )
                        : Icon(
                            Icons.description_outlined,
                            size: 24,
                            color: widget.isMe ? Colors.white : Colors.grey[600],
                          ),
                  ),
                  // Folded corner effect
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? const Color(0xFF2E8B1E)
                            : Colors.grey[400],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.attachment.filename,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.isMe ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isDownloading
                        ? 'Downloading... ${(_downloadProgress * 100).toInt()}%'
                        : 'Click to download',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Download icon
            if (!_isDownloading)
              Icon(
                Icons.download_rounded,
                size: 22,
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }
}
