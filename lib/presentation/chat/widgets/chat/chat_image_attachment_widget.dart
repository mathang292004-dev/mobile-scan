import 'package:flutter/material.dart';
import '../../models/chat_attachment_model.dart';
import '../../utils/chat_file_helper.dart';

/// Widget for displaying image attachments in chat (WhatsApp-style)
class ChatImageAttachmentWidget extends StatefulWidget {
  final ChatAttachment attachment;
  final bool isMe;
  final VoidCallback? onTap;

  const ChatImageAttachmentWidget({
    super.key,
    required this.attachment,
    required this.isMe,
    this.onTap,
  });

  @override
  State<ChatImageAttachmentWidget> createState() =>
      _ChatImageAttachmentWidgetState();
}

class _ChatImageAttachmentWidgetState extends State<ChatImageAttachmentWidget> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _downloadImage() async {
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

  void _showFullScreenImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(
          imageUrl: widget.attachment.url,
          filename: widget.attachment.filename,
          onDownload: _downloadImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _showFullScreenImage,
      onLongPress: _downloadImage,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: widget.isMe
              ? const Color(0xFF3DA229).withValues(alpha: 0.1)
              : Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                widget.attachment.url,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF3DA229),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image failed to load',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Download overlay when downloading
              if (_isDownloading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            value: _downloadProgress > 0 ? _downloadProgress : null,
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_downloadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Download icon hint at bottom right
              if (!_isDownloading)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen image view with download option
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String filename;
  final VoidCallback onDownload;

  const _FullScreenImageView({
    required this.imageUrl,
    required this.filename,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          filename,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              onDownload();
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 60,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}