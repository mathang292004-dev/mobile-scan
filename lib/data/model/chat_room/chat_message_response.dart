class ChatMessageResponse {
  final int? statusCode;
  final String? message;
  final String? status;
  final List<ChatMessage>? data;

  ChatMessageResponse({
    this.statusCode,
    this.message,
    this.status,
    this.data,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      status: json['status'] as String?,
      data: json['data'] is List
          ? (json['data'] as List)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'status': status,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class ChatMessage {
  final String? id;
  final String? sender;
  final String? chatGroup;
  final String? message;
  final int? messageTime;
  final String? replyToMessage;
  final List<MessageAttachment>? attachments;

  ChatMessage({
    this.id,
    this.sender,
    this.chatGroup,
    this.message,
    this.messageTime,
    this.replyToMessage,
    this.attachments,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      sender: json['sender'] as String?,
      chatGroup: json['chatGroup'] as String?,
      message: json['message'] as String?,
      messageTime: json['messageTime'] is int
          ? json['messageTime'] as int
          : (json['messageTime'] != null
              ? int.tryParse(json['messageTime'].toString())
              : null),
      replyToMessage: json['replyToMessage'] as String?,
      attachments: json['attachments'] is List
          ? (json['attachments'] as List)
              .map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'chatGroup': chatGroup,
      'message': message,
      'messageTime': messageTime,
      'replyToMessage': replyToMessage,
      'attachments': attachments?.map((e) => e.toJson()).toList(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? chatGroup,
    String? message,
    int? messageTime,
    String? replyToMessage,
    List<MessageAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      chatGroup: chatGroup ?? this.chatGroup,
      message: message ?? this.message,
      messageTime: messageTime ?? this.messageTime,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// Attachment model matching the web app format exactly
/// Web format: { url, type: 'images'|'videos'|'documents', key, fileSize, fileName }
class MessageAttachment {
  final String? url;
  final String? type;
  final String? key;
  final int? fileSize;
  final String? fileName;

  MessageAttachment({
    this.url,
    this.type,
    this.key,
    this.fileSize,
    this.fileName,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      url: json['url'] as String?,
      type: json['type'] as String?,
      key: json['key'] as String?,
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : (json['fileSize'] != null
              ? int.tryParse(json['fileSize'].toString())
              : null),
      fileName: json['fileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'key': key,
      'fileSize': fileSize,
      'fileName': fileName,
    };
  }

  MessageAttachment copyWith({
    String? url,
    String? type,
    String? key,
    int? fileSize,
    String? fileName,
  }) {
    return MessageAttachment(
      url: url ?? this.url,
      type: type ?? this.type,
      key: key ?? this.key,
      fileSize: fileSize ?? this.fileSize,
      fileName: fileName ?? this.fileName,
    );
  }

  /// Check if this is an image attachment
  bool get isImage => type == 'images';

  /// Check if this is a video attachment
  bool get isVideo => type == 'videos';

  /// Check if this is a document attachment
  bool get isDocument => type == 'documents';

  /// Get formatted file size (e.g., "1.5 MB")
  String get formattedFileSize {
    if (fileSize == null) return '';
    final bytes = fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
