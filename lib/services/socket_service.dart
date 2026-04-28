import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:emergex/services/call_state_manager.dart';

class SocketService {
  io.Socket? _socket;
  String? _userId;
  bool _isConnected = false;

  // Chat event callbacks
  Function(int count)? onOnlineUsersCount;
  Function(Map<String, dynamic> data)? onGroupOnlineCount; // Per-group online count
  Function(String userId)? onUserOnline;
  Function(String userId)? onUserOffline;
  Function(Map<String, dynamic> data)? onNewMessage;
  Function(Map<String, dynamic> data)? onTyping;
  Function()? onConnect;
  Function()? onDisconnect;
  Function(int attemptNumber)? onReconnectAttempt;
  Function(int attemptNumber)? onReconnect;
  Function()? onReconnectFailed;
  Function(dynamic error)? onConnectError;

  // Call event callbacks
  Function(Map<String, dynamic> data)? onIncomingCall;
  Function(Map<String, dynamic> data)? onCallEnded;
  Function(Map<String, dynamic> data)? onParticipantJoined;
  Function(Map<String, dynamic> data)? onParticipantLeft;
  Function(Map<String, dynamic> data)? onActiveCall;

  // Additional listeners for participantLeft and callEnded (supports multiple listeners)
  // These are called IN ADDITION to the single callbacks above
  final List<Function(Map<String, dynamic> data)> _participantLeftListeners = [];
  final List<Function(Map<String, dynamic> data)> _callEndedListeners = [];

  /// Add a listener for participantLeft events (supports multiple listeners)
  void addParticipantLeftListener(Function(Map<String, dynamic> data) listener) {
    _participantLeftListeners.add(listener);
  }

  /// Remove a listener for participantLeft events
  void removeParticipantLeftListener(Function(Map<String, dynamic> data) listener) {
    _participantLeftListeners.remove(listener);
  }

  /// Add a listener for callEnded events (supports multiple listeners)
  void addCallEndedListener(Function(Map<String, dynamic> data) listener) {
    _callEndedListeners.add(listener);
  }

  /// Remove a listener for callEnded events
  void removeCallEndedListener(Function(Map<String, dynamic> data) listener) {
    _callEndedListeners.remove(listener);
  }
  Function(Map<String, dynamic> data)? onNewPeer;
  Function(Map<String, dynamic> data)? onNewProducer;
  Function(Map<String, dynamic> data)? onPeerClosed;
  Function(Map<String, dynamic> data)? onProducerClosed;
  Function(Map<String, dynamic> data)? onProducerPaused;
  Function(Map<String, dynamic> data)? onProducerResumed;
  Function(Map<String, dynamic> data)? onCameraSwitched;

  bool get isConnected => _isConnected;
  String? get userId => _userId;

  void connect(String userId) {
    if (_socket != null && _socket!.connected) {
      disconnect();
    }

    _userId = userId;

    _socket = io.io(
      'https://dev-emergex.zapptor.com',
      io.OptionBuilder()
          .setPath('/chat')
          .setQuery({'userId': userId})
          .setTransports(['websocket', 'polling']) // Add polling as fallback
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(5)
          .build(),
    );

    debugPrint('🔌 Connecting socket with userId: $userId');
    _setupListeners();
    _socket!.connect();
  }

  void _setupListeners() {
    // Connection events
    _socket?.on('connect', (_) {
      _isConnected = true;
      debugPrint('Socket connected: ${_socket?.id}');
      onConnect?.call();
    });

    _socket?.on('disconnect', (reason) {
      _isConnected = false;
      debugPrint('Socket disconnected: $reason');
      onDisconnect?.call();

      // If server disconnected, manually reconnect
      if (reason == 'io server disconnect') {
        _socket?.connect();
      }
    });

    _socket?.on('reconnect_attempt', (attemptNumber) {
      debugPrint('Reconnection attempt $attemptNumber...');
      if (attemptNumber is int) {
        onReconnectAttempt?.call(attemptNumber);
      }
    });

    _socket?.on('reconnect', (attemptNumber) {
      debugPrint('Reconnected after $attemptNumber attempts');
      if (attemptNumber is int) {
        onReconnect?.call(attemptNumber);
      }
    });

    _socket?.on('reconnect_failed', (_) {
      debugPrint('Reconnection failed after all attempts');
      onReconnectFailed?.call();
    });

    _socket?.on('connect_error', (error) {
      debugPrint('Connection error: $error');
      onConnectError?.call(error);
    });

    _socket?.on('error', (error) {
      debugPrint('Socket error: $error');
    });

    // Chat events - Global online count
    _socket?.on('onlineUsersCount', (data) {
      debugPrint('Total online users (platform): $data');
      if (data is int) {
        onOnlineUsersCount?.call(data);
      }
    });

    // Per-group online count
    _socket?.on('groupOnlineCount', (data) {
      debugPrint('Group online count: $data');
      if (data is Map<String, dynamic>) {
        onGroupOnlineCount?.call(data);
      }
    });

    // User online/offline events
    _socket?.on('userOnline', (userId) {
      debugPrint('User $userId is now online');
      if (userId is String) {
        onUserOnline?.call(userId);
      }
    });

    _socket?.on('userOffline', (userId) {
      debugPrint('User $userId is now offline');
      if (userId is String) {
        onUserOffline?.call(userId);
      }
    });

    _socket?.on('newMessage', (data) {
      debugPrint('Socket received newMessage event: $data');
      if (data is Map<String, dynamic>) {
        onNewMessage?.call(data);
      } else {
        debugPrint('Invalid newMessage data type: ${data.runtimeType}');
      }
    });

    _socket?.on('typing', (data) {
      debugPrint('⌨️ Socket received typing event: $data');
      if (data is Map<String, dynamic>) {
        onTyping?.call(data);
      } else {
        debugPrint('⌨️ Invalid typing data type: ${data.runtimeType}');
      }
    });

    // Call events
    _socket?.on('incomingCall', (data) {
      debugPrint('📞 Socket received incomingCall event: $data');
      if (data is Map<String, dynamic>) {
        onIncomingCall?.call(data);
      }
    });

    _socket?.on('callEnded', (data) {
      debugPrint('🛑 Socket received callEnded event: $data');
      if (data is Map<String, dynamic>) {
        // Mark call as ended globally so chat_screen knows not to show join button
        final callId = data['callId'] as String?;
        if (callId != null) {
          CallStateManager().markCallEnded(callId);
        }
        // Call the main callback
        onCallEnded?.call(data);
        // Also call all additional listeners
        for (final listener in _callEndedListeners) {
          listener(data);
        }
      }
    });

    // Participant joined - includes currentParticipants count
    _socket?.on('participantJoined', (data) {
      debugPrint('👥 Socket received participantJoined event: $data');
      if (data is Map<String, dynamic>) {
        onParticipantJoined?.call(data);
      }
    });

    // Participant left - includes remainingParticipants count
    _socket?.on('participantLeft', (data) {
      debugPrint('👋 Socket received participantLeft event: $data');
      if (data is Map<String, dynamic>) {
        // If remainingParticipants is 0, mark call as ended globally
        final remainingParticipants = data['remainingParticipants'] as int?;
        if (remainingParticipants == 0) {
          final callId = data['callId'] as String?;
          if (callId != null) {
            CallStateManager().markCallEnded(callId);
          }
        }
        // Call the main callback
        onParticipantLeft?.call(data);
        // Also call all additional listeners
        for (final listener in _participantLeftListeners) {
          listener(data);
        }
      }
    });

    // Active call - notifies when there's an ongoing call in the group
    _socket?.on('activeCall', (data) {
      debugPrint('📞 Socket received activeCall event: $data');
      if (data is Map<String, dynamic>) {
        onActiveCall?.call(data);
      }
    });

    _socket?.on('newPeer', (data) {
      debugPrint('🆕 Socket received newPeer event: $data');
      if (data is Map<String, dynamic>) {
        onNewPeer?.call(data);
      }
    });

    // New producer - includes paused state
    _socket?.on('newProducer', (data) {
      debugPrint('📢 Socket received newProducer event: $data');
      if (data is Map<String, dynamic>) {
        onNewProducer?.call(data);
      }
    });

    _socket?.on('peerClosed', (data) {
      debugPrint('🚪 Socket received peerClosed event: $data');
      if (data is Map<String, dynamic>) {
        onPeerClosed?.call(data);
      }
    });

    _socket?.on('producerClosed', (data) {
      debugPrint('🔌 Socket received producerClosed event: $data');
      if (data is Map<String, dynamic>) {
        onProducerClosed?.call(data);
      }
    });

    // Producer paused - includes userId, kind, mediaType, userName
    _socket?.on('producerPaused', (data) {
      debugPrint('🔇 Socket received producerPaused event: $data');
      if (data is Map<String, dynamic>) {
        onProducerPaused?.call(data);
      }
    });

    // Producer resumed - includes userId, kind, mediaType, userName
    _socket?.on('producerResumed', (data) {
      debugPrint('🔊 Socket received producerResumed event: $data');
      if (data is Map<String, dynamic>) {
        onProducerResumed?.call(data);
      }
    });

    // Camera switched - notifies when a participant switches between front/back camera
    _socket?.on('cameraSwitched', (data) {
      debugPrint('📷 Socket received cameraSwitched event: $data');
      if (data is Map<String, dynamic>) {
        onCameraSwitched?.call(data);
      }
    });
  }

  void joinGroup(String groupId) {
    if (_socket?.connected == true) {
      _socket!.emit('joinGroup', groupId);
      debugPrint('✅ Successfully joined group: $groupId');
    } else {
      debugPrint('❌ Socket not connected, cannot join group: $groupId');
    }
  }

  /// Send a message with optional attachment
  /// ⚠️ MUST match web payload EXACTLY:
  /// { groupId, senderId, senderName, message, attachment: [...] }
  /// where attachment = { url, type: 'image'|'video'|'file', key, fileSize, filename }
  void sendMessage({
    required String groupId,
    required String message,
    required String senderName,
    List<Map<String, dynamic>>? attachment,
  }) {
    if (_socket?.connected != true) {
      debugPrint('❌ Socket not connected, cannot send message');
      return;
    }

    if (_userId == null) {
      debugPrint('❌ User ID not set, cannot send message');
      return;
    }

    final data = {
      'groupId': groupId,
      'senderId': _userId,
      'senderName': senderName,
      'message': message,
      if (attachment != null && attachment.isNotEmpty) 'attachment': attachment,
    };

    _socket!.emit('sendMessage', data);
    debugPrint(
      '✅ Message sent to socket - groupId: $groupId, senderId: $_userId, senderName: $senderName, message: $message, attachment: ${attachment?.length ?? 0}',
    );
  }

  /// Emit typing indicator - matches web implementation: { groupId, senderId }
  /// Optionally includes senderName for display purposes
  void emitTyping({
    required String groupId,
    String? senderName,
  }) {
    if (_socket?.connected == true && _userId != null) {
      final payload = {
        'groupId': groupId,
        'senderId': _userId,
        if (senderName != null) 'senderName': senderName,
      };
      _socket!.emit('typing', payload);
      debugPrint('⌨️ Emitted typing event: $payload');
    } else {
      debugPrint('⌨️ Cannot emit typing: socket connected=${_socket?.connected}, userId=$_userId');
    }
  }

  /// Stop typing indicator - per reference: { groupId, senderId, senderName }
  void emitStopTyping({
    required String groupId,
    required String senderName,
  }) {
    if (_socket?.connected == true && _userId != null) {
      final payload = {
        'groupId': groupId,
        'senderId': _userId,
        'senderName': senderName,
      };
      _socket!.emit('stopTyping', payload);
      debugPrint('⌨️ Emitted stopTyping event: $payload');
    }
  }

  void leaveGroup(String groupId) {
    if (_socket?.connected == true) {
      _socket!.emit('leaveGroup', groupId);
      debugPrint('Left group: $groupId');
    }
  }

  /// Check for active call in a group - matches web implementation
  /// Emits participantLeft with checkActiveCall flag, backend responds with activeCall event
  void checkForActiveCall(String roomId) {
    if (_socket?.connected == true && _userId != null) {
      final data = {
        'roomId': roomId,
        'odId': _userId,
        'checkActiveCall': true,
      };
      _socket!.emit('participantLeft', data);
      debugPrint('📞 Checking for active call in room: $roomId');
    } else {
      debugPrint('❌ Cannot check for active call: socket connected=${_socket?.connected}, userId=$_userId');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _userId = null;
    }
  }

  // Call-related emit methods
  void startCall(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'startCall',
        data,
        ack: (response) {
          debugPrint('✅ startCall response: $response');
          if (response is Map<String, dynamic>) {
            callback(response);
          }
        },
      );
    } else {
      debugPrint('❌ Socket not connected, cannot start call');
    }
  }

  void joinCall(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'joinCall',
        data,
        ack: (response) {
          debugPrint('✅ joinCall response: $response');
          if (response is Map<String, dynamic>) {
            callback(response);
          }
        },
      );
    } else {
      debugPrint('❌ Socket not connected, cannot join call');
    }
  }

  void endCall(Map<String, dynamic> data) {
    if (_socket?.connected == true) {
      _socket!.emit('endCall', data);
      debugPrint('✅ endCall emitted: $data');
    }
  }

  void leaveCall(Map<String, dynamic> data) {
    if (_socket?.connected == true) {
      _socket!.emit('leaveCall', data);
      debugPrint('✅ leaveCall emitted: $data');
    }
  }

  // Mediasoup WebRTC transport methods
  void getRouterRtpCapabilities(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'getRouterRtpCapabilities',
        data,
        ack: (response) {
          debugPrint('✅ getRouterRtpCapabilities response received');
          if (response is Map<String, dynamic>) {
            callback(response);
          }
        },
      );
    }
  }

  void joinRoom(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'joinRoom',
        data,
        ack: (response) {
          debugPrint('✅ joinRoom response: $response');
          if (response is Map<String, dynamic>) {
            callback(response);
          }
        },
      );
    }
  }

  void createWebRtcTransport(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'createWebRtcTransport',
        data,
        ack: (response) {
          debugPrint('🔧 createWebRtcTransport response received');
          if (response is Map<String, dynamic>) {
            callback(response);
          }
        },
      );
    }
  }

  void connectWebRtcTransport(Map<String, dynamic> data, Function() callback) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'connectWebRtcTransport',
        data,
        ack: (_) {
          debugPrint('✅ connectWebRtcTransport acknowledged');
          callback();
        },
      );
    }
  }

  void produce(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'produce',
        data,
        ack: (response) {
          debugPrint('✅ produce response: $response');
          if (response is Map<String, dynamic>) {
            callback(response);
          }
        },
      );
    }
  }

  void consume(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_socket?.connected == true) {
      _socket!.emitWithAck(
        'consume',
        data,
        ack: (response) {
          debugPrint('🔊 consume response received');
          if (response is Map<String, dynamic>) {
            callback(response);
          }
        },
      );
    }
  }

  /// Resume consumer - per reference uses ack callback
  void resumeConsumer(
    Map<String, dynamic> data, [
    Function(Map<String, dynamic>)? callback,
  ]) {
    if (_socket?.connected == true) {
      if (callback != null) {
        _socket!.emitWithAck(
          'resumeConsumer',
          data,
          ack: (response) {
            debugPrint('▶️ resumeConsumer response: $response');
            if (response is Map<String, dynamic>) {
              callback(response);
            }
          },
        );
      } else {
        _socket!.emit('resumeConsumer', data);
        debugPrint('▶️ resumeConsumer emitted');
      }
    }
  }

  /// Pause producer - per reference uses ack callback
  void pauseProducer(
    Map<String, dynamic> data, [
    Function(Map<String, dynamic>)? callback,
  ]) {
    if (_socket?.connected == true) {
      if (callback != null) {
        _socket!.emitWithAck(
          'pauseProducer',
          data,
          ack: (response) {
            debugPrint('⏸️ pauseProducer response: $response');
            if (response is Map<String, dynamic>) {
              callback(response);
            }
          },
        );
      } else {
        _socket!.emit('pauseProducer', data);
        debugPrint('⏸️ pauseProducer emitted');
      }
    }
  }

  /// Resume producer - per reference uses ack callback
  void resumeProducer(
    Map<String, dynamic> data, [
    Function(Map<String, dynamic>)? callback,
  ]) {
    if (_socket?.connected == true) {
      if (callback != null) {
        _socket!.emitWithAck(
          'resumeProducer',
          data,
          ack: (response) {
            debugPrint('▶️ resumeProducer response: $response');
            if (response is Map<String, dynamic>) {
              callback(response);
            }
          },
        );
      } else {
        _socket!.emit('resumeProducer', data);
        debugPrint('▶️ resumeProducer emitted');
      }
    }
  }

  /// Close producer - for screen sharing cleanup
  void closeProducer(
    Map<String, dynamic> data,
    Function(Map<String, dynamic>)? callback,
  ) {
    if (_socket?.connected == true) {
      if (callback != null) {
        _socket!.emitWithAck(
          'closeProducer',
          data,
          ack: (response) {
            debugPrint('🔌 closeProducer response: $response');
            if (response is Map<String, dynamic>) {
              callback(response);
            }
          },
        );
      } else {
        _socket!.emit('closeProducer', data);
        debugPrint('🔌 closeProducer emitted');
      }
    }
  }

  /// Emit camera switched event to notify other participants
  /// Data: { peerId, isFrontCamera }
  void emitCameraSwitched(Map<String, dynamic> data) {
    if (_socket?.connected == true) {
      _socket!.emit('cameraSwitched', data);
      debugPrint('📷 cameraSwitched emitted: $data');
    }
  }

  void dispose() {
    disconnect();
    // Chat callbacks
    onOnlineUsersCount = null;
    onGroupOnlineCount = null;
    onUserOnline = null;
    onUserOffline = null;
    onNewMessage = null;
    onTyping = null;
    // Connection callbacks
    onConnect = null;
    onDisconnect = null;
    onReconnectAttempt = null;
    onReconnect = null;
    onReconnectFailed = null;
    onConnectError = null;
    // Call callbacks
    onIncomingCall = null;
    onCallEnded = null;
    onParticipantJoined = null;
    onParticipantLeft = null;
    onActiveCall = null;
    onNewPeer = null;
    onNewProducer = null;
    onPeerClosed = null;
    onProducerClosed = null;
    onProducerPaused = null;
    onProducerResumed = null;
    onCameraSwitched = null;
    // Clear listener lists
    _participantLeftListeners.clear();
    _callEndedListeners.clear();
  }
}
