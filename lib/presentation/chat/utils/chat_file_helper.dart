import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper class for handling chat file operations (download, preview)
class ChatFileHelper {
  static final Dio _dio = Dio();

  /// Download a file from URL and save to device
  /// Returns the local file path if successful, null otherwise
  static Future<String?> downloadFile({
    required String url,
    required String fileName,
    required BuildContext context,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final manageStatus =
              await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission required to download files'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return null;
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to access download directory'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Create unique filename to avoid overwriting
      final sanitizedFileName = _sanitizeFileName(fileName);
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
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
          }
        },
      );

      return filePath;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Sanitize filename to remove invalid characters
  static String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  /// Get icon for document type based on file extension
  static IconData getDocumentIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get color for document type based on file extension
  static Color getDocumentColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber;
      case 'txt':
        return Colors.grey;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Colors.purple;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }

  /// Show download success snackbar
  static void showDownloadSuccess(BuildContext context, String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Downloaded to: $filePath',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3DA229),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
