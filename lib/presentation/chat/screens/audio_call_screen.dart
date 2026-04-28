import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_observer.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/services/socket_service.dart';
import 'package:emergex/services/mediasoup_service.dart';
import 'package:emergex/services/call_state_manager.dart';
import 'package:emergex/data/model/call_models.dart'
    show CallType, RemoteParticipantStatus;
import 'package:emergex/data/remote_data_source/login_remote_data_source.dart';
import 'package:emergex/presentation/chat/cubit/chat_cubit/chat_room_cubit.dart';
import 'package:emergex/data/model/chat_room/incident_user_response.dart'
    as api;
import '../models/chat_member_model.dart';
import '../widgets/call/call_header_widget.dart';
import '../widgets/call/call_participant_grid_widget.dart';
import '../widgets/call/mini_chat_bottom_sheet.dart';
import '../widgets/chat/add_members_modal_widget.dart';

/// Audio call screen for incident team communication
/// Displays participants in a grid layout with audio controls
class AudioCallScreen extends StatefulWidget {
  final String incidentId;
  final String chatGroupId;
  final int onlineCount;
  final int totalMembers;
  final List<ChatMember> participants;
  final String? callId;
  final String? roomId;

  const AudioCallScreen({
    super.key,
    required this.incidentId,
    required this.chatGroupId,
    required this.onlineCount,
    required this.totalMembers,
    required this.participants,
    this.callId,
    this.roomId,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late SocketService _socketService;
  MediasoupService? _mediasoupService;
  bool _isMuted = false;
  bool _isConnecting = true;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  bool _isNavigatingAway = false; // Prevent double navigation
  bool _showMiniChat = false;
  bool _isMiniChatExpanded = true;

  // Add member state
  List<ChatMember> _teamMembers = [];
  List<ChatMember> _inviteMembers = [];
  List<api.IncidentUser> _incidentUsers = [];
  final Map<String, bool> _memberIsActiveMap = {};
  bool _shouldShowMembersModal = false;

  @override
  void initState() {
    super.initState();
    _socketService = getIt<SocketService>();
    // Mark that we're now in a call - prevents incoming call dialogs
    CallStateManager().setInCall(true);
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // Get current user info
      final loginDataSource = getIt<LoginRemoteDataSource>();
      final userResponse = await loginDataSource.getUserPermissions();

      if (userResponse.success == true && userResponse.data != null) {
        _currentUserId = userResponse.data!.id;
        _currentUserName = userResponse.data?.name ?? 'User';
        _currentUserAvatar = userResponse.data?.profile;

        if (_currentUserId != null) {
          // Initialize MediasoupService
          _mediasoupService = getIt.get<MediasoupService>(
            param1: _currentUserId!,
            param2: _currentUserName!,
          );

          // Setup listeners
          _setupCallListeners();

          // Start or join call
          if (widget.callId != null && widget.roomId != null) {
            // Join existing call
            await _joinCall();
          } else {
            // Start new call
            await _startCall();
          }

          setState(() {
            _isConnecting = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing call: $e');
      setState(() {
        _isConnecting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize call: $e')),
        );
      }
    }
  }

  void _setupCallListeners() {
    if (_mediasoupService == null) return;

    // Listen to mute state changes
    _mediasoupService!.mutedStream.listen((isMuted) {
      if (mounted) {
        setState(() {
          _isMuted = isMuted;
        });
      }
    });

    // Listen to call state changes
    // Use _isNavigatingAway flag to prevent double navigation
    _mediasoupService!.callStateStream.listen((isInCall) {
      if (!isInCall && mounted && !_isNavigatingAway) {
        _isNavigatingAway = true;
        debugPrint(
          '📞 Call state changed to not in call, navigating back to chat',
        );
        _navigateToChatScreen();
      }
    });

    // 🔥 FIX: Chain socket callbacks instead of replacing them
    // MediasoupService has already set up handlers for these events.
    // We need to call the original handlers first, then add our own logic.

    // Store original callbacks set by MediasoupService
    final originalOnPeerClosed = _socketService.onPeerClosed;
    final originalOnParticipantJoined = _socketService.onParticipantJoined;
    final originalOnParticipantLeft = _socketService.onParticipantLeft;

    // Don't auto-end call when backend sends callEnded event
    // The call should only end when the user clicks the end call button
    _socketService.onCallEnded = (data) {
      debugPrint(
        '📞 Call ended event received from remote (ignored - user must end call manually)',
      );
      // Don't call original handler - we don't want to auto-cleanup
    };

    // Chain peerClosed - call original handler first to remove participant from UI
    _socketService.onPeerClosed = (data) {
      debugPrint('📞 Peer closed event received: $data');
      // Call original MediasoupService handler (removes participant from maps)
      originalOnPeerClosed?.call(data);
      // Note: Don't auto-end call when remote participants leave
      // The call should only end when the user clicks the end call button
    };

    // Chain participantJoined - call original handler first
    _socketService.onParticipantJoined = (data) {
      debugPrint('📞 Participant joined: $data');
      // Call original MediasoupService handler (updates participant count)
      originalOnParticipantJoined?.call(data);
    };

    // Chain participantLeft - call original handler first to remove participant from UI
    _socketService.onParticipantLeft = (data) {
      debugPrint('📞 Participant left: $data');
      // Call original MediasoupService handler (removes participant from maps)
      originalOnParticipantLeft?.call(data);
    };
  }

  Future<void> _startCall() async {
    if (_mediasoupService == null) return;

    try {
      debugPrint('📞 Starting audio call for incident: ${widget.incidentId}');
      debugPrint('📋 Chat group ID: ${widget.chatGroupId}');

      final callId = await _mediasoupService!.startCall(
        chatGroup: widget.chatGroupId,
        callType: CallType.audio,
        incident: widget.incidentId,
      );

      if (callId != null) {
        debugPrint('✅ Audio call started: $callId');
      } else {
        throw Exception('Failed to start call');
      }
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start call: $e')));
        back();
      }
    }
  }

  Future<void> _joinCall() async {
    if (_mediasoupService == null ||
        widget.callId == null ||
        widget.roomId == null) {
      return;
    }

    try {
      debugPrint('📞 Joining audio call: ${widget.callId}');

      final success = await _mediasoupService!.joinCall(
        callId: widget.callId!,
        roomId: widget.roomId!,
        callType: CallType.audio,
        chatGroup: widget.chatGroupId,
      );

      if (success) {
        debugPrint('✅ Joined audio call');
      } else {
        throw Exception('Failed to join call');
      }
    } catch (e) {
      debugPrint('❌ Error joining call: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join call: $e')));
        back();
      }
    }
  }

  void _toggleMute() {
    if (_mediasoupService != null) {
      _mediasoupService!.toggleAudio();
    }
  }

  Future<void> _endCall() async {
    if (_isNavigatingAway) return; // Prevent double call
    _isNavigatingAway = true;

    debugPrint('📞 End call button pressed, navigating back to chat');

    if (_mediasoupService != null) {
      // Use leaveCall instead of endCall - this leaves the call without ending it for others
      // Matches web implementation where users always "leave" rather than "end"
      await _mediasoupService!.leaveCall();
    }

    _navigateToChatScreen();
  }

  /// Navigate back to chat screen with socket connection preserved
  void _navigateToChatScreen() {
    if (!mounted) return;
    debugPrint(
      '📞 Navigating back to chat screen for incident: ${widget.incidentId}',
    );

    // 🔥 FIX: Try to pop first to preserve navigation stack history
    // This ensures we go back to the existing ChatScreen which has the previous screen in its history
    if (context.canPop()) {
      context.pop();
      return;
    }

    // Fallback (e.g. if opened via deep link)
    final ctx = NavObserver.getCtx();
    if (ctx != null) {
      ctx.goNamed(
        Routes.chatScreen,
        queryParameters: {'incidentId': widget.incidentId},
      );
    }
  }

  /// Toggle the mini chat visibility
  void _toggleMiniChat() {
    setState(() {
      if (_showMiniChat && _isMiniChatExpanded) {
        // If chat is open and expanded, collapse it first
        _isMiniChatExpanded = false;
      } else if (_showMiniChat && !_isMiniChatExpanded) {
        // If chat is open but collapsed, close it
        _showMiniChat = false;
        _isMiniChatExpanded = true;
      } else {
        // If chat is closed, open it expanded
        _showMiniChat = true;
        _isMiniChatExpanded = true;
      }
    });
  }

  /// Toggle mini chat expanded/collapsed state
  void _toggleMiniChatExpanded() {
    setState(() {
      _isMiniChatExpanded = !_isMiniChatExpanded;
    });
  }

  /// Show add members modal - triggers loading incident users
  void _showAddMembersModal() {
    setState(() {
      _shouldShowMembersModal = true;
    });

    final chatRoomCubit = getIt<ChatRoomCubit>();
    chatRoomCubit.getIncidentUsers(
      incidentId: widget.incidentId,
      groupId: null,
    );
  }

  /// Display the add members modal dialog
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

              final chatRoomCubit = getIt<ChatRoomCubit>();
              chatRoomCubit.removeMember(
                groupId: widget.chatGroupId,
                userId: member.id,
              );
            },
            onMemberAdded: (member) {
              setState(() {
                _inviteMembers.removeWhere((m) => m.id == member.id);
                _teamMembers.add(
                  member.copyWith(isTeamMember: true, isOnline: true),
                );
              });
              setModalState(() {});

              final chatRoomCubit = getIt<ChatRoomCubit>();
              chatRoomCubit.addMember(
                groupId: widget.chatGroupId,
                userId: member.id,
              );
            },
          );
        },
      ),
    );
  }

  /// Sanitize display name - never show raw IDs
  /// Returns 'Unknown' if the name looks like an ID or is empty
  String _sanitizeDisplayName(String name, String oderId) {
    if (name.isEmpty) return 'Unknown';
    // If name equals the ID, it's likely not a real name
    if (name == oderId) return 'Unknown';
    // Check if name looks like a MongoDB ObjectId (24 hex chars)
    if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(name)) return 'Unknown';
    // Check if name looks like a UUID
    if (RegExp(
      r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$',
    ).hasMatch(name))
      return 'Unknown';
    return name;
  }

  @override
  void dispose() {
    // Mark that we're no longer in a call - allows incoming call dialogs again
    CallStateManager().setInCall(false);
    _mediasoupService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ChatRoomCubit>(),
      child: BlocListener<ChatRoomCubit, ChatRoomState>(
        listener: (context, state) {
          // Handle incident users loaded
          if (_shouldShowMembersModal) {
            setState(() {
              _shouldShowMembersModal = false;

              final currentUserId = _currentUserId;

              // 🔥 Users already joined in call (from mediasoup)
              final joinedCallUserIds =
                  _mediasoupService?.remoteParticipantStatus.keys.toSet() ?? {};

              // 🔥 Build TEAM MEMBERS only from chat group participants
              _teamMembers = widget.participants
                  .where((m) => m.id.isNotEmpty)
                  .where((m) => m.id != currentUserId) // 🚫 remove self
                  .where(
                    (m) => !joinedCallUserIds.contains(m.id),
                  ) // 🚫 already in call
                  .map((m) => m.copyWith(isTeamMember: true, isOnline: false))
                  .toList();

              // 🚫 Call screen-la invite members logic illa
              _inviteMembers = [];
            });

            Future.microtask(() => _displayMembersModal());
          }

          // Handle success message (member added/removed)
          if (state.successMessage != null) {
            final chatRoomCubit = getIt<ChatRoomCubit>();
            chatRoomCubit.getIncidentUsers(
              incidentId: widget.incidentId,
              groupId: null,
            );
            chatRoomCubit.clearSuccess();
          }
        },
        child: PopScope(
          canPop: false,
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEAF2E8), Color(0xFFB9C7B5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.6095],
                ),
              ),
              child: SafeArea(
                child: _isConnecting
                    ? _buildConnectingState()
                    : Stack(
                        children: [
                          Column(
                            children: [
                              // Header with incident info
                              CallHeaderWidget(
                                incidentId: widget.incidentId,
                                onlineCount: widget.onlineCount,
                                totalMembers: widget.totalMembers,
                                onBackPressed: _endCall,
                                onChatPressed: _toggleMiniChat,
                                onAddMemberPressed: _showAddMembersModal,
                              ),

                              // Participants grid with controls inside main card
                              Expanded(
                                child: StreamBuilder<Map<String, RemoteParticipantStatus>>(
                                  stream: _mediasoupService
                                      ?.remoteParticipantStatusStream,
                                  // 🔥 FIX: Use current values as initialData to show participants immediately
                                  // StreamBuilders might miss emissions that happen before they subscribe
                                  initialData:
                                      _mediasoupService
                                          ?.remoteParticipantStatus ??
                                      const {},
                                  builder: (context, statusSnapshot) {
                                    final participantStatus =
                                        statusSnapshot.data ?? {};

                                    return StreamBuilder<Map<String, String>>(
                                      stream: _mediasoupService
                                          ?.participantNamesStream,
                                      // 🔥 FIX: Use current values as initialData
                                      initialData:
                                          _mediasoupService?.participantNames ??
                                          const {},
                                      builder: (context, namesSnapshot) {
                                        final participantNames =
                                            namesSnapshot.data ?? {};

                                        // Convert remote participants to ChatMember format with mute status
                                        final activeParticipants =
                                            participantNames.entries.map((
                                              entry,
                                            ) {
                                              final status =
                                                  participantStatus[entry.key];
                                              final rawName =
                                                  status?.name ?? entry.value;
                                              // Sanitize name - never show ID
                                              final displayName =
                                                  _sanitizeDisplayName(
                                                    rawName,
                                                    entry.key,
                                                  );
                                              return ChatMember(
                                                id: entry.key,
                                                name: displayName,
                                                email: '',
                                                avatar: '',
                                                isOnline: true,
                                                isTeamMember: true,
                                                role: '',
                                                team: '',
                                                isMuted:
                                                    status?.isAudioMuted ??
                                                    false,
                                              );
                                            }).toList();

                                        return CallParticipantGridWidget(
                                          participants: activeParticipants,
                                          isVideoCall: false,
                                          currentUserMuted: _isMuted,
                                          onMuteToggle: _toggleMute,
                                          onEndCall: _endCall,
                                          currentUserAvatar: _currentUserAvatar,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Mini chat bottom sheet overlay
                          if (_showMiniChat)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                height: _isMiniChatExpanded
                                    ? MediaQuery.of(context).size.height * 0.55
                                    : 50,
                                child: MiniChatBottomSheet(
                                  chatGroupId: widget.chatGroupId,
                                  currentUserId: _currentUserId,
                                  currentUserName: _currentUserName,
                                  currentUserAvatar: _currentUserAvatar,
                                  onClose: _toggleMiniChatExpanded,
                                  isExpanded: _isMiniChatExpanded,
                                  participants: widget.participants,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3DA229)),
          ),
          const SizedBox(height: 20),
          Text(
            widget.callId != null ? 'Connecting...' : 'Starting call...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E2A),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              if (_mediasoupService != null) {
                _mediasoupService!.leaveCall();
              }
              back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
