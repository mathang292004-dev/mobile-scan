import 'dart:io';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/presentation/chat/cubit/chat_cubit/chat_room_cubit.dart';
import 'package:emergex/services/socket_service.dart';
import 'package:emergex/services/call_state_manager.dart';
import 'package:emergex/data/remote_data_source/login_remote_data_source.dart';
import 'package:emergex/data/remote_data_source/upload_doc_remote_data_source.dart';
import 'package:emergex/base/cubit/emergex_app_cubit.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/call_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../models/chat_member_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_attachment_model.dart';
import 'package:emergex/data/model/chat_room/incident_user_response.dart'
    as api;
import '../widgets/chat/add_members_modal_widget.dart';
import '../widgets/chat/chat_header_widget.dart';
import '../widgets/chat/chat_input_bar_widget.dart';
import '../widgets/chat/chat_message_bubble_widget.dart';
import '../widgets/chat/user_profile_card_widget.dart';
import '../widgets/chat/typing_indicator_widget.dart';
import 'package:emergex/generated/assets.dart';

/// Main chat screen for incident communication
/// Displays messages, allows adding members, and shows user profiles
class ChatScreen extends StatefulWidget {
  final String incidentId;

  const ChatScreen({super.key, required this.incidentId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State for messages and members
  List<ChatMessage> _messages = [];
  List<ChatMember> _teamMembers = [];
  List<ChatMember> _inviteMembers = [];
  final Map<String, bool> _memberIsActiveMap = {};

  // State for UI
  ChatMember? _selectedMember;
  Rect? _avatarRect;
  final GlobalKey _stackKey = GlobalKey();

  String? _chatGroupId;
  int _membersCount = 0;
  int _onlineCount = 0;
  bool _isLoadingMessages = false;
  bool _isLoadingOlderMessages = false;
  bool _isLoadingNewerMessages = false;
  List<api.IncidentUser> _incidentUsers = [];
  bool _shouldShowMembersModal = false;

  late SocketService _socketService;
  late EmergexAppCubit _appCubit;
  String? _currentUserId;

  /// Map of userId -> userName for users currently typing
  final Map<String, String> _typingUsers = {};

  /// Map of userId -> Timer for auto-clearing typing status
  final Map<String, Timer> _typingTimers = {};

  /// Last time we sent a typing event (for throttling)
  int _lastTypingSentTime = 0;

  /// Timer to auto-send stop typing after inactivity
  Timer? _typingStopTimer;

  /// Active call state
  String? _activeCallId;
  String? _activeCallRoomId;
  CallType? _activeCallType;
  bool _hasActiveCall = false;

  @override
  void initState() {
    super.initState();
    _socketService = getIt<SocketService>();
    _appCubit = getIt<EmergexAppCubit>();
    _initializeSocket();
    _createChatGroup();
    _setupScrollListener();
  }

  Future<void> _initializeSocket() async {
    try {
      final loginDataSource = getIt<LoginRemoteDataSource>();
      final userResponse = await loginDataSource.getUserPermissions();

      if (userResponse.success == true && userResponse.data != null) {
        _currentUserId = userResponse.data!.id;

        if (_currentUserId != null) {
          _socketService.connect(_currentUserId!);
          _setupSocketListeners();
        }
      }
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  void _setupSocketListeners() {
    _socketService.onConnect = () {
      debugPrint('Socket connected');
      if (_chatGroupId != null) {
        debugPrint('Joining group after socket connection: $_chatGroupId');
        _socketService.joinGroup(_chatGroupId!);
        // Check for active call after joining group (matches web implementation)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_chatGroupId != null) {
            _socketService.checkForActiveCall(_chatGroupId!);
          }
        });
      }
    };

    _socketService.onDisconnect = () {
      debugPrint('Socket disconnected');
    };

    _socketService.onOnlineUsersCount = (count) {
      if (_teamMembers.isEmpty) return;

      final currentUserId =
          _currentUserId ?? _appCubit.state.userPermissions?.id;

      final onlineInThisGroup = _teamMembers
          .where((m) => m.isOnline)
          //.where((m) => m.id != currentUserId) // 🚫 remove self
          .length;

      setState(() {
        _onlineCount = onlineInThisGroup;
      });
    };

    _socketService.onNewMessage = (data) {
      debugPrint('Received newMessage event: $data');

      // Support both 'userId' and 'senderId' keys from backend
      final senderId = (data['senderId'] ?? data['userId']) as String?;
      final message = (data['message'] as String?) ?? '';
      final timestamp = data['timestamp'] as int?;
      final socketSenderName = data['senderName'] as String?;
      final currentUserId =
          _currentUserId ?? _appCubit.state.userPermissions?.id;

      // Parse attachment (singular - web socket format) from message data
      List<ChatAttachment> attachmentList = [];
      if (data['attachment'] is List) {
        attachmentList = (data['attachment'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => ChatAttachment.fromJson(e))
            .toList();
      }

      debugPrint(
        'Processing message - senderId: $senderId, currentUserId: $currentUserId, message: $message, attachment: ${attachmentList.length}',
      );

      // Message is valid if it has text OR attachment
      final hasContent = message.isNotEmpty || attachmentList.isNotEmpty;

      if (senderId != null && hasContent) {
        final isCurrentUser =
            currentUserId != null && senderId == currentUserId;

        // Check for duplicate messages in the existing list
        final isDuplicate = _messages.any(
          (msg) =>
              msg.senderId == senderId &&
              msg.message == message &&
              (timestamp == null ||
                  (msg.timestamp.millisecondsSinceEpoch ~/ 1000) ==
                      (timestamp ~/ 1000)),
        );

        if (isDuplicate) {
          debugPrint('Duplicate message detected in list, skipping');
          return;
        }

        // Get sender name: prioritize finding the real name
        final senderName = isCurrentUser
            ? 'You'
            : (socketSenderName != null &&
                      socketSenderName.isNotEmpty &&
                      socketSenderName != senderId
                  ? socketSenderName
                  : _getUserName(senderId));

        final messageId =
            '${senderId}_${timestamp ?? DateTime.now().millisecondsSinceEpoch}';

        setState(() {
          _messages.add(
            ChatMessage(
              id: messageId,
              senderId: senderId,
              senderName: senderName,
              senderAvatar: '',
              message: message,
              timestamp: timestamp != null
                  ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                  : DateTime.now(),
              isMe: isCurrentUser,
              isOnline: false,
              attachments: attachmentList,
            ),
          );

          // Sort messages by timestamp to maintain order
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });

        debugPrint(
          'Message added to list. Total messages: ${_messages.length}',
        );

        // Auto-scroll to bottom after receiving message
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      } else {
        debugPrint(
          'Invalid message data - senderId: $senderId, message: $message',
        );
      }
    };

    _socketService.onTyping = (data) {
      debugPrint('⌨️ ChatScreen onTyping received: $data');

      // Support both 'userId' and 'senderId' keys from backend
      final userId = (data['senderId'] ?? data['userId']) as String?;
      final isTyping = data['isTyping'] as bool? ?? true;

      debugPrint(
        '⌨️ Parsed - userId: $userId, currentUserId: $_currentUserId, isTyping: $isTyping',
      );

      if (userId != null && userId != _currentUserId) {
        // Get sender name: fallback to team members lookup if socket data doesn't have a good name
        final socketSenderName = data['senderName'] as String?;
        final senderName =
            (socketSenderName != null &&
                socketSenderName.isNotEmpty &&
                socketSenderName != userId)
            ? socketSenderName
            : _getUserName(userId);
        debugPrint('⌨️ User $senderName ($userId) isTyping: $isTyping');

        if (isTyping) {
          // Cancel existing timer for this user
          _typingTimers[userId]?.cancel();

          setState(() {
            _typingUsers[userId] = senderName;
          });
          debugPrint('⌨️ Updated _typingUsers: $_typingUsers');

          // Auto-clear after 3 seconds of no typing updates
          _typingTimers[userId] = Timer(const Duration(seconds: 3), () {
            setState(() {
              _typingUsers.remove(userId);
            });
            _typingTimers.remove(userId);
            debugPrint('⌨️ Cleared typing for $userId after timeout');
          });
        } else {
          // User stopped typing
          _typingTimers[userId]?.cancel();
          _typingTimers.remove(userId);
          setState(() {
            _typingUsers.remove(userId);
          });
          debugPrint('⌨️ User $userId stopped typing');
        }
      } else {
        debugPrint(
          '⌨️ Ignoring typing event - userId: $userId, currentUserId: $_currentUserId',
        );
      }
    };

    // Incoming call listener
    _socketService.onIncomingCall = (data) {
      debugPrint('📞 INCOMING CALL RECEIVED: $data');

      try {
        final incomingCall = IncomingCallData.fromJson(data);

        // Set active call state
        if (incomingCall.roomId == _chatGroupId) {
          setState(() {
            _hasActiveCall = true;
            _activeCallId = incomingCall.callId;
            _activeCallRoomId = incomingCall.roomId;
            _activeCallType = incomingCall.callType;
          });
        }

        _showIncomingCallDialog(incomingCall);
      } catch (e) {
        debugPrint('❌ Error parsing incoming call data: $e');
      }
    };

    // Call ended listener (matches web implementation)
    // Use addCallEndedListener to support multiple listeners (MediasoupService also listens)
    _socketService.addCallEndedListener(_handleCallEnded);

    // Active call listener
    _socketService.onActiveCall = (data) {
      debugPrint('📞 ACTIVE CALL DETECTED: $data');
      if (!mounted) return;

      final roomId = data['roomId'] as String?;
      // Only update if it's for our chat group
      if (roomId == _chatGroupId) {
        final callTypeStr = data['callType'] as String?;
        final callType = callTypeStr == 'audio'
            ? CallType.audio
            : CallType.video;

        setState(() {
          _hasActiveCall = true;
          _activeCallId = data['callId'] as String?;
          _activeCallRoomId = roomId;
          _activeCallType = callType;
        });
        debugPrint(
          '📞 Active call state set: hasActiveCall=$_hasActiveCall, callId=$_activeCallId',
        );
      }
    };

    // Participant left listener - check if call ended (matches web implementation)
    // Use addParticipantLeftListener to support multiple listeners (MediasoupService also listens)
    _socketService.addParticipantLeftListener(_handleParticipantLeft);
  }

  /// Handle call ended event from socket
  void _handleCallEnded(Map<String, dynamic> data) {
    debugPrint('🛑 Call ended event: $data');
    if (!mounted) return;

    // Always clear active call state when callEnded event is received
    // The call has ended, so hide the Join Call button
    debugPrint('🛑 Clearing active call state from callEnded event');
    setState(() {
      _hasActiveCall = false;
      _activeCallId = null;
      _activeCallRoomId = null;
      _activeCallType = null;
    });
  }

  /// Handle participant left event from socket
  void _handleParticipantLeft(Map<String, dynamic> data) {
    debugPrint('👋 Chat screen participantLeft: $data');
    if (!mounted) return;

    final remainingParticipants = data['remainingParticipants'] as int? ?? 0;
    final activeCall = data['activeCall'] as bool?;

    debugPrint(
      '👋 remainingParticipants=$remainingParticipants, activeCall=$activeCall, _hasActiveCall=$_hasActiveCall',
    );

    // Check if call has effectively ended (matches web logic)
    final callEnded = remainingParticipants == 0 || activeCall == false;

    if (callEnded && _hasActiveCall) {
      debugPrint(
        '🛑 Call ended (remainingParticipants=0 or activeCall=false), clearing call state',
      );
      setState(() {
        _hasActiveCall = false;
        _activeCallId = null;
        _activeCallRoomId = null;
        _activeCallType = null;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <=
              _scrollController.position.minScrollExtent &&
          _scrollController.position.outOfRange) {
        _loadOlderMessages();
      } else if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          _scrollController.position.outOfRange) {
        _loadNewerMessages();
      }
    });
  }

  String _getUserName(String userId) {
    if (userId.isEmpty) return 'Unknown';

    // 1. Check if it's the current user
    final currentUserId = _currentUserId ?? _appCubit.state.userPermissions?.id;
    if (userId == currentUserId) {
      return _appCubit.state.userPermissions?.name ?? 'You';
    }

    // 2. Check team members list
    try {
      final member = _teamMembers.firstWhere((m) => m.id == userId);
      if (member.name.isNotEmpty && member.name != userId) {
        return member.name;
      }
    } catch (_) {}

    // 3. Check incident users list (often more reliable)
    try {
      final user = _incidentUsers.firstWhere((u) => u.id == userId);
      if (user.name != null && user.name!.isNotEmpty && user.name != userId) {
        return user.name!;
      }
    } catch (_) {}

    // 4. Check if we already have a message from this user with a proper name
    try {
      final msg = _messages.lastWhere(
        (m) =>
            m.senderId == userId &&
            m.senderName.isNotEmpty &&
            m.senderName != userId &&
            m.senderName != 'You',
      );
      return msg.senderName;
    } catch (_) {}

    return userId;
  }

  void _showIncomingCallDialog(IncomingCallData incomingCall) {
    debugPrint(
      '📞 Showing incoming call dialog for: ${incomingCall.initiatedBy}',
    );

    // Check if the caller is the current user (same user on different device)
    // Don't show incoming call notification for calls initiated by self
    final callerId = incomingCall.initiatedBy ?? '';
    if (callerId.isNotEmpty && callerId == _currentUserId) {
      debugPrint(
        '📞 Incoming call blocked - caller is current user (multi-device scenario)',
      );
      return;
    }

    // Check if we should show the dialog using CallStateManager
    final callStateManager = CallStateManager();
    final callId = incomingCall.callId ?? '';

    if (!callStateManager.showIncomingCallDialog(callId)) {
      debugPrint('📞 Incoming call dialog blocked by CallStateManager');
      return;
    }

    // Resolve caller name from userId - never show raw ID
    final callerName = callerId.isNotEmpty ? _getUserName(callerId) : 'Unknown';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large circular avatar with gradient background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF3DA229),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(callerName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Caller name
              Text(
                callerName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Call type indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    incomingCall.callType == CallType.audio
                        ? Assets.chatCallIcon
                        : Assets.chatVideoIcon,
                    width: 16,
                    height: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Incoming ${incomingCall.callType == CallType.audio ? 'Audio' : 'Video'} Call',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline button
                  Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          CallStateManager().dismissIncomingCallDialog();
                          debugPrint('📞 Call declined');
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF5252),
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),

                  // Accept button
                  Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          CallStateManager().dismissIncomingCallDialog();
                          _acceptCall(incomingCall);
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3DA229),
                          ),
                          child: Center(
                            child: Image.asset(
                              incomingCall.callType == CallType.audio
                                  ? Assets.chatCallIcon
                                  : Assets.chatVideoIcon,
                              width: 32,
                              height: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  void _acceptCall(IncomingCallData incomingCall) {
    // Navigate to audio/video call screen based on call type
    if (incomingCall.callType == CallType.audio) {
      openScreen(
        Routes.audioCallScreen,
        args: {
          'incidentId': widget.incidentId,
          'chatGroupId': _chatGroupId,
          'callId': incomingCall.callId,
          'roomId': incomingCall.roomId,
          'onlineCount': _onlineCount,
          'totalMembers': _membersCount,
          'participants': _teamMembers,
        },
      );
    } else {
      // Video call
      openScreen(
        Routes.videoCallScreen,
        args: {
          'incidentId': widget.incidentId,
          'chatGroupId': _chatGroupId,
          'callId': incomingCall.callId,
          'roomId': incomingCall.roomId,
          'onlineCount': _onlineCount,
          'totalMembers': _membersCount,
          'participants': _teamMembers,
        },
      );
    }
  }

  void _createChatGroup() {
    final chatRoomCubit = getIt<ChatRoomCubit>();
    chatRoomCubit.createChatGroup(widget.incidentId);
  }

  void _loadInitialMessages() {
    if (_chatGroupId == null || _isLoadingMessages) return;

    setState(() {
      _isLoadingMessages = true;
    });

    final chatRoomCubit = getIt<ChatRoomCubit>();
    chatRoomCubit.getChatMessages(groupId: _chatGroupId!);
  }

  void _loadOlderMessages() {
    if (_chatGroupId == null || _isLoadingOlderMessages || _messages.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingOlderMessages = true;
    });

    final firstMessageTime = _messages.first.timestamp.millisecondsSinceEpoch;

    final chatRoomCubit = getIt<ChatRoomCubit>();
    chatRoomCubit.getChatMessages(
      groupId: _chatGroupId!,
      before: firstMessageTime,
    );
  }

  void _loadNewerMessages() {
    if (_chatGroupId == null || _isLoadingNewerMessages || _messages.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingNewerMessages = true;
    });

    final lastMessageTime = _messages.last.timestamp.millisecondsSinceEpoch;

    final chatRoomCubit = getIt<ChatRoomCubit>();
    chatRoomCubit.getChatMessages(
      groupId: _chatGroupId!,
      after: lastMessageTime,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Cancel all typing timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _typingStopTimer?.cancel();
    // Remove socket listeners to prevent memory leaks
    _socketService.removeParticipantLeftListener(_handleParticipantLeft);
    _socketService.removeCallEndedListener(_handleCallEnded);
    if (_chatGroupId != null) {
      _socketService.leaveGroup(_chatGroupId!);
    }
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleTyping() {
    if (_chatGroupId == null || !_socketService.isConnected) {
      debugPrint(
        '⌨️ _handleTyping: skipped - chatGroupId=$_chatGroupId, connected=${_socketService.isConnected}',
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final senderName = _appCubit.state.userPermissions?.name ?? 'User';

    // Throttle: send at most once per 1000ms (matching web implementation)
    if (now - _lastTypingSentTime >= 1000) {
      debugPrint('⌨️ _handleTyping: emitting typing for group $_chatGroupId');
      _socketService.emitTyping(groupId: _chatGroupId!, senderName: senderName);
      _lastTypingSentTime = now;
    }

    // Reset stop typing timer (web doesn't use stopTyping, just relies on receiver timeout)
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 2), () {
      // Optionally emit stop typing for backends that support it
      if (_chatGroupId != null && _socketService.isConnected) {
        _socketService.emitStopTyping(
          groupId: _chatGroupId!,
          senderName: senderName,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _chatGroupId == null) return;

    if (!_socketService.isConnected) {
      debugPrint('Cannot send message: Socket not connected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost. Please wait...')),
      );
      return;
    }

    final message = _messageController.text.trim();
    final currentUserId =
        _currentUserId ?? _appCubit.state.userPermissions?.id ?? 'currentUser';
    final currentUserName = _appCubit.state.userPermissions?.name ?? 'User';

    debugPrint(
      'Sending message: $message from $currentUserId ($currentUserName)',
    );

    // Stop typing indicator when message is sent
    _socketService.emitStopTyping(
      groupId: _chatGroupId!,
      senderName: currentUserName,
    );

    // Emit message via socket (matches web payload exactly)
    _socketService.sendMessage(
      groupId: _chatGroupId!,
      message: message,
      senderName: currentUserName,
    );

    // Clear input immediately for better UX
    setState(() {
      _messageController.clear();
    });

    // Message will be added when received via socket confirmation
    debugPrint('Message sent to socket, waiting for confirmation');
  }

  /// Pick and send a document file
  Future<void> _pickAndSendDocument() async {
    if (_chatGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chat not initialized')));
      return;
    }

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick document: $e')));
      }
    }
  }

  /// Pick and send an image
  Future<void> _pickAndSendImage() async {
    if (_chatGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chat not initialized')));
      return;
    }

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  /// Upload file to server and send as attachment
  Future<void> _uploadAndSendAttachment(File file, String fileName) async {
    if (!_socketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection lost. Please wait...')),
      );
      return;
    }

    // Show uploading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Uploading...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Upload file using the existing upload data source
      final uploadDataSource =
          getIt<OnboardingOrganizationStructureRemoteDataSource>();
      final response = await uploadDataSource.uploadOrganizationStructureFiles([
        file,
      ]);

      // Hide uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response.success == true &&
          response.data != null &&
          response.data!.files.isNotEmpty) {
        final uploadedFile = response.data!.files.first;
        final actualFileName = uploadedFile.fileName.isNotEmpty
            ? uploadedFile.fileName
            : fileName;

        // Determine type from file extension (image, video, or file)
        final attachmentType = ChatAttachment.getTypeFromExtension(
          actualFileName,
        );

        // Convert fileSize from bytes to MB (web format)
        final fileSizeInMb = uploadedFile.fileSize / (1024 * 1024);

        // Create attachment object matching web format EXACTLY
        final attachment = ChatAttachment(
          url: uploadedFile.fileUrl,
          type: attachmentType,
          key: uploadedFile.key,
          fileSize: fileSizeInMb,
          filename: actualFileName,
        );

        // Send message with attachment
        _sendMessageWithAttachment(attachment);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File sent successfully'),
              backgroundColor: Color(0xFF3DA229),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Send a message with attachment (matches web payload exactly)
  void _sendMessageWithAttachment(ChatAttachment attachment) {
    if (_chatGroupId == null) return;

    // Use filename as message (matches web behavior)
    final message = attachment.filename;
    final currentUserName = _appCubit.state.userPermissions?.name ?? 'User';

    debugPrint('Sending attachment: ${attachment.filename} ($currentUserName)');

    // Convert attachment to JSON array for socket (web sends array)
    final attachmentJson = [attachment.toJson()];

    // Emit message with attachment via socket (matches web payload exactly)
    _socketService.sendMessage(
      groupId: _chatGroupId!,
      message: message,
      senderName: currentUserName,
      attachment: attachmentJson,
    );

    // Clear input
    setState(() {
      _messageController.clear();
    });

    // Message will be added when received via socket confirmation
    debugPrint('Attachment sent to socket, waiting for confirmation');
  }

  void _showAddMembersModal() {
    setState(() {
      _shouldShowMembersModal = true;
    });

    final chatRoomCubit = getIt<ChatRoomCubit>();
    chatRoomCubit.getIncidentUsers(
      incidentId: widget.incidentId,
      groupId: _chatGroupId,
    );
  }

  void _displayMembersModal() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AddMembersModal(
            teamMembers: _teamMembers,
            inviteMembers: _inviteMembers,
            incidentUsers: _incidentUsers,
            onMemberRemoved: (member) {
              setState(() {
                _teamMembers.removeWhere((m) => m.id == member.id);
                _inviteMembers.add(
                  member.copyWith(isTeamMember: false, isOnline: false),
                );
              });
              setModalState(() {});

              if (_chatGroupId != null) {
                final chatRoomCubit = getIt<ChatRoomCubit>();
                chatRoomCubit.removeMember(
                  groupId: _chatGroupId!,
                  userId: member.id,
                );
              }
            },
            onMemberAdded: (member) {
              setState(() {
                _inviteMembers.removeWhere((m) => m.id == member.id);
                _teamMembers.add(
                  member.copyWith(isTeamMember: true, isOnline: true),
                );
              });
              setModalState(() {});

              if (_chatGroupId != null) {
                final chatRoomCubit = getIt<ChatRoomCubit>();
                chatRoomCubit.addMember(
                  groupId: _chatGroupId!,
                  userId: member.id,
                );
              }
            },
          );
        },
      ),
    );
  }

  void _showUserProfile(ChatMessage message, Rect avatarRect) {
    // Find member from the team members list or create basic member info
    ChatMember? member;

    if (message.isMe) {
      final currentUserId =
          _currentUserId ?? _appCubit.state.userPermissions?.id;
      final userName = _appCubit.state.userPermissions?.name ?? 'You';
      final userEmail = _appCubit.state.userPermissions?.email ?? '';

      member = ChatMember(
        id: currentUserId ?? 'currentUser',
        name: userName,
        email: userEmail,
        avatar: message.senderAvatar,
        role: _appCubit.state.userPermissions?.permissions.isNotEmpty == true
            ? _appCubit.state.userPermissions!.permissions.first.roleName
            : '',
        team: '',
        isOnline: true,
        isTeamMember: true,
      );
    } else {
      // Try to find from team members
      try {
        member = _teamMembers.firstWhere((m) => m.id == message.senderId);
      } catch (e) {
        // Create basic member info if not found
        member = ChatMember(
          id: message.senderId,
          name: message.senderName,
          email: '',
          avatar: message.senderAvatar,
          role: '',
          team: '',
          isOnline: message.isOnline,
          isTeamMember: true,
        );
      }
    }

    setState(() {
      _selectedMember = member;
      _avatarRect = avatarRect;
    });
  }

  void _hideUserProfile() {
    setState(() {
      _selectedMember = null;
      _avatarRect = null;
    });
  }

  /// Safe back navigation that handles cases where this screen is the root route
  void _safeBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.homeScreen);
    }
  }

  void _handleEmailAction(ChatMember member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email for ${member.email}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ChatRoomCubit>(),
      child: BlocListener<ChatRoomCubit, ChatRoomState>(
        listener: (context, state) {
          // Handle chat group created
          if (state.chatGroup != null && _chatGroupId != state.chatGroup!.id) {
            setState(() {
              _chatGroupId = state.chatGroup!.id;
              final currentUserId =
                  _currentUserId ?? _appCubit.state.userPermissions?.id;

              // Build team members from chatGroupResponse.members
              // Counts will be updated after building the list
              _teamMembers = (state.chatGroupResponse?.members ?? [])
                  //.where((m) => m.userId != currentUserId) // 🚫 remove self
                  .map((m) {
                    // Store member active status for later reference
                    if (m.userId != null) {
                      _memberIsActiveMap[m.userId!] = m.isActive ?? false;
                    }
                    return ChatMember(
                      id: m.userId ?? '', // ✅ userId (parsed from user field)
                      name:
                          m.userName ??
                          '', // ✅ userName (direct or from userDetails)
                      email: m.userEmail ?? '', // ✅ userEmail (from flat JSON)
                      avatar: '',
                      role: m.role ?? '',
                      team: '',
                      isOnline: m.isActive ?? false,
                      isTeamMember: true,
                    );
                  })
                  .toList();

              // Update counts based on team members
              _membersCount = _teamMembers.length;
              _onlineCount = _teamMembers.where((m) => m.isOnline).length;

              // Refresh typing users names with new member data
              if (_typingUsers.isNotEmpty) {
                for (final id in _typingUsers.keys.toList()) {
                  _typingUsers[id] = _getUserName(id);
                }
              }

              // Set active call from response (matches web implementation)
              final activeCall = state.chatGroupResponse?.activeCall;
              if (activeCall != null && activeCall.callId != null) {
                // Check if this call has already ended (we received participantLeft with remainingParticipants: 0)
                if (!CallStateManager().isCallEnded(activeCall.callId!)) {
                  _hasActiveCall = true;
                  _activeCallId = activeCall.callId;
                  _activeCallRoomId = activeCall.roomId;
                  _activeCallType = activeCall.callType;
                  debugPrint(
                    '📞 Active call found from API response: ${activeCall.callId}, type: ${activeCall.callType}',
                  );
                } else {
                  debugPrint(
                    '📞 Active call ${activeCall.callId} has already ended, not showing join button',
                  );
                  _hasActiveCall = false;
                  _activeCallId = null;
                  _activeCallRoomId = null;
                  _activeCallType = null;
                }
              }
            });

            _loadInitialMessages();

            final chatRoomCubit = getIt<ChatRoomCubit>();
            chatRoomCubit.getIncidentUsers(
              incidentId: widget.incidentId,
              groupId: _chatGroupId,
            );

            // Join group only if socket is already connected
            if (_socketService.isConnected && _chatGroupId != null) {
              debugPrint(
                'Socket already connected, joining group immediately: $_chatGroupId',
              );
              _socketService.joinGroup(_chatGroupId!);
              // Check for active call after joining group (matches web implementation)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_chatGroupId != null) {
                  _socketService.checkForActiveCall(_chatGroupId!);
                }
              });
            } else {
              debugPrint(
                'Socket not connected yet, will join group on socket connect event',
              );
            }
          }

          // Handle messages loaded
          if (state.messages.isNotEmpty &&
              state.processState == ProcessState.done) {
            final currentUserId =
                _currentUserId ?? _appCubit.state.userPermissions?.id;
            final newMessages = state.messages.map((apiMessage) {
              final senderId = apiMessage.sender ?? '';
              final isCurrentUser =
                  currentUserId != null && senderId == currentUserId;

              // Convert MessageAttachment to ChatAttachment
              final attachments = (apiMessage.attachments ?? [])
                  .map((att) => ChatAttachment.fromMessageAttachment(att))
                  .toList();

              return ChatMessage(
                id: apiMessage.id ?? '',
                senderId: senderId,
                senderName: isCurrentUser ? 'You' : _getUserName(senderId),
                senderAvatar: '',
                message: apiMessage.message ?? '',
                timestamp: apiMessage.messageTime != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        apiMessage.messageTime!,
                      )
                    : DateTime.now(),
                isMe: isCurrentUser,
                isOnline: false,
                attachments: attachments,
              );
            }).toList();

            final wasLoadingInitialMessages = _isLoadingMessages;

            setState(() {
              if (_isLoadingMessages) {
                _messages = newMessages;
                _isLoadingMessages = false;
              } else if (_isLoadingOlderMessages) {
                _messages = [...newMessages, ..._messages];
                _isLoadingOlderMessages = false;
              } else if (_isLoadingNewerMessages) {
                _messages = [..._messages, ...newMessages];
                _isLoadingNewerMessages = false;
              }
            });

            if (wasLoadingInitialMessages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          }

          // Handle incident users loaded - ONLY for building invite members list
          // Team members are ALWAYS from chatGroupResponse.members, never from incidentUsers
          // ✅ ALWAYS handle incidentUsers (even if empty)
          if (state.incidentUsers != null) {
            setState(() {
              _incidentUsers = state.incidentUsers;

              // Get current team member IDs to filter out from invite list
              final teamMemberIds = _teamMembers.map((m) => m.id).toSet();
              final currentUserId =
                  _currentUserId ?? _appCubit.state.userPermissions?.id;

              // ✅ Build invite members list
              _inviteMembers = state.incidentUsers
                  .where((user) => user.id != null)
                  .where((user) => !teamMemberIds.contains(user.id))
                  .where((user) => user.id != currentUserId) // 🚫 exclude self
                  .map(
                    (user) => ChatMember(
                      id: user.id ?? '',
                      name: user.name ?? '',
                      email: user.email ?? '',
                      avatar: '',
                      role: '',
                      team: '',
                      isOnline: false,
                      isTeamMember: false,
                    ),
                  )
                  .toList();

              // Refresh typing users names with updated data
              if (_typingUsers.isNotEmpty) {
                for (final id in _typingUsers.keys.toList()) {
                  _typingUsers[id] = _getUserName(id);
                }
              }
            });
          }

          // ✅ OPEN MODAL REGARDLESS OF invite list size
          if (_shouldShowMembersModal) {
            _shouldShowMembersModal = false;
            Future.microtask(() => _displayMembersModal());
          }

          // Handle success message (member added/removed)
          if (state.successMessage != null) {
            final chatRoomCubit = getIt<ChatRoomCubit>();
            chatRoomCubit.createChatGroup(widget.incidentId);

            chatRoomCubit.getIncidentUsers(
              incidentId: widget.incidentId,
              groupId: _chatGroupId,
            );

            // Clear the success message after handling
            chatRoomCubit.clearSuccess();
          }

          // Handle error
          if (state.processState == ProcessState.error) {
            setState(() {
              _isLoadingMessages = false;
              _isLoadingOlderMessages = false;
              _isLoadingNewerMessages = false;
            });
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEAF2E8), Color(0xFFB9C7B5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.6095],
                ),
              ),
              child: Column(
                children: [
                  // Custom header
                  ChatHeaderWidget(
                    incidentId: widget.incidentId,
                    onlineCount: _onlineCount,
                    totalMembers: _membersCount,
                    hasActiveCall: _hasActiveCall,
                    activeCallType: _activeCallType,
                    onBackPressed: () => _safeBack(context),
                    onCallPressed: () {
                      // Check if there's an active call - join instead of starting new
                      // This prevents duplicate users from starting a new call
                      final callId = _hasActiveCall ? _activeCallId : null;
                      final roomId = _hasActiveCall ? _activeCallRoomId : null;

                      if (_hasActiveCall) {
                        debugPrint('📞 Active call detected, joining existing call instead of starting new');
                        debugPrint('   - Call ID: $callId');
                        debugPrint('   - Room ID: $roomId');
                      }

                      openScreen(
                        Routes.audioCallScreen,
                        args: {
                          'incidentId': widget.incidentId,
                          'chatGroupId':
                              _chatGroupId, // ✅ Pass chat group ID for broadcasting
                          'callId': callId,
                          'roomId': roomId,
                          'onlineCount': _onlineCount,
                          'totalMembers': _membersCount,
                          'participants': _teamMembers,
                        },
                      );
                    },
                    onVideoPressed: () {
                      // Check if there's an active call - join instead of starting new
                      // This prevents duplicate users from starting a new call
                      final callId = _hasActiveCall ? _activeCallId : null;
                      final roomId = _hasActiveCall ? _activeCallRoomId : null;

                      if (_hasActiveCall) {
                        debugPrint('📞 Active call detected, joining existing call instead of starting new');
                        debugPrint('   - Call ID: $callId');
                        debugPrint('   - Room ID: $roomId');
                      }

                      openScreen(
                        Routes.videoCallScreen,
                        args: {
                          'incidentId': widget.incidentId,
                          'chatGroupId':
                              _chatGroupId, // ✅ Pass chat group ID for broadcasting
                          'callId': callId,
                          'roomId': roomId,
                          'onlineCount': _onlineCount,
                          'totalMembers': _membersCount,
                          'participants': _teamMembers,
                        },
                      );
                    },
                    onMenuPressed: _showAddMembersModal,
                  ),
                  // Messages list
                  Expanded(
                    child: Stack(
                      key: _stackKey,
                      children: [
                        // Message list
                        GestureDetector(
                          onTap: _hideUserProfile,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 14,
                              top: 10,
                              bottom: 30,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];

                              return ChatMessageBubble(
                                message: message,
                                resolveUserName: _getUserName,
                                onAvatarTap: (avatarRect) {
                                  _showUserProfile(message, avatarRect);
                                },
                              );
                            },
                          ),
                        ),
                        // User profile card overlay
                        if (_selectedMember != null && _avatarRect != null)
                          Builder(
                            builder: (context) {
                              // Card dimensions (must match UserProfileCard)
                              const cardWidth = 170.0;
                              const cardHeight = 180.0;
                              const gap = 6.0;
                              const margin = 10.0;

                              // Get Stack's position to convert global to local coordinates
                              final stackRenderBox =
                                  _stackKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (stackRenderBox == null) {
                                return const SizedBox.shrink();
                              }

                              final stackOffset = stackRenderBox.localToGlobal(
                                Offset.zero,
                              );
                              final stackSize = stackRenderBox.size;

                              // Convert avatar global coordinates to Stack-local coordinates
                              final avatarLeft =
                                  _avatarRect!.left - stackOffset.dx;
                              final avatarTop =
                                  _avatarRect!.top - stackOffset.dy;
                              final avatarBottom =
                                  _avatarRect!.bottom - stackOffset.dy;
                              final avatarRight =
                                  _avatarRect!.right - stackOffset.dx;

                              // Calculate initial position below avatar
                              double left;
                              double top = avatarBottom + gap;

                              // Determine horizontal alignment based on avatar position
                              final isRightSide =
                                  avatarLeft > stackSize.width / 2;
                              if (isRightSide) {
                                // Right-side avatar: align card's right edge with avatar's right edge
                                left = avatarRight - cardWidth;
                              } else {
                                // Left-side avatar: align card's left edge with avatar's left edge
                                left = avatarLeft;
                              }

                              // Clamp horizontal position within Stack bounds
                              left = left.clamp(
                                margin,
                                stackSize.width - cardWidth - margin,
                              );

                              // Check if card overflows bottom, show above if needed
                              if (top + cardHeight >
                                  stackSize.height - margin) {
                                top = avatarTop - cardHeight - gap;
                              }

                              // Clamp vertical position within Stack bounds
                              top = top.clamp(
                                margin,
                                stackSize.height - cardHeight - margin,
                              );

                              return Positioned(
                                left: left,
                                top: top,
                                child: GestureDetector(
                                  onTap: () {},
                                  child: UserProfileCard(
                                    member: _selectedMember!,
                                    onEmailPressed: () {
                                      _handleEmailAction(_selectedMember!);
                                      _hideUserProfile();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  // Input bar with typing indicator above
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Input bar
                      ChatInputBarWidget(
                        controller: _messageController,
                        onSendPressed: _sendMessage,
                        onChanged: (_) => _handleTyping(),
                        onAttachmentPressed: _pickAndSendDocument,
                        onGalleryPressed: _pickAndSendImage,
                      ),
                      // Typing indicator positioned above input bar
                      if (_typingUsers.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 70,
                          child: TypingIndicatorWidget(
                            typingUsers: _typingUsers,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
