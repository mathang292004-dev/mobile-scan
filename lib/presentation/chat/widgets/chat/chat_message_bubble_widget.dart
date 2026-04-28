import 'package:flutter/material.dart';
import '../../models/chat_message_model.dart';
import 'chat_image_attachment_widget.dart';
import 'chat_document_attachment_widget.dart';

/// A chat message bubble widget
/// Shows differently based on whether it's sent by current user or others
/// Supports text messages, image attachments, and document attachments
class ChatMessageBubble extends StatefulWidget {
  /// The message data to display
  final ChatMessage message;
  final String Function(String userId)? resolveUserName;

  /// Callback when avatar is tapped, provides avatar's global position and size
  final void Function(Rect avatarRect)? onAvatarTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onAvatarTap,
    this.resolveUserName,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  final GlobalKey _avatarKey = GlobalKey();

  void _handleAvatarTap() {
    final RenderBox? renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && widget.onAvatarTap != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      widget.onAvatarTap!(rect);
    }
  }

  String _formatTime(DateTime time) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${months[time.month - 1]} ${time.day}, ${time.year} ${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  /// Build message content including attachments and text
  Widget _buildMessageContent(BuildContext context) {
    final hasText = widget.message.message.trim().isNotEmpty;
    final hasAttachments = widget.message.hasAttachments;

    // If no attachments, just show text bubble
    if (!hasAttachments) {
      return _buildTextBubble(context);
    }

    // Build list of content widgets
    final List<Widget> contentWidgets = [];

    // Add image attachments
    for (final attachment in widget.message.imageAttachments) {
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ChatImageAttachmentWidget(
            attachment: attachment,
            isMe: widget.message.isMe,
          ),
        ),
      );
    }

    // Add file attachments (documents, PDFs, etc.)
    for (final attachment in widget.message.fileAttachments) {
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ChatDocumentAttachmentWidget(
            attachment: attachment,
            isMe: widget.message.isMe,
          ),
        ),
      );
    }

    // Add video attachments (show as documents for now)
    for (final attachment in widget.message.videoAttachments) {
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ChatDocumentAttachmentWidget(
            attachment: attachment,
            isMe: widget.message.isMe,
          ),
        ),
      );
    }

    // Add text bubble if there's text
    if (hasText) {
      contentWidgets.add(_buildTextBubble(context));
    }

    return Column(
      crossAxisAlignment: widget.message.isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: contentWidgets,
    );
  }

  /// Build the text message bubble
  Widget _buildTextBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: widget.message.isMe ? const Color(0xFF3DA229) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        widget.message.message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: widget.message.isMe ? Colors.white : Colors.black,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      key: _avatarKey,
      width: 32,
      height: 32,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          widget.message.senderAvatar,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.grey[600],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.message.isMe
        ? 'You'
        : (widget.resolveUserName?.call(widget.message.senderId) ?? 'Unknown');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: widget.message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar for received messages (left side)
          if (!widget.message.isMe) ...[
            GestureDetector(
              onTap: _handleAvatarTap,
              child: _buildAvatar(),
            ),
            const SizedBox(width: 12),
          ],
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: widget.message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Header with name and time
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: widget.message.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!widget.message.isMe) ...[
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF242424),
                                height: 1.5,
                              ),
                        ),

                        const Spacer(),
                      ],
                      if (widget.message.isMe) ...[const Spacer()],
                      Text(
                        _formatTime(widget.message.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6E6E6E),
                          height: 1.5,
                        ),
                      ),
                      if (widget.message.isMe) ...[
                        const SizedBox(width: 8),
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF242424),
                                height: 1.5,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Message content (attachments + text)
                _buildMessageContent(context),
              ],
            ),
          ),
          // Avatar for sent messages (right side)
          if (widget.message.isMe) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleAvatarTap,
              child: _buildAvatar(),
            ),
          ],
        ],
      ),
    );
  }
}
