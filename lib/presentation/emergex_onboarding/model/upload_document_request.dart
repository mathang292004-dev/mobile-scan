import 'dart:convert';
import 'dart:io';

/// Model for upload document request with nested section structure
class UploadDocumentRequest {
  final String projectId;
  final Map<String, List<File>> section;

  UploadDocumentRequest({
    required this.projectId,
    required this.section,
  });

  /// Convert section to JSON string for API
  /// Returns JSON with category keys and file names only (not full paths)
  String get sectionJson {
    final Map<String, dynamic> sectionMap = {};
    section.forEach((categoryKey, fileList) {
      sectionMap[categoryKey] = fileList.map((file) => file.path.split('/').last).toList();
    });
    return jsonEncode(sectionMap);
  }

  /// Get all files from all categories
  List<File> get allFiles {
    final List<File> files = [];
    section.forEach((categoryKey, fileList) {
      files.addAll(fileList);
    });
    return files;
  }
}

