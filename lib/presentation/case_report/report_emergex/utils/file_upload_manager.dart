import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:flutter/material.dart';

class FileUploadManager extends ChangeNotifier {
  final List<FileUploadItem> _uploadItems = [];
  static FileUploadManager? _instance;

  static FileUploadManager? get instance => _instance;

  final List<String> supportedExtensions = [
    TextHelper.jpg,
    TextHelper.jpeg,
    TextHelper.png,
    TextHelper.mp4,
    TextHelper.svg,
    TextHelper.zip,
    TextHelper.pdf,
    TextHelper.doc,
    TextHelper.docx,
  ];

  List<FileUploadItem> get uploadItems => List.unmodifiable(_uploadItems);
  bool get hasUploads => _uploadItems.isNotEmpty;
  static String getFileIconData(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'jpg':
        return Assets.jpgImage;
      case 'png':
        return Assets.png;
      case 'mp4':
        return Assets.mp4;
      case 'pdf':
        return Assets.pdf;
      case 'zip':
        return Assets.zip;
      default:
        return Assets.defaultPic;
    }
  }
}
