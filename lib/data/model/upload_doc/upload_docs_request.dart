import 'package:equatable/equatable.dart';

/// File item model for uploaded files
class FileItem extends Equatable {
  final String fileUrl;
  final String key;
  final String fileType;
  final int fileSize;
  final String fileName;

  const FileItem({
    required this.fileUrl,
    required this.key,
    required this.fileType,
    required this.fileSize,
    required this.fileName,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileUrl: json['fileUrl']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : int.tryParse(json['fileSize']?.toString() ?? '0') ?? 0,
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

/// Request model for uploading documents for all projects
class UploadDocsRequest extends Equatable {
  final List<String> projectIds;
  final List<FileItem>? projectSpecific;
  final List<FileItem>? clientsInternal;
  final List<FileItem>? clientRef;
  final List<FileItem>? global;
  final bool? saveAsDraft;

  const UploadDocsRequest({
    required this.projectIds,
    this.projectSpecific,
    this.clientsInternal,
    this.clientRef,
    this.global,
    this.saveAsDraft,
  });

  factory UploadDocsRequest.fromJson(Map<String, dynamic> json) {
    return UploadDocsRequest(
      projectIds: json['projectIds'] is List
          ? (json['projectIds'] as List).map((e) => e.toString()).toList()
          : [],
      projectSpecific: json['projectSpecific'] is List
          ? (json['projectSpecific'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => FileItem.fromJson(e))
              .toList()
          : null,
      clientsInternal: json['clientsInternal'] is List
          ? (json['clientsInternal'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => FileItem.fromJson(e))
              .toList()
          : null,
      clientRef: json['clientRef'] is List
          ? (json['clientRef'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => FileItem.fromJson(e))
              .toList()
          : null,
      global: json['global'] is List
          ? (json['global'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => FileItem.fromJson(e))
              .toList()
          : null,
      saveAsDraft: json['saveAsDraft'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'projectIds': projectIds,
    };

    if (projectSpecific != null && projectSpecific!.isNotEmpty) {
      data['projectSpecific'] = projectSpecific!.map((e) => e.toJson()).toList();
    }

    if (clientsInternal != null && clientsInternal!.isNotEmpty) {
      data['clientsInternal'] = clientsInternal!.map((e) => e.toJson()).toList();
    }

    if (clientRef != null && clientRef!.isNotEmpty) {
      data['clientRef'] = clientRef!.map((e) => e.toJson()).toList();
    }

    if (global != null && global!.isNotEmpty) {
      data['global'] = global!.map((e) => e.toJson()).toList();
    }

    if (saveAsDraft != null) {
      data['saveAsDraft'] = saveAsDraft;
    }

    return data;
  }

  @override
  List<Object?> get props => [
        projectIds,
        projectSpecific,
        clientsInternal,
        clientRef,
        global,
        saveAsDraft,
      ];
}
