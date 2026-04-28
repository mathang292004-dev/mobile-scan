import 'package:equatable/equatable.dart';

/// Incident File Upload Response Model
class IncidentFileUploadResponse extends Equatable {
  final List<UploadedFileItem> files;

  const IncidentFileUploadResponse({
    required this.files,
  });

  factory IncidentFileUploadResponse.fromJson(dynamic json) {
    if (json == null) {
      return const IncidentFileUploadResponse(files: []);
    }

    // Handle response format: { "status": 200, "message": "Success", "data": [...] }
    List<dynamic> fileList = [];
    if (json is Map<String, dynamic>) {
      if (json['data'] is List) {
        fileList = json['data'] as List<dynamic>;
      }
    } else if (json is List) {
      fileList = json;
    }

    return IncidentFileUploadResponse(
      files: fileList
          .whereType<Map<String, dynamic>>()
          .map((e) => UploadedFileItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': files.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [files];
}

/// Uploaded File Item Model
class UploadedFileItem extends Equatable {
  final String fileUrl;
  final String key;
  final String fileType;
  final int fileSize;
  final String fileName;

  const UploadedFileItem({
    required this.fileUrl,
    required this.key,
    required this.fileType,
    required this.fileSize,
    required this.fileName,
  });

  factory UploadedFileItem.fromJson(Map<String, dynamic> json) {
    return UploadedFileItem(
      fileUrl: json['fileUrl']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : json['fileSize'] is String
              ? int.tryParse(json['fileSize'] as String) ?? 0
              : 0,
      fileName: json['fileName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      'key': key,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileName': fileName,
    };
  }

  @override
  List<Object?> get props => [fileUrl, key, fileType, fileSize, fileName];
}

