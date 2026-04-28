import 'package:equatable/equatable.dart';
import 'incident_file_upload_response.dart';

/// View Details Response Model
/// Response from POST /api/onboarding/view-details
class ViewDetailsResponse extends Equatable {
  final String? id;
  final String? projectId;
  final DocumentSection? section;
  final String? createdAt;
  final String? updatedAt;

  const ViewDetailsResponse({
    this.id,
    this.projectId,
    this.section,
    this.createdAt,
    this.updatedAt,
  });

  factory ViewDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ViewDetailsResponse(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      projectId: json['projectId']?.toString(),
      section: json['section'] != null
          ? DocumentSection.fromJson(json['section'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'projectId': projectId,
      'section': section?.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [id, projectId, section, createdAt, updatedAt];
}

/// Document Section Model
/// Contains arrays of files for different categories
class DocumentSection extends Equatable {
  final List<DocumentFileItem> projectSpecific;
  final List<DocumentFileItem> clientsInternal;
  final List<DocumentFileItem> clientRef;
  final List<DocumentFileItem> global;

  const DocumentSection({
    this.projectSpecific = const [],
    this.clientsInternal = const [],
    this.clientRef = const [],
    this.global = const [],
  });

  factory DocumentSection.fromJson(Map<String, dynamic> json) {
    return DocumentSection(
      projectSpecific: json['projectSpecific'] is List
          ? (json['projectSpecific'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => DocumentFileItem.fromJson(e))
              .toList()
          : [],
      clientsInternal: json['clientsInternal'] is List
          ? (json['clientsInternal'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => DocumentFileItem.fromJson(e))
              .toList()
          : [],
      clientRef: json['clientRef'] is List
          ? (json['clientRef'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => DocumentFileItem.fromJson(e))
              .toList()
          : [],
      global: json['global'] is List
          ? (json['global'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => DocumentFileItem.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectSpecific': projectSpecific.map((e) => e.toJson()).toList(),
      'clientsInternal': clientsInternal.map((e) => e.toJson()).toList(),
      'clientRef': clientRef.map((e) => e.toJson()).toList(),
      'global': global.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [projectSpecific, clientsInternal, clientRef, global];
}

/// Document File Item Model
/// Represents a file in the document section
class DocumentFileItem extends Equatable {
  final String? fileUrl;
  final String? key;
  final String? fileName;
  final int fileSize;

  const DocumentFileItem({
    this.fileUrl,
    this.key,
    this.fileName,
    this.fileSize = 0,
  });

  factory DocumentFileItem.fromJson(Map<String, dynamic> json) {
    return DocumentFileItem(
      fileUrl: json['fileUrl']?.toString(),
      key: json['key']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : json['fileSize'] is String
              ? int.tryParse(json['fileSize'] as String) ?? 0
              : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      'key': key,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }

  /// Convert to UploadedFileItem format for compatibility
  UploadedFileItem toUploadedFileItem() {
    return UploadedFileItem(
      fileUrl: fileUrl ?? '',
      key: key ?? '',
      fileType: _getFileTypeFromFileName(fileName ?? ''),
      fileSize: fileSize,
      fileName: fileName ?? '',
    );
  }

  String _getFileTypeFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
      return 'video';
    } else if (['mp3', 'wav', 'aac'].contains(extension)) {
      return 'audio';
    }
    return 'document';
  }

  @override
  List<Object?> get props => [fileUrl, key, fileName, fileSize];
}

