import 'dart:io';
import 'package:dio/dio.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app viewer for DOC/DOCX files using Google Docs Viewer.
/// Matches PdfViewerDialog UI — same header, share/download buttons, loading/error states.
class DocViewerDialog extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const DocViewerDialog({
    super.key,
    required this.fileUrl,
    required this.fileName,
  });

  @override
  State<DocViewerDialog> createState() => _DocViewerDialogState();
}

class _DocViewerDialogState extends State<DocViewerDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDownloading = false;
  bool _isSharing = false;

  String get _viewerUrl =>
      'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.fileUrl)}';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _hasError = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(_viewerUrl));
  }

  /// Download file to device's Downloads folder
  Future<void> _downloadToDevice() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            if (mounted) {
              _showSnackBar(
                'Storage permission required to download files',
                isError: true,
              );
            }
            setState(() => _isDownloading = false);
            return;
          }
        }
      }

      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        downloadDir = await getDownloadsDirectory();
      }

      if (downloadDir == null) {
        if (mounted) {
          _showSnackBar('Unable to access download directory', isError: true);
        }
        setState(() => _isDownloading = false);
        return;
      }

      final sanitized = _sanitizeFileName(widget.fileName);
      String filePath = '${downloadDir.path}/$sanitized';

      if (await File(filePath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = sanitized.contains('.')
            ? '.${sanitized.split('.').last}'
            : '';
        final base = sanitized.contains('.')
            ? sanitized.substring(0, sanitized.lastIndexOf('.'))
            : sanitized;
        filePath = '${downloadDir.path}/${base}_$timestamp$ext';
      }

      await Dio().download(widget.fileUrl, filePath);

      if (mounted) {
        _showSnackBar('File downloaded successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to download: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  /// Share the document file
  Future<void> _shareFile() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _sanitizeFileName(widget.fileName);
      final file = File('${tempDir.path}/$fileName');

      if (!await file.exists()) {
        await Dio().download(widget.fileUrl, file.path);
      }

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sharing ${widget.fileName}',
      );

      if (result.status == ShareResultStatus.success) {
        debugPrint('File shared successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to share: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? ColorHelper.errorColor
            : const Color(0xFF3DA229),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: ColorHelper.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header — matches PdfViewerDialog exactly
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ColorHelper.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.fileName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Share button
                IconButton(
                  onPressed: _isSharing || _isLoading ? null : _shareFile,
                  icon: _isSharing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorHelper.primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.share,
                          color: _isLoading
                              ? Colors.grey
                              : ColorHelper.primaryColor,
                        ),
                  tooltip: 'Share',
                ),
                // Download button
                IconButton(
                  onPressed: _isDownloading || _isLoading
                      ? null
                      : _downloadToDevice,
                  icon: _isDownloading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorHelper.primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.download,
                          color: _isLoading
                              ? Colors.grey
                              : ColorHelper.primaryColor,
                        ),
                  tooltip: 'Download',
                ),
                // Close button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: ColorHelper.textSecondary),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: ColorHelper.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Failed to load document.\nCheck your internet connection and try again.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: ColorHelper.errorColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            _controller.loadRequest(Uri.parse(_viewerUrl));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorHelper.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isLoading)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ColorHelper.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading document...',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: ColorHelper.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
