import 'dart:io';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/remote_data_source/upload_doc_remote_data_source.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/chat/cubit/chat_cubit/chat_room_cubit.dart';
import 'package:emergex/presentation/chat/models/chat_attachment_model.dart';
import 'package:emergex/presentation/chat/models/chat_member_model.dart';
import 'package:emergex/presentation/chat/models/chat_message_model.dart';
import 'package:emergex/services/socket_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class MiniChatState extends Equatable {
  final List<ChatMessage> messages;
  final ProcessState processState;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;
  final Map<String, String> userNameCache;

  const MiniChatState({
    this.messages = const [],
    this.processState = ProcessState.none,
    this.isLoading = true,
    this.isUploading = false,
    this.errorMessage,
    this.userNameCache = const {},
  });

  factory MiniChatState.initial() =>
      const MiniChatState(processState: ProcessState.none);

  MiniChatState copyWith({
    List<ChatMessage>? messages,
    ProcessState? processState,
    bool? isLoading,
    bool? isUploading,
    String? errorMessage,
    Map<String, String>? userNameCache,
    bool clearError = false,
  }) {
    return MiniChatState(
      messages: messages ?? this.messages,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userNameCache: userNameCache ?? this.userNameCache,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        processState,
        isLoading,
        isUploading,
        errorMessage,
        userNameCache,
      ];
}

class MiniChatCubit extends Cubit<MiniChatState> {
  final SocketService _socketService;
  final ChatRoomCubit _chatRoomCubit;

  String? _chatGroupId;
  String? _currentUserId;
  String? _currentUserName;
  List<ChatMember> _participants = [];

  MiniChatCubit({
    SocketService? socketService,
    ChatRoomCubit? chatRoomCubit,
  })  : _socketService = socketService ?? getIt<SocketService>(),
        _chatRoomCubit = chatRoomCubit ?? getIt<ChatRoomCubit>(),
        super(MiniChatState.initial());

  /// Initialize the cubit with required parameters
  void initialize({
    required String chatGroupId,
    required String? currentUserId,
    required String? currentUserName,
    required List<ChatMember> participants,
  }) {
    _chatGroupId = chatGroupId;
    _currentUserId = currentUserId;
    _currentUserName = currentUserName;
    _participants = participants;

    _initUserNameCache();
    _setupSocketListeners();
    _loadMessages();
  }

  /// Initialize user name cache from participants
  void _initUserNameCache() {
    final cache = Map<String, String>.from(state.userNameCache);
    for (final participant in _participants) {
      if (participant.id.isNotEmpty && participant.name.isNotEmpty) {
        cache[participant.id] = participant.name;
      }
    }
    emit(state.copyWith(userNameCache: cache));
  }

  /// Get user name from cache or participants list
  String _getUserName(String userId) {
    if (userId.isEmpty) return 'Unknown';

    // Check cache first
    if (state.userNameCache.containsKey(userId)) {
      return state.userNameCache[userId]!;
    }

    // Try to find in participants
    try {
      final member = _participants.firstWhere((m) => m.id == userId);
      _updateUserNameCache(userId, member.name);
      return member.name;
    } catch (e) {
      return 'User';
    }
  }

  /// Update user name cache
  void _updateUserNameCache(String userId, String name) {
    final cache = Map<String, String>.from(state.userNameCache);
    cache[userId] = name;
    emit(state.copyWith(userNameCache: cache));
  }

  /// Setup socket listeners for new messages
  void _setupSocketListeners() {
    _socketService.onNewMessage = (data) {
      _handleNewMessage(data);
    };
  }

  /// Handle incoming socket message
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final groupId = data['groupId'] as String?;
      if (groupId != _chatGroupId) return;

      final senderId = data['senderId'] as String? ?? '';
      final socketSenderName = data['senderName'] as String?;
      final senderAvatar = data['senderAvatar'] as String? ?? '';
      final messageText = data['message'] as String? ?? '';
      final messageId =
          data['_id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
          : DateTime.now();

      // Cache the sender name from socket message
      if (socketSenderName != null && socketSenderName.isNotEmpty) {
        _updateUserNameCache(senderId, socketSenderName);
      }

      final isMe = senderId == _currentUserId;
      final senderName = isMe
          ? 'You'
          : (socketSenderName ?? _getUserName(senderId));

      // Parse attachments if present
      List<ChatAttachment> attachments = [];
      if (data['attachment'] is List) {
        attachments = (data['attachment'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => ChatAttachment.fromJson(e))
            .toList();
      }

      // Check for duplicates
      final isDuplicate = state.messages.any((m) => m.id == messageId);
      if (isDuplicate) return;

      final newMessage = ChatMessage(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        message: messageText,
        timestamp: timestamp,
        isMe: isMe,
        isOnline: true,
        attachments: attachments,
      );

      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(newMessage)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      debugPrint('Error handling new message in mini chat: $e');
    }
  }

  /// Load messages from API
  void _loadMessages() {
    if (_chatGroupId == null) return;
    _chatRoomCubit.getChatMessages(groupId: _chatGroupId!);
  }

  /// Process messages loaded from ChatRoomCubit
  void processLoadedMessages(ChatRoomState chatRoomState) {
    if (chatRoomState.processState == ProcessState.done &&
        chatRoomState.messages.isNotEmpty) {
      final List<ChatMessage> loadedMessages = [];

      for (final apiMsg in chatRoomState.messages) {
        final senderId = apiMsg.sender ?? '';
        final isMe = senderId == _currentUserId;
        final isDuplicate = state.messages.any((m) => m.id == apiMsg.id);

        if (!isDuplicate) {
          // Convert MessageAttachment to ChatAttachment
          final attachments = (apiMsg.attachments ?? [])
              .map((att) => ChatAttachment.fromMessageAttachment(att))
              .toList();

          // Get name from cache or participants
          final senderName = isMe ? 'You' : _getUserName(senderId);

          loadedMessages.add(
            ChatMessage(
              id: apiMsg.id ?? '',
              senderId: senderId,
              senderName: senderName,
              senderAvatar: '',
              message: apiMsg.message ?? '',
              timestamp: apiMsg.messageTime != null
                  ? DateTime.fromMillisecondsSinceEpoch(apiMsg.messageTime!)
                  : DateTime.now(),
              isMe: isMe,
              isOnline: true,
              attachments: attachments,
            ),
          );
        }
      }

      final allMessages = List<ChatMessage>.from(state.messages)
        ..addAll(loadedMessages)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      emit(state.copyWith(
        messages: allMessages,
        isLoading: false,
        processState: ProcessState.done,
      ));
    } else if (chatRoomState.processState == ProcessState.done &&
        chatRoomState.messages.isEmpty) {
      emit(state.copyWith(
        isLoading: false,
        processState: ProcessState.done,
      ));
    } else if (chatRoomState.processState == ProcessState.error) {
      emit(state.copyWith(
        isLoading: false,
        processState: ProcessState.error,
        errorMessage: chatRoomState.errorMessage,
      ));
    }
  }

  /// Send a text message
  void sendMessage(String message) {
    if (message.trim().isEmpty) return;
    if (_chatGroupId == null) return;

    if (!_socketService.isConnected) {
      emit(state.copyWith(
        errorMessage: 'Connection lost. Please wait...',
      ));
      return;
    }

    final currentUserName = _currentUserName ?? 'User';

    _socketService.sendMessage(
      groupId: _chatGroupId!,
      message: message.trim(),
      senderName: currentUserName,
    );
  }

  /// Pick and send a document file
  Future<void> pickAndSendDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'zip',
          'rar',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _uploadAndSendAttachment(File(file.path!), file.name);
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      emit(state.copyWith(errorMessage: 'Failed to pick document: $e'));
    }
  }

  /// Pick and send an image
  Future<void> pickAndSendImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _uploadAndSendAttachment(File(file.path!), file.name);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      emit(state.copyWith(errorMessage: 'Failed to pick image: $e'));
    }
  }

  /// Upload file to server and send as attachment
  Future<void> _uploadAndSendAttachment(File file, String fileName) async {
    if (_chatGroupId == null) return;

    if (!_socketService.isConnected) {
      emit(state.copyWith(errorMessage: 'Connection lost. Please wait...'));
      return;
    }

    emit(state.copyWith(isUploading: true));

    try {
      final uploadDataSource =
          getIt<OnboardingOrganizationStructureRemoteDataSource>();
      final response = await uploadDataSource.uploadOrganizationStructureFiles([
        file,
      ]);

      if (response.success == true &&
          response.data != null &&
          response.data!.files.isNotEmpty) {
        final uploadedFile = response.data!.files.first;
        final actualFileName = uploadedFile.fileName.isNotEmpty
            ? uploadedFile.fileName
            : fileName;

        // Determine attachment type
        String attachmentType = 'documents';
        final lowerName = actualFileName.toLowerCase();
        if (lowerName.endsWith('.jpg') ||
            lowerName.endsWith('.jpeg') ||
            lowerName.endsWith('.png') ||
            lowerName.endsWith('.gif') ||
            lowerName.endsWith('.webp')) {
          attachmentType = 'images';
        } else if (lowerName.endsWith('.mp4') ||
            lowerName.endsWith('.mov') ||
            lowerName.endsWith('.avi')) {
          attachmentType = 'videos';
        }

        // Send message with attachment via socket
        _socketService.sendMessage(
          groupId: _chatGroupId!,
          message: '',
          senderName: _currentUserName ?? 'User',
          attachment: [
            {
              'url': uploadedFile.fileUrl,
              'type': attachmentType,
              'key': uploadedFile.key,
              'fileSize': uploadedFile.fileSize,
              'fileName': actualFileName,
            },
          ],
        );

        emit(state.copyWith(isUploading: false));
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      emit(state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to upload: $e',
      ));
    }
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null, clearError: true));
  }

  /// Clear cache and reset to initial state
  void clearCache() {
    emit(MiniChatState.initial());
  }

  /// Check if socket is connected
  bool get isConnected => _socketService.isConnected;

  /// Get chat room cubit for listening
  ChatRoomCubit get chatRoomCubit => _chatRoomCubit;

  /// Get current chat group ID
  String? get chatGroupId => _chatGroupId;

  /// Get current user ID
  String? get currentUserId => _currentUserId;
}
