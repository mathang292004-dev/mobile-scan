import 'dart:io';
import 'package:dio/dio.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// PDF Viewer Dialog Widget
class PdfViewerDialog extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const PdfViewerDialog({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  State<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<PdfViewerDialog> {
  String? _localFilePath;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isSharing = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  void _goToPreviousPage() {
    if (_pdfViewController != null && _currentPage > 0) {
      _pdfViewController!.setPage(_currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_pdfViewController != null && _currentPage < _totalPages - 1) {
      _pdfViewController!.setPage(_currentPage + 1);
    }
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // ApplicationDocumentsDirectory is reliably writable on all platforms
      final appDir = await getApplicationDocumentsDirectory();
      // Ensure unique filename per request to avoid session collisions
      final uniqueFileName =
          '${widget.fileName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${appDir.path}/$uniqueFileName');

      debugPrint('Downloading PDF to: ${file.path}');

      final response = await Dio().download(
        widget.pdfUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
              'Download progress: ${((received / total) * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      if (await file.exists()) {
        final bytes = await file.length();
        if (bytes < 10) {
          throw Exception(
            'Downloaded file is empty or corrupted (size: $bytes bytes)',
          );
        }

        if (mounted) {
          setState(() {
            _localFilePath = file.path;
            _isLoading = false;
          });
          debugPrint('PDF file ready for viewing: $bytes bytes');
        }
      } else {
        throw Exception('File was not saved after download');
      }
    } catch (e) {
      debugPrint('PDF loading failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load PDF. Please check your connection.\n\nError: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Download PDF to device's Downloads folder
  Future<void> _downloadToDevice() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Request storage permission on Android
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
            setState(() {
              _isDownloading = false;
            });
            return;
          }
        }
      }

      // Get download directory
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
        setState(() {
          _isDownloading = false;
        });
        return;
      }

      // Create unique filename to avoid overwriting
      final sanitizedFileName = _sanitizeFileName(widget.fileName);
      String filePath = '${downloadDir.path}/$sanitizedFileName';

      // If file exists, add timestamp to make unique
      if (await File(filePath).exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = sanitizedFileName.contains('.')
            ? '.${sanitizedFileName.split('.').last}'
            : '';
        final baseName = sanitizedFileName.contains('.')
            ? sanitizedFileName.substring(0, sanitizedFileName.lastIndexOf('.'))
            : sanitizedFileName;
        filePath = '${downloadDir.path}/${baseName}_$timestamp$extension';
      }

      // Download the file
      await Dio().download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Optional: Show download progress
          }
        },
      );

      if (mounted) {
        _showSnackBar('PDF downloaded successfully to $filePath');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to download: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// Share PDF file
  Future<void> _sharePdf() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // Ensure the file is downloaded locally first
      if (_localFilePath == null || !await File(_localFilePath!).exists()) {
        // Download to temp if not already there
        final tempDir = await getTemporaryDirectory();
        final fileName = _sanitizeFileName(widget.fileName);
        final file = File('${tempDir.path}/$fileName');

        await Dio().download(widget.pdfUrl, file.path);
        _localFilePath = file.path;
      }

      // Share the file
      final result = await Share.shareXFiles([
        XFile(_localFilePath!),
      ], text: 'Sharing ${widget.fileName}');

      if (result.status == ShareResultStatus.success) {
        debugPrint('PDF shared successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to share: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  /// Sanitize filename to remove invalid characters
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
          // Header with title, action buttons, and close button
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
                  onPressed: _isSharing || _isLoading ? null : _sharePdf,
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
                  tooltip: 'Share PDF',
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
                  tooltip: 'Download PDF',
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
          // Page indicator with navigation buttons
          if (!_isLoading && _errorMessage == null && _totalPages > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ColorHelper.white.withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  IconButton(
                    onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                    icon: Icon(
                      Icons.chevron_left,
                      color: _currentPage > 0
                          ? ColorHelper.primaryColor
                          : Colors.grey,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _currentPage > 0
                          ? ColorHelper.primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Page indicator
                  Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.textSecondary,
                    ),
                  ),
                  // Next button
                  IconButton(
                    onPressed: _currentPage < _totalPages - 1
                        ? _goToNextPage
                        : null,
                    icon: Icon(
                      Icons.chevron_right,
                      color: _currentPage < _totalPages - 1
                          ? ColorHelper.primaryColor
                          : Colors.grey,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _currentPage < _totalPages - 1
                          ? ColorHelper.primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // PDF Viewer
          Expanded(
            child: _isLoading
                ? Center(
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
                          'Loading PDF...',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: ColorHelper.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
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
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: ColorHelper.errorColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadPdf,
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
                : _localFilePath != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: PDFView(
                      filePath: _localFilePath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      fitEachPage: false,
                      fitPolicy: FitPolicy.BOTH,
                      onRender: (pages) {
                        if (mounted) {
                          setState(() {
                            _totalPages = pages ?? 0;
                          });
                        }
                      },
                      onError: (error) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = 'Error loading PDF: $error';
                          });
                        }
                      },
                      onPageError: (page, error) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = 'Error on page $page: $error';
                          });
                        }
                      },
                      onViewCreated: (PDFViewController controller) {
                        _pdfViewController = controller;
                      },
                      onPageChanged: (int? page, int? total) {
                        if (mounted) {
                          setState(() {
                            _currentPage = page ?? 0;
                            _totalPages = total ?? 0;
                          });
                        }
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
