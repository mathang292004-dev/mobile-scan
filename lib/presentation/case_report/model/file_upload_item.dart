import 'package:dio/dio.dart';

enum UploadStatus { pending, uploading, paused, completed, failed, cancelled }

class FileUploadItem {
  final String id;
  final String? key;
  final String fileName;
  final String? text;
  final String filePath;
  final int? fileSize;
  final String? fileType;
  final DateTime? createdAt;
  UploadStatus status;
  double progress;
  CancelToken? cancelToken;
  String? error;
  String? errorMessage;
  String? fileUrl;
  String? infoId;

  FileUploadItem({
    required this.id,
    this.key,
    required this.fileName,
    this.text,
    required this.filePath,
    this.fileSize,
    this.fileType,
    this.createdAt,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.cancelToken,
    this.error,
    this.errorMessage,
    this.fileUrl,
    this.infoId,
  });
}
