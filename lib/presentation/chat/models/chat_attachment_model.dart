/// Chat attachment model
/// ⚠️ MUST match web socket payload EXACTLY
/// Web format:
/// {
///   url: string,
///   type: 'image' | 'video' | 'file',
///   key: string,
///   fileSize: number (double),
///   filename: string
/// }
class ChatAttachment {
  final String url;
  final String type; // image | video | file
  final String key;
  final double fileSize; // MUST be double (web sends decimal)
  final String filename; // MUST be `filename` (not fileName)

  const ChatAttachment({
    required this.url,
    required this.type,
    required this.key,
    required this.fileSize,
    required this.filename,
  });

  /// Create from JSON (socket / API)
  /// Handles both web format (filename) and API format (fileName)
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    // Handle both 'filename' and 'fileName' keys
    final name = json['filename']?.toString() ??
        json['fileName']?.toString() ??
        'Unknown';

    // Handle type mapping: API may use 'images'/'documents', web uses 'image'/'file'
    String typeValue = json['type']?.toString() ?? 'file';
    if (typeValue == 'images') typeValue = 'image';
    if (typeValue == 'videos') typeValue = 'video';
    if (typeValue == 'documents') typeValue = 'file';

    // Handle fileSize: could be int (bytes) or double (MB)
    double fileSizeValue = 0.0;
    if (json['fileSize'] != null) {
      final raw = json['fileSize'];
      if (raw is int) {
        // Bytes -> convert to MB
        fileSizeValue = raw / (1024 * 1024);
      } else if (raw is double) {
        fileSizeValue = raw;
      } else {
        fileSizeValue = double.tryParse(raw.toString()) ?? 0.0;
      }
    }

    return ChatAttachment(
      url: json['url']?.toString() ?? '',
      type: typeValue,
      key: json['key']?.toString() ?? '',
      fileSize: fileSizeValue,
      filename: name,
    );
  }

  /// Create from MessageAttachment (data layer model)
  factory ChatAttachment.fromMessageAttachment(dynamic attachment) {
    if (attachment == null) {
      return const ChatAttachment(
        url: '',
        type: 'file',
        key: '',
        fileSize: 0.0,
        filename: 'Unknown',
      );
    }

    // Handle type mapping: API uses 'images'/'documents', we use 'image'/'file'
    String typeValue = attachment.type?.toString() ?? 'file';
    if (typeValue == 'images') typeValue = 'image';
    if (typeValue == 'videos') typeValue = 'video';
    if (typeValue == 'documents') typeValue = 'file';

    // Convert fileSize from bytes (int) to MB (double)
    double fileSizeValue = 0.0;
    if (attachment.fileSize != null) {
      fileSizeValue = (attachment.fileSize as int) / (1024 * 1024);
    }

    return ChatAttachment(
      url: attachment.url?.toString() ?? '',
      type: typeValue,
      key: attachment.key?.toString() ?? '',
      fileSize: fileSizeValue,
      filename: attachment.fileName?.toString() ?? 'Unknown',
    );
  }

  /// Convert to JSON for socket emit
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'key': key,
      'fileSize': fileSize,
      'filename': filename,
    };
  }

  // ===== Helpers for UI =====

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isFile => type == 'file';

  /// File size formatted for display
  /// Web sends fileSize in MB (e.g., 0.035 = 35KB)
  String get formattedFileSize {
    if (fileSize <= 0) return '';
    final mb = fileSize;
    if (mb < 0.001) {
      // Less than 1KB, show bytes
      return '${(mb * 1024 * 1024).toStringAsFixed(0)} B';
    } else if (mb < 1) {
      // Less than 1MB, show KB
      return '${(mb * 1024).toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get fileExtension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Determine attachment type from file extension
  static String getTypeFromExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].contains(ext)) {
      return 'image';
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext)) {
      return 'video';
    }
    return 'file';
  }

  ChatAttachment copyWith({
    String? url,
    String? type,
    String? key,
    double? fileSize,
    String? filename,
  }) {
    return ChatAttachment(
      url: url ?? this.url,
      type: type ?? this.type,
      key: key ?? this.key,
      fileSize: fileSize ?? this.fileSize,
      filename: filename ?? this.filename,
    );
  }
}
