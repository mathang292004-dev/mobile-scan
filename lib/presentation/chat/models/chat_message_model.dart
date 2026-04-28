import 'chat_attachment_model.dart';

/// Model class representing a chat message in the incident chat
class ChatMessage {
  /// Unique identifier for the message
  final String id;

  /// ID of the sender
  final String senderId;

  /// Name of the sender
  final String senderName;

  /// Avatar/profile image URL or path
  final String senderAvatar;

  /// The actual message text content
  final String message;

  /// Timestamp when the message was sent
  final DateTime timestamp;

  /// Whether the message is sent by the current user
  final bool isMe;

  /// Online status of the sender
  final bool isOnline;

  /// List of attachments (images, videos, documents)
  final List<ChatAttachment> attachments;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.message,
    required this.timestamp,
    required this.isMe,
    this.isOnline = false,
    this.attachments = const [],
  });

  /// Factory constructor to create a ChatMessage from JSON
  /// Handles both 'attachment' (singular, web socket format) and 'attachments' (plural)
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<ChatAttachment> attachmentsList = [];
    // Check for 'attachment' (singular - web socket format) first
    if (json['attachment'] is List) {
      attachmentsList = (json['attachment'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ChatAttachment.fromJson(e))
          .toList();
    } else if (json['attachments'] is List) {
      // Fallback to 'attachments' (plural) for backward compatibility
      attachmentsList = (json['attachments'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ChatAttachment.fromJson(e))
          .toList();
    }

    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMe: json['isMe'] as bool,
      isOnline: json['isOnline'] as bool? ?? false,
      attachments: attachmentsList,
    );
  }

  /// Convert ChatMessage to JSON
  /// Uses 'attachment' (singular) to match web socket format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isMe': isMe,
      'isOnline': isOnline,
      if (attachments.isNotEmpty)
        'attachment': attachments.map((e) => e.toJson()).toList(),
    };
  }

  /// Create a copy of ChatMessage with optional field updates
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? message,
    DateTime? timestamp,
    bool? isMe,
    bool? isOnline,
    List<ChatAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      isOnline: isOnline ?? this.isOnline,
      attachments: attachments ?? this.attachments,
    );
  }

  /// Check if message has any attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if message has only attachments (no text)
  bool get isAttachmentOnly => message.trim().isEmpty && hasAttachments;

  /// Get only image attachments
  List<ChatAttachment> get imageAttachments =>
      attachments.where((a) => a.isImage).toList();

  /// Get only file attachments (documents)
  List<ChatAttachment> get fileAttachments =>
      attachments.where((a) => a.isFile).toList();

  /// Get only video attachments
  List<ChatAttachment> get videoAttachments =>
      attachments.where((a) => a.isVideo).toList();
}
