import 'package:flutter/material.dart';
import 'package:emergex/presentation/chat/models/chat_message_model.dart';
import 'package:emergex/presentation/chat/models/chat_attachment_model.dart';
import 'package:emergex/presentation/chat/models/chat_member_model.dart';
import 'package:emergex/presentation/chat/cubit/chat_cubit/chat_room_cubit.dart';
import 'package:emergex/presentation/chat/cubit/mini_chat_cubit/mini_chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mini chat bottom sheet for audio/video call screens
/// Shows live chat messages with input field
class MiniChatBottomSheet extends StatefulWidget {
  final String chatGroupId;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserAvatar;
  final VoidCallback onClose;
  final bool isExpanded;
  final List<ChatMember> participants;

  const MiniChatBottomSheet({
    super.key,
    required this.chatGroupId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.onClose,
    this.isExpanded = true,
    this.participants = const [],
  });

  @override
  State<MiniChatBottomSheet> createState() => _MiniChatBottomSheetState();
}

class _MiniChatBottomSheetState extends State<MiniChatBottomSheet> {
  late MiniChatCubit _miniChatCubit;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _miniChatCubit = MiniChatCubit();
    _miniChatCubit.initialize(
      chatGroupId: widget.chatGroupId,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      participants: widget.participants,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    if (!_miniChatCubit.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost. Please wait...')),
      );
      return;
    }

    _miniChatCubit.sendMessage(_messageController.text);
    _messageController.clear();
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _miniChatCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _miniChatCubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<ChatRoomCubit, ChatRoomState>(
            bloc: _miniChatCubit.chatRoomCubit,
            listener: (context, state) {
              _miniChatCubit.processLoadedMessages(state);
              if (state.messages.isNotEmpty) {
                _scrollToBottom();
              }
            },
          ),
          BlocListener<MiniChatCubit, MiniChatState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
                _miniChatCubit.clearError();
              }
            },
          ),
        ],
        child: BlocBuilder<MiniChatCubit, MiniChatState>(
          builder: (context, state) {
            return SizedBox.expand(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Header
                    _buildHeader(),
                    // Chat content
                    if (widget.isExpanded) ...[
                      Expanded(
                        child: state.isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF3DA229),
                                    ),
                                  ),
                                ),
                              )
                            : _buildMessageList(state.messages),
                      ),
                      // Input field
                      _buildInputField(state.isUploading),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF3DA229),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            Transform.rotate(
              angle: widget.isExpanded ? 0 : 3.14159,
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No messages yet',
            style: TextStyle(
              color: Color(0xFF6E6E6E),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      );
    }

    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isMe = message.isMe;
    final displayName = isMe ? 'You' : message.senderName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar for received messages (left side)
          if (!isMe) ...[
            _buildAvatar(message.senderAvatar),
            const SizedBox(width: 12),
          ],
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Header with name and time
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe) ...[
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF242424),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isMe) ...[
                        Text(
                          _formatTime(message.timestamp),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6E6E6E),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF242424),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ] else ...[
                        Text(
                          _formatTime(message.timestamp),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6E6E6E),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Attachments
                if (message.hasAttachments) ...[
                  for (final attachment in message.attachments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildAttachment(attachment, isMe),
                    ),
                ],
                // Message bubble (only if there's text)
                if (message.message.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.55,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF3DA229)
                          : const Color(0xFFECECEC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: isMe ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Avatar for sent messages (right side)
          if (isMe) ...[
            const SizedBox(width: 12),
            _buildAvatar(widget.currentUserAvatar ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachment(ChatAttachment attachment, bool isMe) {
    if (attachment.isImage) {
      return _buildImageAttachment(attachment, isMe);
    } else {
      return _buildDocumentAttachment(attachment, isMe);
    }
  }

  Widget _buildImageAttachment(ChatAttachment attachment, bool isMe) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
          maxHeight: 150,
        ),
        child: Image.network(
          attachment.url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 100,
              height: 100,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3DA229)),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentAttachment(ChatAttachment attachment, bool isMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.55,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF3DA229) : const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF3DA229).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileIcon(attachment.filename),
              size: 16,
              color: isMe ? Colors.white : const Color(0xFF3DA229),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.filename,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isMe ? Colors.white : Colors.black,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.fileSize > 0)
                  Text(
                    '${attachment.fileSize.toStringAsFixed(2)} MB',
                    style: TextStyle(
                      fontSize: 8,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description;
    }
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return Icons.table_chart;
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return Icons.slideshow;
    }
    if (lower.endsWith('.zip') || lower.endsWith('.rar')) {
      return Icons.folder_zip;
    }
    return Icons.insert_drive_file;
  }

  Widget _buildAvatar(String avatarUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.67),
      child: avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar();
              },
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6.67),
      ),
      child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
    );
  }

  Widget _buildInputField(bool isUploading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromRGBO(61, 162, 41, 0.15),
            width: 4,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  color: Color(0xFF3D3D3D),
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Poppins',
                    color: Color(0xFF3D3D3D),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            // Attachment button
            GestureDetector(
              onTap: isUploading ? null : _miniChatCubit.pickAndSendDocument,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DA229).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_file,
                  size: 10,
                  color: isUploading ? Colors.grey : const Color(0xFF3DA229),
                ),
              ),
            ),
            // Image button
            GestureDetector(
              onTap: isUploading ? null : _miniChatCubit.pickAndSendImage,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DA229).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image,
                  size: 10,
                  color: isUploading ? Colors.grey : const Color(0xFF3DA229),
                ),
              ),
            ),
            // Send button
            GestureDetector(
              onTap: isUploading ? null : _sendMessage,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF3DA229),
                  shape: BoxShape.circle,
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
