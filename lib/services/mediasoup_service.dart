import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emergex/data/model/call_models.dart';
import 'package:emergex/services/socket_service.dart';

/// Mediasoup service for handling WebRTC calls using mediasoup_client_flutter
/// This service manages audio/video calls using the mediasoup protocol
///
/// Lifecycle Management:
/// - [_isDisposed]: True after dispose() is called. No operations allowed.
/// - [_isActive]: True when actively in a call. Guards socket event handlers.
/// - [cleanup()]: Clears call resources but keeps service usable for new calls.
/// - [dispose()]: Final cleanup - closes all controllers, detaches all listeners.
class MediasoupService {
  final SocketService socketService;
  final String userId;
  final String userName;

  // ============================================
  // LIFECYCLE FLAGS
  // ============================================

  /// True when dispose() has been called. All operations should check this.
  bool _isDisposed = false;

  /// True when actively in a call session. Guards socket event handlers.
  bool _isActive = false;

  /// Tracks if cleanup is in progress to prevent re-entry.
  bool _isCleaningUp = false;
bool _audioProduced = false;
bool _videoProduced = false;

// Completers to track when producers are fully created on the backend (server ACK)
Completer<String?>? _audioProducerCompleter;
Completer<String?>? _videoProducerCompleter;

// Completers to track when producer is fully created LOCALLY (including SDP negotiation)
// This is critical - we must wait for producerCallback before starting next produce
Completer<void>? _audioProducerLocalCompleter;
Completer<void>? _videoProducerLocalCompleter;

  // ============================================
  // MEDIASOUP STATE
  // ============================================

  Device? _device;
  Transport? _sendTransport;
  Transport? _recvTransport;
  MediaStream? _localStream;
  final Map<String, MediaStream> _remoteStreams = {};
  final Map<String, String> _participantNames = {};
  final Map<String, RemoteParticipantStatus> _remoteParticipantStatus = {};

  // Producers and consumers - using Map like web implementation for reliable lookup
  final Map<String, Producer> _producers = {}; // 'audio' or 'video' -> Producer
  final Map<String, Consumer> _consumers = {};
  final Map<String, Map<String, dynamic>> _producerToPeer = {};

  // Pending consumers queue (for producers that arrive before device is ready)
  final List<Map<String, dynamic>> _pendingConsumers = [];

  // Pending tracks for peers whose stream is being created (fixes async race condition)
  final Map<String, List<MediaStreamTrack>> _pendingTracks = {};
  final Set<String> _streamCreationInProgress = {};

  // ============================================
  // CALL STATE
  // ============================================

  bool _isInCall = false;
  bool _isConnecting = false;
  String? _currentCallId;
  String? _currentRoomId; // Used for tracking current room
  String? _peerId;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true; // Track current camera facing mode
  bool _isTransportsReady = false;
  int _participantCount = 0; // Per reference: track participant count

  // ============================================
  // STREAM CONTROLLERS (all broadcast for multiple listeners)
  // ============================================

  final _localStreamController = StreamController<MediaStream?>.broadcast();
  final _remoteStreamsController =
      StreamController<Map<String, MediaStream>>.broadcast();
  final _participantNamesController =
      StreamController<Map<String, String>>.broadcast();
  final _remoteParticipantStatusController =
      StreamController<Map<String, RemoteParticipantStatus>>.broadcast();
  final _callStateController = StreamController<bool>.broadcast();
  final _connectingController = StreamController<bool>.broadcast();
  final _mutedController = StreamController<bool>.broadcast();
  final _videoOffController = StreamController<bool>.broadcast();
  final _frontCameraController = StreamController<bool>.broadcast();
  final _participantCountController = StreamController<int>.broadcast();

  // ============================================
  // SAVED SOCKET CALLBACKS (for detachment)
  // ============================================

  Function(Map<String, dynamic>)? _savedOnNewProducer;
  Function(Map<String, dynamic>)? _savedOnProducerPaused;
  Function(Map<String, dynamic>)? _savedOnProducerResumed;
  Function(Map<String, dynamic>)? _savedOnParticipantJoined;
  Function(Map<String, dynamic>)? _savedOnParticipantLeft;
  Function(Map<String, dynamic>)? _savedOnPeerClosed;
  Function(Map<String, dynamic>)? _savedOnProducerClosed;
  Function(Map<String, dynamic>)? _savedOnCameraSwitched;
  Function(Map<String, dynamic>)? _savedOnCallEnded;

  // ============================================
  // STREAM GETTERS
  // ============================================

  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;
  Stream<Map<String, MediaStream>> get remoteStreamsStream =>
      _remoteStreamsController.stream;
  Stream<Map<String, String>> get participantNamesStream =>
      _participantNamesController.stream;
  Stream<Map<String, RemoteParticipantStatus>>
  get remoteParticipantStatusStream =>
      _remoteParticipantStatusController.stream;
  Stream<bool> get callStateStream => _callStateController.stream;
  Stream<bool> get connectingStream => _connectingController.stream;
  Stream<bool> get mutedStream => _mutedController.stream;
  Stream<bool> get videoOffStream => _videoOffController.stream;
  Stream<bool> get frontCameraStream => _frontCameraController.stream;
  Stream<int> get participantCountStream => _participantCountController.stream;

  // ============================================
  // STATE GETTERS
  // ============================================

  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams =>
      Map.unmodifiable(_remoteStreams);
  Map<String, String> get participantNames =>
      Map.unmodifiable(_participantNames);
  Map<String, RemoteParticipantStatus> get remoteParticipantStatus =>
      Map.unmodifiable(_remoteParticipantStatus);
  bool get isInCall => _isInCall;
  bool get isConnecting => _isConnecting;
  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;
  bool get isFrontCamera => _isFrontCamera;
  String? get currentRoomId => _currentRoomId;
  String? get currentCallId => _currentCallId;
  bool get isDisposed => _isDisposed;
  bool get isActive => _isActive;
  int get participantCount => _participantCount;

  MediasoupService({
    required this.socketService,
    required this.userId,
    required this.userName,
  }) {
    _setupEventListeners();
  }

  // ============================================
  // SAFE STREAM CONTROLLER ADD
  // ============================================

  /// Safely adds an event to a StreamController, checking lifecycle flags first.
  /// Returns true if the event was added, false if it was skipped.
  bool _safeAdd<T>(StreamController<T> controller, T value) {
    if (_isDisposed) {
      debugPrint(
        '⚠️ MediasoupService: Skipping stream add - service is disposed',
      );
      return false;
    }
    if (controller.isClosed) {
      debugPrint(
        '⚠️ MediasoupService: Skipping stream add - controller is closed',
      );
      return false;
    }
    controller.add(value);
    return true;
  }

  // ============================================
  // LIFECYCLE GUARD
  // ============================================

  /// Checks if the service can process events. Returns false if disposed or not active.
  bool _canProcessEvents() {
    if (_isDisposed) {
      debugPrint(
        '⚠️ MediasoupService: Cannot process events - service is disposed',
      );
      return false;
    }
    if (!_isActive) {
      debugPrint(
        '⚠️ MediasoupService: Cannot process events - service is not active',
      );
      return false;
    }
    return true;
  }

  // ============================================
  // SOCKET EVENT LISTENERS
  // ============================================

  /// Setup socket event listeners for call events
  void _setupEventListeners() {
    // Save references to callbacks so we can detach them later

    _savedOnNewProducer = (data) async {
      if (!_canProcessEvents()) return;

      debugPrint('📢 NEW PRODUCER EVENT: $data');
      final producerData = NewProducerData.fromJson(data);

      // Store producer to peer mapping
      if (producerData.peerId.isNotEmpty) {
        _producerToPeer[producerData.producerId] = {
          'peerId': producerData.peerId,
          'kind': producerData.kind,
          'mediaType': producerData.mediaType,
        };
        debugPrint(
          '🔗 Mapped producer ${producerData.producerId} to peer ${producerData.peerId} (${producerData.kind})',
        );
      }

      // Store participant name
      if (producerData.userName != null) {
        _participantNames[producerData.peerId] =
            producerData.userName ?? 'Participant';
        _safeAdd(
          _participantNamesController,
          Map<String, String>.from(_participantNames),
        );
      }

      // Initialize or update remote participant status
      // Per reference: handle initial paused state (usually false for new producers)
      final existingStatus = _remoteParticipantStatus[producerData.peerId];
      if (existingStatus != null) {
        // Update existing status with paused state if producer started muted
        if (producerData.paused) {
          _updateParticipantMuteState(
            producerData.peerId,
            producerData.kind,
            true,
          );
        }
        // Update camera facing for video producers
        if (producerData.kind == 'video' && producerData.isFrontCamera != null) {
          _remoteParticipantStatus[producerData.peerId] = existingStatus.copyWith(
            isFrontCamera: producerData.isFrontCamera,
            isMobile: true, // If isFrontCamera is provided, it's a mobile device
          );
          _safeAdd(
            _remoteParticipantStatusController,
            Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
          );
        }
      } else {
        // Create new status
        _remoteParticipantStatus[producerData.peerId] = RemoteParticipantStatus(
          peerId: producerData.peerId,
          name: producerData.userName ?? 'Participant',
          isAudioMuted: producerData.kind == 'audio' && producerData.paused,
          isVideoOff: producerData.kind == 'video' && producerData.paused,
          isFrontCamera: producerData.isFrontCamera ?? true,
          isMobile: producerData.isFrontCamera != null, // Mobile if camera info provided
        );
        _safeAdd(
          _remoteParticipantStatusController,
          Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
        );
      }

      // Log paused state if applicable
      if (producerData.paused) {
        debugPrint(
          'Producer ${producerData.producerId} (${producerData.kind}) started in muted state',
        );
      }

      // Queue or consume the producer
      if (_isTransportsReady && _recvTransport != null) {
        await _consumeProducer(producerData.producerId, producerData.peerId);
      } else {
        debugPrint(
          '⚠️ Transport not ready, queueing producer: ${producerData.producerId}',
        );
        _pendingConsumers.add({
          'producerId': producerData.producerId,
          'peerId': producerData.peerId,
        });
      }
    };

    _savedOnProducerPaused = (data) {
      if (!_canProcessEvents()) return;

      debugPrint('🔇 Producer paused: $data');
      final statusData = ProducerStatusData.fromJson(data);
      _handleProducerStatusChange(statusData, isPaused: true);
    };

    _savedOnProducerResumed = (data) {
      if (!_canProcessEvents()) return;

      debugPrint('🔊 Producer resumed: $data');
      final statusData = ProducerStatusData.fromJson(data);
      _handleProducerStatusChange(statusData, isPaused: false);
    };

    // Per reference: participantJoined includes { callId, userId, currentParticipants }
    _savedOnParticipantJoined = (data) {
      if (!_canProcessEvents()) return;

      debugPrint('👥 Participant joined: $data');
      final participantData = ParticipantJoinedData.fromJson(data);

      // Use authoritative count from backend (prevents sync issues on rejoin)
      _participantCount = participantData.currentParticipants;
      _safeAdd(_participantCountController, _participantCount);

      debugPrint(
        'Participant ${participantData.userId} joined. Total: ${participantData.currentParticipants}',
      );
    };

    // Per reference: participantLeft includes { callId, userId, remainingParticipants }
    _savedOnParticipantLeft = (data) {
      if (!_canProcessEvents()) return;

      debugPrint('👋 Participant left: $data');
      final participantData = ParticipantLeftData.fromJson(data);

      // Use authoritative count from backend
      _participantCount = participantData.remainingParticipants;
      _safeAdd(_participantCountController, _participantCount);

      debugPrint(
        'Participant ${participantData.userId} left. Remaining: ${participantData.remainingParticipants}',
      );

      // Also handle cleanup via ParticipantEventData for backward compatibility
      _handleParticipantLeft(ParticipantEventData(
        peerId: participantData.peerId,
        userId: participantData.userId,
      ));
    };

    _savedOnPeerClosed = (data) {
      if (!_canProcessEvents()) return;

      debugPrint('🚪 Peer closed: $data');
      final participantData = ParticipantEventData.fromJson(data);
      _handleParticipantLeft(participantData);
    };

    _savedOnProducerClosed = (data) {
      if (!_canProcessEvents()) return;

      debugPrint('🔌 Producer closed: $data');
      final statusData = ProducerStatusData.fromJson(data);
      _handleProducerClosed(statusData);
    };

    _savedOnCameraSwitched = (data) {
      if (!_canProcessEvents()) return;

      debugPrint('📷 Camera switched by remote: $data');
      final peerId = data['peerId'] as String?;
      final isFrontCamera = data['isFrontCamera'] as bool? ?? true;

      if (peerId != null && _remoteParticipantStatus.containsKey(peerId)) {
        _remoteParticipantStatus[peerId] = _remoteParticipantStatus[peerId]!.copyWith(
          isFrontCamera: isFrontCamera,
        );
        _safeAdd(
          _remoteParticipantStatusController,
          Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
        );
        debugPrint('📷 Updated camera status for $peerId: isFrontCamera=$isFrontCamera');
      }
    };

    _savedOnCallEnded = (data) {
      // Allow call ended even if not active, but not if disposed
      if (_isDisposed) {
        return;
      }

      debugPrint('🛑 Call ended: $data');
      cleanup();
    };

    // Attach listeners to socket service
    _attachSocketListeners();
  }

  /// Attach socket event listeners
  void _attachSocketListeners() {
    socketService.onNewProducer = _savedOnNewProducer;
    socketService.onProducerPaused = _savedOnProducerPaused;
    socketService.onProducerResumed = _savedOnProducerResumed;
    socketService.onParticipantJoined = _savedOnParticipantJoined;
    socketService.onParticipantLeft = _savedOnParticipantLeft;
    socketService.onPeerClosed = _savedOnPeerClosed;
    socketService.onProducerClosed = _savedOnProducerClosed;
    socketService.onCameraSwitched = _savedOnCameraSwitched;
    socketService.onCallEnded = _savedOnCallEnded;

    debugPrint('✅ MediasoupService: Socket listeners attached');
  }

  /// Detach socket event listeners (called during cleanup, not dispose)
  void _detachSocketListeners() {
    // Only null out our callbacks, don't affect other potential listeners
    if (socketService.onNewProducer == _savedOnNewProducer) {
      socketService.onNewProducer = null;
    }
    if (socketService.onProducerPaused == _savedOnProducerPaused) {
      socketService.onProducerPaused = null;
    }
    if (socketService.onProducerResumed == _savedOnProducerResumed) {
      socketService.onProducerResumed = null;
    }
    if (socketService.onParticipantJoined == _savedOnParticipantJoined) {
      socketService.onParticipantJoined = null;
    }
    if (socketService.onParticipantLeft == _savedOnParticipantLeft) {
      socketService.onParticipantLeft = null;
    }
    if (socketService.onPeerClosed == _savedOnPeerClosed) {
      socketService.onPeerClosed = null;
    }
    if (socketService.onProducerClosed == _savedOnProducerClosed) {
      socketService.onProducerClosed = null;
    }
    if (socketService.onCameraSwitched == _savedOnCameraSwitched) {
      socketService.onCameraSwitched = null;
    }
    if (socketService.onCallEnded == _savedOnCallEnded) {
      socketService.onCallEnded = null;
    }

    debugPrint('✅ MediasoupService: Socket listeners detached');
  }

  // ============================================
  // EVENT HANDLERS
  // ============================================

  /// Handle producer status change (muted/unmuted)
  /// Per reference: producerPaused/Resumed includes { userId, kind, mediaType, userName }
  void _handleProducerStatusChange(
    ProducerStatusData data, {
    required bool isPaused,
  }) {
    if (_isDisposed) return;

    final mapping = _producerToPeer[data.producerId];
    String? kind = mapping?['kind'] ?? data.kind;
    String? peerId = mapping?['peerId'] ?? data.peerId;

    // Per reference: use userId to identify the participant
    // Try to find peer by userId if peerId is not available
    if (peerId == null && data.userId != null) {
      // Search for peer with matching userId
      for (final entry in _remoteParticipantStatus.entries) {
        if (entry.key.contains(data.userId!)) {
          peerId = entry.key;
          break;
        }
      }
    }

    // Update participant name if provided
    if (peerId != null && data.userName != null) {
      _participantNames[peerId] = data.userName!;
      _safeAdd(
        _participantNamesController,
        Map<String, String>.from(_participantNames),
      );
    }

    if (peerId != null && _remoteParticipantStatus.containsKey(peerId)) {
      final status = _remoteParticipantStatus[peerId]!;
      if (kind == 'audio') {
        _remoteParticipantStatus[peerId] = status.copyWith(
          isAudioMuted: isPaused,
          name: data.userName ?? status.name,
        );
        debugPrint(
          '${data.userName ?? peerId} ${isPaused ? "muted" : "unmuted"} audio',
        );
      } else if (kind == 'video') {
        _remoteParticipantStatus[peerId] = status.copyWith(
          isVideoOff: isPaused,
          name: data.userName ?? status.name,
        );
        debugPrint(
          '${data.userName ?? peerId} ${isPaused ? "turned off" : "turned on"} video',
        );
      }
      _safeAdd(
        _remoteParticipantStatusController,
        Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
      );
    }
  }

  /// Handle participant left (matches web implementation)
  /// Collects all possible peer IDs from peerId and userId, then removes all matching entries
  void _handleParticipantLeft(ParticipantEventData data) {
    if (_isDisposed) return;

    // Collect all possible peer IDs to try (matches web implementation)
    final Set<String> peerIdsToRemove = {};

    // Add peerId from event data if available
    if (data.peerId != null && data.peerId!.isNotEmpty) {
      peerIdsToRemove.add(data.peerId!);
    }

    // If we have userId, look for peer IDs that contain this userId (matches web)
    if (data.userId != null && data.userId!.isNotEmpty) {
      final eventUserId = data.userId!;

      // Check remoteStreams for matching peer IDs
      for (final peerId in _remoteStreams.keys) {
        if (peerId.contains(eventUserId) || peerId.startsWith(eventUserId)) {
          peerIdsToRemove.add(peerId);
        }
      }

      // Check participantNames for matching peer IDs
      for (final peerId in _participantNames.keys) {
        if (peerId.contains(eventUserId) || peerId.startsWith(eventUserId)) {
          peerIdsToRemove.add(peerId);
        }
      }

      // Check remoteParticipantStatus for matching peer IDs
      for (final peerId in _remoteParticipantStatus.keys) {
        if (peerId.contains(eventUserId) || peerId.startsWith(eventUserId)) {
          peerIdsToRemove.add(peerId);
        }
      }

      // Check producer-to-peer mappings
      for (final entry in _producerToPeer.entries) {
        final peerId = entry.value['peerId'] as String?;
        if (peerId != null && (peerId.contains(eventUserId) || peerId.startsWith(eventUserId))) {
          peerIdsToRemove.add(peerId);
        }
      }
    }

    debugPrint('🎯 [participantLeft] Peer IDs to remove: $peerIdsToRemove');

    if (peerIdsToRemove.isEmpty) {
      debugPrint('⚠️ [participantLeft] No matching peer IDs found for: ${data.toJson()}');
      return;
    }

    // Remove all matching peer IDs
    for (final peerId in peerIdsToRemove) {
      debugPrint('🗑️ Cleaning up peer: $peerId');

      // Close consumers for this peer
      _consumers.removeWhere((consumerId, consumer) {
        if (consumer.appData['peerId'] == peerId) {
          consumer.close();
          debugPrint('🗑️ [participantLeft] Closed consumer $consumerId for peer: $peerId');
          return true;
        }
        return false;
      });

      // Remove from remote streams
      if (_remoteStreams.containsKey(peerId)) {
        _remoteStreams[peerId]?.dispose();
        _remoteStreams.remove(peerId);
        debugPrint('🗑️ [participantLeft] Removed stream for peer: $peerId, remaining: ${_remoteStreams.length}');
      }

      // Remove from participant names
      if (_participantNames.containsKey(peerId)) {
        _participantNames.remove(peerId);
        debugPrint('🗑️ [participantLeft] Removed name for peer: $peerId');
      }

      // Remove from participant status
      if (_remoteParticipantStatus.containsKey(peerId)) {
        _remoteParticipantStatus.remove(peerId);
        debugPrint('🗑️ [participantLeft] Removed status for peer: $peerId');
      }

      // Remove from producer-to-peer mappings
      final producersToRemove = <String>[];
      for (final entry in _producerToPeer.entries) {
        if (entry.value['peerId'] == peerId) {
          producersToRemove.add(entry.key);
        }
      }
      for (final producerId in producersToRemove) {
        _producerToPeer.remove(producerId);
        debugPrint('🗑️ [participantLeft] Removed producer mapping: $producerId');
      }
    }

    // Emit updated state
    _safeAdd(
      _remoteStreamsController,
      Map<String, MediaStream>.from(_remoteStreams),
    );
    _safeAdd(
      _participantNamesController,
      Map<String, String>.from(_participantNames),
    );
    _safeAdd(
      _remoteParticipantStatusController,
      Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
    );
  }

  /// Handle producer closed
  void _handleProducerClosed(ProducerStatusData data) {
    if (_isDisposed) return;

    final mapping = _producerToPeer[data.producerId];
    final peerId = mapping?['peerId'] ?? data.peerId;

    _producerToPeer.remove(data.producerId);

    if (peerId != null) {
      final hasRemainingProducers = _producerToPeer.values.any(
        (mapping) => mapping['peerId'] == peerId,
      );

      if (!hasRemainingProducers) {
        _consumers.removeWhere((consumerId, consumer) {
          if (consumer.appData['peerId'] == peerId) {
            consumer.close();
            return true;
          }
          return false;
        });

        _remoteStreams[peerId]?.dispose();
        _remoteStreams.remove(peerId);
        _participantNames.remove(peerId);
        _remoteParticipantStatus.remove(peerId);
        _safeAdd(
          _remoteStreamsController,
          Map<String, MediaStream>.from(_remoteStreams),
        );
        _safeAdd(
          _participantNamesController,
          Map<String, String>.from(_participantNames),
        );
        _safeAdd(
          _remoteParticipantStatusController,
          Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
        );
      }
    }
  }

  /// Helper function to update participant mute state
  /// Per reference: Update UI to show muted indicator for this user
  void _updateParticipantMuteState(String peerId, String kind, bool isMuted) {
    if (_isDisposed) return;

    if (_remoteParticipantStatus.containsKey(peerId)) {
      final status = _remoteParticipantStatus[peerId]!;
      if (kind == 'audio') {
        _remoteParticipantStatus[peerId] = status.copyWith(
          isAudioMuted: isMuted,
        );
      } else if (kind == 'video') {
        _remoteParticipantStatus[peerId] = status.copyWith(
          isVideoOff: isMuted,
        );
      }
      _safeAdd(
        _remoteParticipantStatusController,
        Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
      );
    }
  }

  // ============================================
  // PERMISSIONS & MEDIA
  // ============================================

  /// Request camera and microphone permissions
  Future<bool> requestPermissions(CallType callType) async {
    if (_isDisposed) return false;

    try {
      debugPrint('🔐 Requesting permissions for ${callType.name} call...');

      if (callType == CallType.video) {
        debugPrint('📸 Requesting camera permission...');
        final cameraStatus = await Permission.camera.request();
        debugPrint('📸 Camera permission: ${cameraStatus.name}');

        debugPrint('🎤 Requesting microphone permission...');
        final micStatus = await Permission.microphone.request();
        debugPrint('🎤 Microphone permission: ${micStatus.name}');

        final granted = cameraStatus.isGranted && micStatus.isGranted;
        debugPrint(
          granted ? '✅ All permissions granted' : '❌ Some permissions denied',
        );
        return granted;
      } else {
        debugPrint('🎤 Requesting microphone permission...');
        final micStatus = await Permission.microphone.request();
        debugPrint('🎤 Microphone permission: ${micStatus.name}');

        final granted = micStatus.isGranted;
        debugPrint(
          granted
              ? '✅ Microphone permission granted'
              : '❌ Microphone permission denied',
        );
        return granted;
      }
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Get user media stream
  Future<MediaStream?> getUserMedia(CallType callType) async {
    if (_isDisposed) return null;

    try {
      debugPrint('🎥 Getting user media for ${callType.name} call...');

      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': callType == CallType.video
            ? {
                'facingMode': _isFrontCamera ? 'user' : 'environment',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      debugPrint('🔧 Media constraints: $mediaConstraints');

      try {
        final stream = await navigator.mediaDevices.getUserMedia(
          mediaConstraints,
        );
        debugPrint('✅ Got user media stream: ${stream.id}');
        debugPrint('   - Audio tracks: ${stream.getAudioTracks().length}');
        debugPrint('   - Video tracks: ${stream.getVideoTracks().length}');
        return stream;
      } catch (e) {
        debugPrint('⚠️ Failed with ideal constraints, trying basic: $e');

        // Fallback to basic constraints
        final basicConstraints = {
          'audio': true,
          'video': callType == CallType.video,
        };

        try {
          final stream = await navigator.mediaDevices.getUserMedia(
            basicConstraints,
          );
          debugPrint(
            '✅ Got user media stream with basic constraints: ${stream.id}',
          );
          return stream;
        } catch (fallbackError) {
          debugPrint(
            '❌ Failed to get video, trying audio-only: $fallbackError',
          );

          // Last resort: audio only
          final audioStream = await navigator.mediaDevices.getUserMedia({
            'audio': true,
            'video': false,
          });
          debugPrint('🎤 Falling back to audio-only stream');
          return audioStream;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting user media: $e');
      return null;
    }
  }

  // ============================================
  // DEVICE & TRANSPORT INITIALIZATION
  // ============================================

  /// Initialize mediasoup device
  Future<bool> _initializeDevice(
    Map<String, dynamic> routerRtpCapabilities,
  ) async {
    if (_isDisposed) return false;

    try {
      debugPrint('🔧 Initializing mediasoup device...');

      _device = Device();

      // Load the device with router RTP capabilities
      await _device!.load(
        routerRtpCapabilities: RtpCapabilities.fromMap(routerRtpCapabilities),
      );

      debugPrint('✅ Device initialized successfully');
      debugPrint(
        '   - Can produce audio: ${_device!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio)}',
      );
      debugPrint(
        '   - Can produce video: ${_device!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo)}',
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error initializing device: $e');
      return false;
    }
  }

  /// Get router RTP capabilities from server
  Future<Map<String, dynamic>?> _getRouterRtpCapabilities(String roomId) async {
    if (_isDisposed) return null;

    try {
      debugPrint('🔧 Getting router RTP capabilities for room: $roomId');
      final completer = Completer<Map<String, dynamic>?>();

      socketService.getRouterRtpCapabilities({'roomId': roomId}, (response) {
        if (_isDisposed) {
          completer.complete(null);
          return;
        }

        if (response['rtpCapabilities'] != null) {
          debugPrint('✅ Got router RTP capabilities');
          completer.complete(
            Map<String, dynamic>.from(response['rtpCapabilities']),
          );
        } else {
          debugPrint('❌ No RTP capabilities in response');
          completer.complete(null);
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Timeout getting RTP capabilities');
          return null;
        },
      );
    } catch (e) {
      debugPrint('❌ Error getting RTP capabilities: $e');
      return null;
    }
  }

  /// Join mediasoup room
  Future<Map<String, dynamic>?> _joinRoom(String roomId, String peerId) async {
    if (_isDisposed) return null;

    try {
      debugPrint('🚪 Joining mediasoup room...');
      debugPrint('   - Room ID: $roomId');
      debugPrint('   - Peer ID: $peerId');
      debugPrint('   - User ID: $userId');
      debugPrint('   - User Name: $userName');

      final completer = Completer<Map<String, dynamic>?>();

      socketService.joinRoom(
        {
          'roomId': roomId,
          'peerId': peerId,
          'userId': userId,
          'userName': userName,
        },
        (response) {
          if (_isDisposed) {
            completer.complete(null);
            return;
          }

          debugPrint('✅ Joined mediasoup room successfully');
          debugPrint('   - Response: $response');
          _peerId = peerId;
          completer.complete(Map<String, dynamic>.from(response));
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Timeout joining room');
          return null;
        },
      );
    } catch (e) {
      debugPrint('❌ Error joining room: $e');
      return null;
    }
  }

  /// Create send transport
  Future<bool> _createSendTransport() async {
    if (_isDisposed) return false;

    try {
      debugPrint('🔧 Creating send transport...');

      final completer = Completer<bool>();

      socketService.createWebRtcTransport({'direction': 'send'}, (
        transportOptions,
      ) async {
        if (_isDisposed) {
          completer.complete(false);
          return;
        }

        try {
          debugPrint('📦 Received send transport options: $transportOptions');

          final Map<String, dynamic> options = Map<String, dynamic>.from(
            transportOptions,
          );

          _sendTransport = _device!.createSendTransportFromMap(
            options,
            // producerCallback is called AFTER producer is FULLY created locally
            // Including SDP negotiation completion - this is critical for sequencing
            // 🔥 FIX: Library only passes (Producer), not (Producer, Map)!
            producerCallback: (Producer producer) {
                  if (_isDisposed) return;

                  debugPrint('🔍 Producer callback - producer FULLY created (SDP done)');
                  debugPrint('   - producer.id: ${producer.id}');
                  debugPrint('   - producer.kind: ${producer.kind}');
                  debugPrint('   - producer.track?.kind: ${producer.track?.kind}');

                  // Determine kind
                  String kindStr;
                  if (producer.track?.kind == 'audio') {
                    kindStr = 'audio';
                  } else if (producer.track?.kind == 'video') {
                    kindStr = 'video';
                  } else if (producer.kind.toString().toLowerCase().contains('audio')) {
                    kindStr = 'audio';
                  } else {
                    kindStr = 'video';
                  }

                  // Store producer in Map (like web: producersRef.current.set("audio", audioProducer))
                  _producers[kindStr] = producer;
                  debugPrint('✅ ${kindStr.toUpperCase()} producer stored in _producers Map');

                  // 🔥 CRITICAL: Complete the local completer to signal producer is FULLY ready
                  // This allows the next produce() to start only after SDP negotiation is complete
                  if (kindStr == 'audio') {
                    if (_audioProducerLocalCompleter != null && !_audioProducerLocalCompleter!.isCompleted) {
                      _audioProducerLocalCompleter!.complete();
                      debugPrint('🔔 Audio producer LOCAL completer completed (SDP done)');
                    }
                  } else {
                    if (_videoProducerLocalCompleter != null && !_videoProducerLocalCompleter!.isCompleted) {
                      _videoProducerLocalCompleter!.complete();
                      debugPrint('🔔 Video producer LOCAL completer completed (SDP done)');
                    }
                  }
                },
          );

          // 🔥 CRITICAL: Register event listeners in the same order as the working example
          // Order: 1) connect, 2) produce, 3) connectionstatechange

          // 1) Handle transport connect event FIRST (matches working example order)
          _sendTransport!.on('connect', (Map data) {
            if (_isDisposed) return;

            debugPrint('🔗 Send transport connecting...');
            final dtlsParameters = data['dtlsParameters'] as DtlsParameters;
            final callback = data['callback'] as Function;

            socketService.connectWebRtcTransport(
              {
                'transportId': _sendTransport!.id,
                'dtlsParameters': dtlsParameters.toMap(),
              },
              () {
                debugPrint('✅ Send transport connected');
                callback();
              },
            );
          });

          // 🔍 DEBUG: Verify connect listener registration
          final connectListeners = _sendTransport!.listeners('connect');
          debugPrint('✅ Connect event listener attached');
          debugPrint('   🔍 Registered connect listeners count: ${connectListeners.length}');

          // 2) Handle transport produce event (this is REQUIRED by the library)
          // This is equivalent to web's: transport.on("produce", async ({ kind, rtpParameters, appData }, callback, errback) => {...})
          _sendTransport!.on('produce', (Map data) async {
            if (_isDisposed) return;

            debugPrint('📤 Transport "produce" event fired');
            final kind = data['kind'] as String?;
            final rtpParameters = data['rtpParameters'];
            final appData = data['appData'] as Map<String, dynamic>?;
            final callback = data['callback'] as Function?;
            final errback = data['errback'] as Function?;

            debugPrint('   - Kind: $kind');
            debugPrint('   - Has callback: ${callback != null}');
            debugPrint('   - Has errback: ${errback != null}');

            if (kind == null) {
              debugPrint('❌ produce event missing kind');
              errback?.call(Exception('Missing kind'));
              return;
            }

            try {
              // Emit to server - exactly like web does
              // 🔥 FIX: Use same mediaType values as web: 'audio' and 'camera'
              socketService.produce(
                {
                  'transportId': _sendTransport!.id,
                  'kind': kind,
                  'rtpParameters': rtpParameters is RtpParameters
                      ? rtpParameters.toMap()
                      : rtpParameters,
                  'appData': {
                    'mediaType': kind == 'audio' ? 'audio' : 'camera',
                    'peerId': _peerId,
                    'userId': userId,
                    'userName': userName,
                    if (kind == 'video') 'isFrontCamera': _isFrontCamera,
                    ...?(appData),
                  },
                },
                (response) {
                  final producerId = response['id'] as String;
                  debugPrint('✅ Server returned producer ID: $producerId');

                  // 🔥 CRITICAL FIX: Pass just the string ID, not a map
                  // The library expects: callback(producerId) not callback({'id': producerId})
                  // This matches the working example: data['callback'](response['id'])
                  callback?.call(producerId);

                  // Complete ACK completers
                  if (kind == 'audio') {
                    if (_audioProducerCompleter != null && !_audioProducerCompleter!.isCompleted) {
                      _audioProducerCompleter!.complete(producerId);
                      debugPrint('🔔 Audio producer ACK completed');
                    }
                  } else {
                    if (_videoProducerCompleter != null && !_videoProducerCompleter!.isCompleted) {
                      _videoProducerCompleter!.complete(producerId);
                      debugPrint('🔔 Video producer ACK completed');
                    }
                  }
                },
              );
            } catch (e) {
              debugPrint('❌ Error in produce event handler: $e');
              errback?.call(e);
            }
          });

          // 🔍 DEBUG: Verify produce listener registration
          final produceListeners = _sendTransport!.listeners('produce');
          debugPrint('✅ Produce event listener attached to send transport');
          debugPrint('   🔍 Registered produce listeners count: ${produceListeners.length}');

          // 3) Handle transport connection state change
          _sendTransport!.on('connectionstatechange', (Map data) {
            final state = data['connectionState'];
            debugPrint('📡 Send transport connection state: $state');
          });

          debugPrint('✅ Send transport created: ${_sendTransport!.id}');
          completer.complete(true);
        } catch (e) {
          debugPrint('❌ Error creating send transport: $e');
          completer.complete(false);
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Timeout creating send transport');
          return false;
        },
      );
    } catch (e) {
      debugPrint('❌ Error in createSendTransport: $e');
      return false;
    }
  }

  /// Create receive transport
  Future<bool> _createRecvTransport() async {
    if (_isDisposed) return false;

    try {
      debugPrint('🔧 Creating receive transport...');

      final completer = Completer<bool>();

      socketService.createWebRtcTransport({'direction': 'recv'}, (
        transportOptions,
      ) async {
        if (_isDisposed) {
          completer.complete(false);
          return;
        }

        try {
          debugPrint('📦 Received recv transport options: $transportOptions');

          final Map<String, dynamic> options = Map<String, dynamic>.from(
            transportOptions,
          );

          _recvTransport = _device!.createRecvTransportFromMap(
            options,
            consumerCallback: (Consumer consumer, dynamic accept) {
              if (_isDisposed) {
                debugPrint('⚠️ Consumer callback ignored - service disposed');
                return;
              }

              debugPrint('📥 Consumer callback for: ${consumer.id}');
              debugPrint('   - Kind: ${consumer.kind}');
              debugPrint('   - Track: ${consumer.track}');
              debugPrint('   - AppData: ${consumer.appData}');

              // Accept the consumer first
              if (accept != null) {
                accept();
              }

              // Get peerId from appData
              final appData = consumer.appData;
              final peerId =
                  appData['peerId'] as String? ?? 'unknown-${consumer.id}';
              debugPrint('   - PeerId: $peerId');

              // Store the consumer
              _consumers[consumer.id] = consumer;
              debugPrint('✅ Consumer stored: ${consumer.id}');

              // Get the track from the consumer
              final track = consumer.track;

              // Enable the track for audio playback
              track.enabled = true;
              debugPrint('✅ Track enabled: ${track.id} (${track.kind})');

              // Handle stream creation with race condition protection
              _addTrackToRemoteStream(peerId, track);
            },
          );

          // Handle transport connect event
          _recvTransport!.on('connect', (Map data) {
            if (_isDisposed) return;

            debugPrint('🔗 Recv transport connecting...');
            final dtlsParameters = data['dtlsParameters'] as DtlsParameters;
            final callback = data['callback'] as Function;

            socketService.connectWebRtcTransport(
              {
                'transportId': _recvTransport!.id,
                'dtlsParameters': dtlsParameters.toMap(),
              },
              () {
                debugPrint('✅ Recv transport connected');
                callback();
              },
            );
          });

          // Handle transport connection state change
          _recvTransport!.on('connectionstatechange', (Map data) {
            final state = data['connectionState'];
            debugPrint('📡 Recv transport connection state: $state');
          });

          debugPrint('✅ Recv transport created: ${_recvTransport!.id}');
          completer.complete(true);
        } catch (e) {
          debugPrint('❌ Error creating recv transport: $e');
          completer.complete(false);
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Timeout creating recv transport');
          return false;
        },
      );
    } catch (e) {
      debugPrint('❌ Error in createRecvTransport: $e');
      return false;
    }
  }

  // ============================================
  // PRODUCE MEDIA
  // ============================================

  /// Produce audio track
  /// 🔥 CRITICAL FIX: Now waits for server ACK before returning
  /// This ensures the producer is fully registered on the backend
  /// and other participants can receive the newProducer event
  Future<void> _produceAudio() async {
    debugPrint('🎤 _produceAudio() called - checking guards...');
    debugPrint('   - _isDisposed: $_isDisposed');
    debugPrint('   - _audioProduced: $_audioProduced');
    debugPrint('   - _sendTransport: ${_sendTransport != null ? "EXISTS (id: ${_sendTransport!.id})" : "NULL"}');
    debugPrint('   - _localStream: ${_localStream != null ? "EXISTS (id: ${_localStream!.id})" : "NULL"}');

    if (_isDisposed) {
      debugPrint('❌ _produceAudio() returning - service is disposed');
      return;
    }

    // 🔥 CRITICAL GUARD
    if (_audioProduced) {
      debugPrint('ℹ️ Audio already produced, skipping');
      return;
    }

    if (_sendTransport == null) {
      debugPrint('❌ _produceAudio() returning - _sendTransport is NULL');
      return;
    }

    if (_localStream == null) {
      debugPrint('❌ _produceAudio() returning - _localStream is NULL');
      return;
    }

    final audioTracks = _localStream!.getAudioTracks();
    debugPrint('   - Audio tracks count: ${audioTracks.length}');
    if (audioTracks.isEmpty) {
      debugPrint('❌ _produceAudio() returning - No audio tracks available');
      return;
    }

    try {
      debugPrint('🎤 Producing audio track: ${audioTracks.first.id}');
      debugPrint('   - Track enabled: ${audioTracks.first.enabled}');
      debugPrint('   - Track muted: ${audioTracks.first.muted}');

      // 🔥 CRITICAL FIX: Create completers to wait for BOTH server ACK AND local SDP completion
      _audioProducerCompleter = Completer<String?>();
      _audioProducerLocalCompleter = Completer<void>();

      // 🔍 DEBUG: Verify listeners are still registered before produce()
      final produceListeners = _sendTransport!.listeners('produce');
      final connectListeners = _sendTransport!.listeners('connect');
      debugPrint('📤 Calling _sendTransport.produce()...');
      debugPrint('   🔍 Before produce - produce listeners: ${produceListeners.length}');
      debugPrint('   🔍 Before produce - connect listeners: ${connectListeners.length}');
      debugPrint('   🔍 Transport ID: ${_sendTransport!.id}');

      _sendTransport!.produce(
        track: audioTracks.first,
        stream: _localStream!,
        source: 'mic',
        codecOptions: ProducerCodecOptions(opusStereo: 1, opusDtx: 1),
        appData: {
          'peerId': _peerId,
          'userId': userId,
          'userName': userName,
        },
      );

      _audioProduced = true; // ✅ SET FLAG
      debugPrint('✅ Audio produce() called, waiting for LOCAL completion + server ACK...');

      // 🔥 CRITICAL FIX: Wait for BOTH:
      // 1. Local SDP negotiation to complete (producerCallback is called)
      // 2. Server ACK to come back
      // This prevents the next produce() from starting before this one's SDP is done

      // Wait for LOCAL completion first (SDP negotiation done)
      await _audioProducerLocalCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ TIMEOUT waiting for audio producer LOCAL completion after 10s');
        },
      );
      debugPrint('✅ Audio producer LOCAL completion done (SDP negotiated)');

      // Then wait for server ACK
      final producerId = await _audioProducerCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ TIMEOUT waiting for audio producer server ACK after 10s');
          return null;
        },
      );

      if (producerId != null) {
        debugPrint('✅ Audio producer fully registered on server: $producerId');
      } else {
        debugPrint('⚠️ Audio producer ACK returned null (timeout or error)');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error producing audio: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _audioProducerCompleter = null;
      _audioProducerLocalCompleter = null;
    }
  }


  /// Produce video track
  /// 🔥 CRITICAL FIX: Now waits for BOTH local SDP completion AND server ACK
  /// This ensures proper SDP negotiation sequencing and backend registration
  Future<void> _produceVideo() async {
    if (_isDisposed) return;

    if (_videoProduced) {
      debugPrint('ℹ️ Video already produced, skipping');
      return;
    }

    if (_sendTransport == null || _localStream == null) {
      debugPrint('⚠️ Cannot produce video - transport or stream not ready');
      return;
    }

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) {
      debugPrint('⚠️ No video tracks available');
      return;
    }

    try {
      debugPrint('📹 Producing video track...');

      // 🔥 CRITICAL FIX: Create completers to wait for BOTH local SDP AND server ACK
      _videoProducerCompleter = Completer<String?>();
      _videoProducerLocalCompleter = Completer<void>();

      _sendTransport!.produce(
        track: videoTracks.first,
        stream: _localStream!,
        source: 'webcam',
        codecOptions: ProducerCodecOptions(videoGoogleStartBitrate: 1000),
        appData: {'peerId': _peerId, 'userId': userId, 'userName': userName},
      );

      _videoProduced = true;
      debugPrint('✅ Video produce request sent, waiting for LOCAL completion + server ACK...');

      // Wait for LOCAL completion first (SDP negotiation done)
      await _videoProducerLocalCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ TIMEOUT waiting for video producer LOCAL completion after 10s');
        },
      );
      debugPrint('✅ Video producer LOCAL completion done (SDP negotiated)');

      // Then wait for server ACK
      final producerId = await _videoProducerCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Timeout waiting for video producer ACK');
          return null;
        },
      );

      if (producerId != null) {
        debugPrint('✅ Video producer fully registered on server: $producerId');
      } else {
        debugPrint('⚠️ Video producer ACK returned null (timeout or error)');
      }
    } catch (e) {
      debugPrint('❌ Error producing video: $e');
      _videoProducerCompleter = null;
      _videoProducerLocalCompleter = null;
    }
  }

  // ============================================
  // CONSUME MEDIA
  // ============================================

  /// Helper to parse RTCRtpMediaType from string
  RTCRtpMediaType _parseMediaType(String kind) {
    if (kind == 'audio') {
      return RTCRtpMediaType.RTCRtpMediaTypeAudio;
    } else {
      return RTCRtpMediaType.RTCRtpMediaTypeVideo;
    }
  }

  /// Add track to remote stream with race condition protection
  /// This handles the case where multiple tracks arrive before stream is created
  void _addTrackToRemoteStream(String peerId, MediaStreamTrack track) {
    if (_isDisposed) return;

    // Check if stream already exists
    final existingStream = _remoteStreams[peerId];
    if (existingStream != null) {
      // Stream exists, add track directly
      existingStream.addTrack(track);
      debugPrint('✅ Added ${track.kind} track to existing stream for peer $peerId');

      // Emit updated remote streams
      _safeAdd(
        _remoteStreamsController,
        Map<String, MediaStream>.from(_remoteStreams),
      );
      return;
    }

    // Check if stream creation is already in progress
    if (_streamCreationInProgress.contains(peerId)) {
      // Queue the track to be added when stream is ready
      _pendingTracks.putIfAbsent(peerId, () => []);
      _pendingTracks[peerId]!.add(track);
      debugPrint('⏳ Queued ${track.kind} track for peer $peerId (stream creation in progress)');
      return;
    }

    // Mark stream creation as in progress
    _streamCreationInProgress.add(peerId);
    debugPrint('🔧 Creating new remote stream for peer $peerId');

    // Create new MediaStream
    createLocalMediaStream('remote-$peerId').then((newStream) {
      if (_isDisposed) {
        _streamCreationInProgress.remove(peerId);
        return;
      }

      // Add the initial track
      newStream.addTrack(track);
      _remoteStreams[peerId] = newStream;
      debugPrint('✅ Created remote stream for peer $peerId with ${track.kind} track');

      // Add any pending tracks that arrived while stream was being created
      final pendingTracksForPeer = _pendingTracks.remove(peerId);
      if (pendingTracksForPeer != null && pendingTracksForPeer.isNotEmpty) {
        for (final pendingTrack in pendingTracksForPeer) {
          newStream.addTrack(pendingTrack);
          debugPrint('✅ Added pending ${pendingTrack.kind} track to stream for peer $peerId');
        }
      }

      // Mark stream creation as complete
      _streamCreationInProgress.remove(peerId);

      // Emit updated remote streams
      _safeAdd(
        _remoteStreamsController,
        Map<String, MediaStream>.from(_remoteStreams),
      );
    }).catchError((e) {
      debugPrint('❌ Error creating remote stream for peer $peerId: $e');
      _streamCreationInProgress.remove(peerId);
      _pendingTracks.remove(peerId);
    });
  }

  /// Consume a remote producer
  /// Per reference flow: consume → resumeConsumer
  Future<void> _consumeProducer(String producerId, String remotePeerId) async {
    if (_isDisposed) return;

    if (_recvTransport == null || _device == null) {
      debugPrint('⚠️ Cannot consume - transport or device not ready');
      return;
    }

    // Skip if already consuming this producer
    final existingConsumer = _consumers.values.where(
      (c) => c.appData['producerId'] == producerId,
    );
    if (existingConsumer.isNotEmpty) {
      debugPrint('ℹ️ Already consuming producer: $producerId');
      return;
    }

    try {
      debugPrint('🔊 Consuming producer: $producerId from peer: $remotePeerId');

      final completer = Completer<void>();

      // Per reference: consume uses { producerId, rtpCapabilities }
      socketService.consume(
        {
          'producerId': producerId,
          'rtpCapabilities': _device!.rtpCapabilities.toMap(),
        },
        (consumerOptions) async {
          if (_isDisposed) {
            completer.complete();
            return;
          }

          try {
            debugPrint('📦 Consumer options received: $consumerOptions');

            final Map<String, dynamic> options = Map<String, dynamic>.from(
              consumerOptions,
            );
            final String kind = options['kind'] as String;
            final String consumerId = options['id'] as String;
            final String consumerProducerId = options['producerId'] as String;

            debugPrint('🎬 Creating consumer: $consumerId ($kind) for peer: $remotePeerId');

            // consume() is synchronous and triggers consumerCallback
            _recvTransport!.consume(
              id: consumerId,
              producerId: consumerProducerId,
              peerId: remotePeerId,
              kind: _parseMediaType(kind),
              rtpParameters: RtpParameters.fromMap(
                Map<String, dynamic>.from(options['rtpParameters']),
              ),
              appData: {'peerId': remotePeerId, 'producerId': producerId, 'kind': kind},
            );

            debugPrint('✅ Consumer created on client: $consumerId ($kind)');

            // Small delay to ensure consumerCallback has processed the consumer
            await Future.delayed(const Duration(milliseconds: 100));

            // 🔥 CRITICAL: Resume consumer on server WITH ACK callback
            // Per reference: resumeConsumer uses { consumerId } and returns { resumed: true }
            final resumeCompleter = Completer<void>();
            socketService.resumeConsumer({'consumerId': consumerId}, (response) {
              if (response['resumed'] == true) {
                debugPrint('✅ resumeConsumer ACK received for: $consumerId ($kind)');

                // Re-emit remote streams to trigger UI update after resume
                if (!_isDisposed) {
                  _safeAdd(
                    _remoteStreamsController,
                    Map<String, MediaStream>.from(_remoteStreams),
                  );
                }
              } else {
                debugPrint('⚠️ resumeConsumer response: $response');
              }
              if (!resumeCompleter.isCompleted) {
                resumeCompleter.complete();
              }
            });

            // Wait for resume ACK with timeout
            await resumeCompleter.future.timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('⚠️ resumeConsumer ACK timeout for: $consumerId');
              },
            );

            completer.complete();
          } catch (e) {
            debugPrint('❌ Error creating consumer: $e');
            completer.completeError(e);
          }
        },
      );

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Timeout consuming producer: $producerId');
        },
      );
    } catch (e) {
      debugPrint('❌ Error consuming producer: $e');
    }
  }

  /// Process pending consumers
  Future<void> _processPendingConsumers() async {
    if (_isDisposed) return;
    if (_pendingConsumers.isEmpty) return;

    debugPrint('📦 Processing ${_pendingConsumers.length} pending consumers');
    final pending = List<Map<String, dynamic>>.from(_pendingConsumers);
    _pendingConsumers.clear();

    for (final item in pending) {
      if (_isDisposed) break;
      await _consumeProducer(item['producerId'], item['peerId']);
    }
  }

  // ============================================
  // START CALL
  // ============================================

  /// Start a new call
  ///
  /// IMPORTANT: roomId is generated using the chatGroup ID as the base,
  /// following the backend contract. This ensures consistent room identification.
  Future<String?> startCall({
    required String chatGroup,
    required CallType callType,
    String? incident,
  }) async {
    if (_isDisposed) {
      debugPrint('❌ Cannot start call - service is disposed');
      return null;
    }

    try {
      debugPrint('══════════════════════════════════════════');
      debugPrint('📞 STARTING NEW ${callType.name.toUpperCase()} CALL');
      debugPrint('══════════════════════════════════════════');
      debugPrint('📋 Call Details:');
      debugPrint('   - Chat Group: $chatGroup');
      debugPrint('   - Incident: ${incident ?? "none"}');
      debugPrint('   - User ID: $userId');
      debugPrint('   - User Name: $userName');
      debugPrint('   - Call Type: ${callType.name}');

      _isConnecting = true;
      _isActive = true; // Mark as active to allow socket event processing

      _safeAdd(_connectingController, true);

      // 🔥 STEP 0 (CRITICAL): Join socket room FIRST to not miss any events
      debugPrint('\n👥 STEP 0: Joining chat group FIRST (critical for socket events)...');
      socketService.joinGroup(chatGroup);
      debugPrint('✅ Joined chat group: $chatGroup');

      // Step 1: Request permissions
      debugPrint('\n🔐 STEP 1: Requesting permissions...');
      final hasPermissions = await requestPermissions(callType);
      if (!hasPermissions) {
        _isActive = false;
        throw Exception('Permissions not granted');
      }

      // Step 2: Get user media
      debugPrint('\n🎥 STEP 2: Getting user media...');
      // 🔒 Defensive cleanup (prevents camera lock on Android)
_localStream?.getTracks().forEach((t) {
  try { t.stop(); } catch (_) {}
});
_localStream?.dispose();
_localStream = null;

      final stream = await getUserMedia(callType);
      if (stream == null) {
        _isActive = false;
        throw Exception('Failed to get user media');
      }

      _localStream = stream;
      _safeAdd(_localStreamController, stream);
      debugPrint('✅ Local stream added to controller');

      // Generate room ID based on chatGroup (backend contract)
      // The roomId should be based on chatGroup to ensure consistency
      final roomId = chatGroup; // Use chatGroup as roomId per backend contract

      // 🔥 FIX: Use userId directly as peerId to match web implementation
      // Web: const peerId = userId (useMediasoup.ts line 624)
      // Mobile joinCall: final peerId = userId (line 1970)
      // This ensures consistent peer identification across platforms and prevents
      // the same user from being treated as different participants on reconnect
      final peerId = userId;
      _peerId = peerId;
      debugPrint('\n🆔 STEP 3: Generated IDs:');
      debugPrint('   - Room ID: $roomId (based on chatGroup)');
      debugPrint('   - Peer ID: $peerId (using userId directly per web implementation)');

      // Step 4: Get router RTP capabilities and initialize device
      debugPrint(
        '\n🔧 STEP 4: Getting RTP capabilities and initializing device...',
      );
      final rtpCapabilities = await _getRouterRtpCapabilities(roomId);
      if (rtpCapabilities == null) {
        _isActive = false;
        throw Exception('Failed to get RTP capabilities');
      }

      final deviceReady = await _initializeDevice(rtpCapabilities);
      if (!deviceReady) {
        _isActive = false;
        throw Exception('Failed to initialize device');
      }

      // Step 5: Start call on backend
      debugPrint('\n📡 STEP 5: Emitting startCall to server...');
      final completer = Completer<String?>();

      socketService.startCall(
        {
          'chatGroup': chatGroup,
          'incident': incident,
          'initiatedBy': userId,
          'callType': callType == CallType.audio ? 'audio' : 'video',
          'roomId': roomId,
        },
        (response) async {
          if (_isDisposed) {
            completer.complete(null);
            return;
          }

          debugPrint('📨 Server response received: $response');

          if (response['success'] == true) {
            _currentCallId = response['callId'];
            _currentRoomId =
                response['roomId'] ?? roomId; // Use server's roomId if provided
            final isExisting = response['isExisting'] == true;
            debugPrint(
              '✅ Call ${isExisting ? "joined (existing)" : "created (new)"} on server',
            );
            debugPrint('   - Call ID: $_currentCallId');
            debugPrint('   - Room ID: $_currentRoomId');
            debugPrint('   - Is Existing: $isExisting');

            try {
              // Step 7: Join room
              debugPrint('\n🚪 STEP 7: Joining mediasoup room...');
              final roomResponse = await _joinRoom(_currentRoomId!, peerId);

              // Step 8: Create transports
              debugPrint('\n🔧 STEP 8: Creating WebRTC transports...');
              final sendCreated = await _createSendTransport();
              final recvCreated = await _createRecvTransport();

              if (!sendCreated || !recvCreated) {
                _isActive = false;
                throw Exception('Failed to create transports');
              }

              _isTransportsReady = true;
              debugPrint('🚀 Both transports created and ready!');

              // Step 9: Produce media
              debugPrint('\n📤 STEP 9: Producing local media...');
              await _produceAudio();
              if (callType == CallType.video) {
                await _produceVideo();
              }

              // Step 10: Consume existing producers and handle their paused state
              debugPrint('\n📥 STEP 10: Consuming existing participants...');
              debugPrint('   🔍 Current userId: $userId, peerId: $peerId');
              if (roomResponse != null && roomResponse['producers'] != null) {
                final producers = roomResponse['producers'] as List;
                debugPrint('   Found ${producers.length} existing producers');
                for (final producer in producers) {
                  if (_isDisposed) break;
                  final producerId = producer['producerId'] as String?;
                  final remotePeerId =
                      producer['peerId'] as String? ?? 'unknown';
                  final paused = producer['paused'] as bool? ?? false;
                  final kind = producer['kind'] as String?;
                  final userName = producer['userName'] as String?;

                  debugPrint('   🔍 Processing producer: $producerId');
                  debugPrint('      - remotePeerId: $remotePeerId');
                  debugPrint('      - userName: $userName');
                  debugPrint('      - kind: $kind');

                  if (producerId != null) {
                    // 🔥 FIX: Skip our own producers - check if remotePeerId contains our userId
                    // Because peerId format can be either 'userId' or 'peer-userId-timestamp'
                    final isOwnProducer = remotePeerId == peerId ||
                                          remotePeerId == userId ||
                                          remotePeerId.contains(userId);

                    debugPrint('      - isOwnProducer: $isOwnProducer');

                    // Store participant name and status for OTHER participants only
                    if (userName != null && !isOwnProducer) {
                      _participantNames[remotePeerId] = userName;
                      debugPrint('   ✅ Stored participant name: $userName for peer: $remotePeerId');

                      // Initialize or update remote participant status
                      if (!_remoteParticipantStatus.containsKey(remotePeerId)) {
                        _remoteParticipantStatus[remotePeerId] = RemoteParticipantStatus(
                          peerId: remotePeerId,
                          name: userName,
                          isAudioMuted: kind == 'audio' && paused,
                          isVideoOff: kind == 'video' && paused,
                        );
                        debugPrint('   ✅ Created RemoteParticipantStatus for: $remotePeerId');
                      }
                    }

                    // Only consume producers from OTHER participants
                    if (!isOwnProducer) {
                      await _consumeProducer(producerId, remotePeerId);

                      // Handle initial paused state (e.g., user already muted)
                      if (paused && kind != null) {
                        debugPrint(
                          'Producer $producerId ($kind) is muted/paused',
                        );
                        _updateParticipantMuteState(remotePeerId, kind, true);
                      }
                    } else {
                      debugPrint('   ⏭️ Skipping own producer: $producerId');
                    }
                  }
                }

                // 🔥 FIX: Emit participant updates after processing all producers
                debugPrint('   📊 Final _participantNames: $_participantNames');
                debugPrint('   📊 Final _remoteParticipantStatus keys: ${_remoteParticipantStatus.keys.toList()}');
                _safeAdd(
                  _participantNamesController,
                  Map<String, String>.from(_participantNames),
                );
                _safeAdd(
                  _remoteParticipantStatusController,
                  Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
                );
                debugPrint('   ✅ Emitted participant names and status updates');
              } else {
                debugPrint('   No existing producers to consume');
              }

              // Process pending consumers
              await _processPendingConsumers();

              _isInCall = true;
              _isConnecting = false;
              _safeAdd(_callStateController, true);
              _safeAdd(_connectingController, false);

              debugPrint('\n✅ CALL STARTED SUCCESSFULLY');
              debugPrint('══════════════════════════════════════════\n');

              completer.complete(response['callId']);
            } catch (e) {
              debugPrint('❌ Error during call setup: $e');
              _isConnecting = false;
              _isActive = false;
              _safeAdd(_connectingController, false);
              completer.complete(null);
            }
          } else {
            debugPrint('❌ Server rejected call start: $response');
            _isConnecting = false;
            _isActive = false;
            _safeAdd(_connectingController, false);
            completer.complete(null);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('\n❌❌❌ ERROR STARTING CALL ❌❌❌');
      debugPrint('Error: $e');
      debugPrint('══════════════════════════════════════════\n');
      _isConnecting = false;
      _isActive = false;
      _safeAdd(_connectingController, false);
      return null;
    }
  }

  // ============================================
  // JOIN CALL
  // ============================================

  /// Join an existing call
  /// Per reference: joinCall uses { callId, userId, role: 'participant' }
  Future<bool> joinCall({
    required String callId,
    required String roomId,
    required CallType callType,
    required String chatGroup,
  }) async {
    if (_isDisposed) {
      debugPrint('❌ Cannot join call - service is disposed');
      return false;
    }

    try {
      debugPrint('══════════════════════════════════════════');
      debugPrint('🔗 JOINING EXISTING ${callType.name.toUpperCase()} CALL');
      debugPrint('══════════════════════════════════════════');
      debugPrint('📋 Call Details:');
      debugPrint('   - Call ID: $callId');
      debugPrint('   - Room ID: $roomId');
      debugPrint('   - User ID: $userId');
      debugPrint('   - User Name: $userName');
      debugPrint('   - Call Type: ${callType.name}');

      _isConnecting = true;
      _isActive = true; // Mark as active to allow socket event processing
      _safeAdd(_connectingController, true);

      // 🔥 WEB IMPLEMENTATION NOTE: joinCall does NOT call joinGroup!
      // Only startCall joins the group. Removing joinGroup here to match web.
      // The user should already be in the group from the chat screen.
      debugPrint('\n📝 NOTE: Skipping joinGroup - per web implementation, only startCall does this');

      // Step 1: Request permissions
      debugPrint('\n🔐 STEP 1: Requesting permissions...');
      final hasPermissions = await requestPermissions(callType);
      if (!hasPermissions) {
        _isActive = false;
        throw Exception('Permissions not granted');
      }

      // Step 2: Get user media
      debugPrint('\n🎥 STEP 2: Getting user media...');
      // Defensive cleanup (prevents camera lock on Android)
      _localStream?.getTracks().forEach((t) {
        try {
          t.stop();
        } catch (_) {}
      });
      _localStream?.dispose();
      _localStream = null;

      final stream = await getUserMedia(callType);
      if (stream == null) {
        _isActive = false;
        throw Exception('Failed to get user media');
      }

      _localStream = stream;
      _safeAdd(_localStreamController, stream);
      debugPrint('✅ Local stream added to controller');

      // 🔥 WEB IMPLEMENTATION FIX: Use userId directly as peerId
      // Web code: const peerId = userId;
      // This ensures consistent peer identification across web and mobile
      final peerId = userId;
      _peerId = peerId;
      debugPrint('\n🆔 STEP 3: Using userId as Peer ID: $peerId');
      debugPrint('   💡 Per web implementation: peerId = userId (not generated)');

      // Step 4: Get router RTP capabilities and initialize device
      debugPrint(
        '\n🔧 STEP 4: Getting RTP capabilities and initializing device...',
      );
      final rtpCapabilities = await _getRouterRtpCapabilities(roomId);
      if (rtpCapabilities == null) {
        _isActive = false;
        throw Exception('Failed to get RTP capabilities');
      }

      final deviceReady = await _initializeDevice(rtpCapabilities);
      if (!deviceReady) {
        _isActive = false;
        throw Exception('Failed to initialize device');
      }

      // Step 5: Join existing call - per reference: { callId, userId }
      debugPrint('\n📡 STEP 5: Joining call via joinCall...');
      final completer = Completer<bool>();

      // Per reference documentation: joinCall uses { callId, userId }
      socketService.joinCall(
        {
          'callId': callId,
          'userId': userId,
        },
        (response) async {
          if (_isDisposed) {
            completer.complete(false);
            return;
          }

          debugPrint('📨 Server response received: $response');

          if (response['success'] == true) {
            _currentCallId = response['callId'] ?? callId;
            _currentRoomId = response['roomId'] ?? roomId;
            debugPrint('✅ Joined call on server');
            debugPrint('   - Is Existing: ${response['isExisting']}');

            try {
              // Join room
              debugPrint('\n🚪 STEP 7: Joining mediasoup room...');
              final roomResponse = await _joinRoom(_currentRoomId!, peerId);

              // Create transports
              debugPrint('\n🔧 STEP 8: Creating WebRTC transports...');
              final sendCreated = await _createSendTransport();
              final recvCreated = await _createRecvTransport();

              if (!sendCreated || !recvCreated) {
                _isActive = false;
                throw Exception('Failed to create transports');
              }

              _isTransportsReady = true;
              debugPrint('✅ Both transports created and ready');

              // Produce media
              debugPrint('\n📤 STEP 9: Producing local media...');
              await _produceAudio();
              if (callType == CallType.video) {
                await _produceVideo();
              }

              // Consume existing producers and handle their paused state
              debugPrint('\n📥 STEP 10: Consuming existing participants...');
              debugPrint('   🔍 Current userId: $userId, peerId: $peerId');
              if (roomResponse != null && roomResponse['producers'] != null) {
                final producers = roomResponse['producers'] as List;
                debugPrint('   Found ${producers.length} existing producers');
                for (final producer in producers) {
                  if (_isDisposed) break;
                  final producerId = producer['producerId'] as String?;
                  final remotePeerId =
                      producer['peerId'] as String? ?? 'unknown';
                  final paused = producer['paused'] as bool? ?? false;
                  final kind = producer['kind'] as String?;
                  final userName = producer['userName'] as String?;

                  debugPrint('   🔍 Processing producer: $producerId');
                  debugPrint('      - remotePeerId: $remotePeerId');
                  debugPrint('      - userName: $userName');
                  debugPrint('      - kind: $kind');

                  if (producerId != null) {
                    // 🔥 FIX: Skip our own producers - check if remotePeerId contains our userId
                    // Because peerId format can be either 'userId' or 'peer-userId-timestamp'
                    final isOwnProducer = remotePeerId == peerId ||
                                          remotePeerId == userId ||
                                          remotePeerId.contains(userId);

                    debugPrint('      - isOwnProducer: $isOwnProducer');

                    // Store participant name and status for OTHER participants only
                    if (userName != null && !isOwnProducer) {
                      _participantNames[remotePeerId] = userName;
                      debugPrint('   ✅ Stored participant name: $userName for peer: $remotePeerId');

                      // Initialize or update remote participant status
                      if (!_remoteParticipantStatus.containsKey(remotePeerId)) {
                        _remoteParticipantStatus[remotePeerId] = RemoteParticipantStatus(
                          peerId: remotePeerId,
                          name: userName,
                          isAudioMuted: kind == 'audio' && paused,
                          isVideoOff: kind == 'video' && paused,
                        );
                        debugPrint('   ✅ Created RemoteParticipantStatus for: $remotePeerId');
                      }
                    }

                    // Only consume producers from OTHER participants
                    if (!isOwnProducer) {
                      await _consumeProducer(producerId, remotePeerId);

                      // Handle initial paused state (e.g., user already muted)
                      if (paused && kind != null) {
                        debugPrint(
                          'Producer $producerId ($kind) is muted/paused',
                        );
                        _updateParticipantMuteState(remotePeerId, kind, true);
                      }
                    } else {
                      debugPrint('   ⏭️ Skipping own producer: $producerId');
                    }
                  }
                }

                // 🔥 FIX: Emit participant updates after processing all producers
                debugPrint('   📊 Final _participantNames: $_participantNames');
                debugPrint('   📊 Final _remoteParticipantStatus keys: ${_remoteParticipantStatus.keys.toList()}');
                _safeAdd(
                  _participantNamesController,
                  Map<String, String>.from(_participantNames),
                );
                _safeAdd(
                  _remoteParticipantStatusController,
                  Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
                );
                debugPrint('   ✅ Emitted participant names and status updates');
              }

              // Process pending consumers
              await _processPendingConsumers();

              _isInCall = true;
              _isConnecting = false;
              _safeAdd(_callStateController, true);
              _safeAdd(_connectingController, false);

              debugPrint('\n✅ JOINED CALL SUCCESSFULLY');
              debugPrint('══════════════════════════════════════════\n');

              completer.complete(true);
            } catch (e) {
              debugPrint('❌ Error during join setup: $e');
              _isConnecting = false;
              _isActive = false;
              _safeAdd(_connectingController, false);
              completer.complete(false);
            }
          } else {
            debugPrint('❌ Server rejected join request: $response');
            _isConnecting = false;
            _isActive = false;
            _safeAdd(_connectingController, false);
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      debugPrint('\n❌❌❌ ERROR JOINING CALL ❌❌❌');
      debugPrint('Error: $e');
      debugPrint('══════════════════════════════════════════\n');
      _isConnecting = false;
      _isActive = false;
      _safeAdd(_connectingController, false);
      return false;
    }
  }

  // ============================================
  // END / LEAVE CALL
  // ============================================

  /// End call (initiator)
  Future<void> endCall() async {
    if (_isDisposed) {
      debugPrint('⚠️ Cannot end call - service is disposed');
      return;
    }

    if (_currentCallId == null) {
      debugPrint('⚠️ Cannot end call - no active call ID');
      cleanup();
      return;
    }

    debugPrint('🛑 Ending call: $_currentCallId');
    socketService.endCall({'callId': _currentCallId!, 'status': 'ended'});

    cleanup();
  }

  /// Leave call (participant)
  Future<void> leaveCall() async {
    if (_isDisposed) {
      debugPrint('⚠️ Cannot leave call - service is disposed');
      return;
    }

    if (_currentCallId == null) {
      debugPrint('⚠️ Cannot leave call - no active call ID');
      cleanup();
      return;
    }

    debugPrint('👋 Leaving call: $_currentCallId');
    socketService.leaveCall({'callId': _currentCallId!, 'userId': userId});

    cleanup();
  }

  // ============================================
  // AUDIO/VIDEO CONTROLS
  // ============================================

  /// Toggle audio mute/unmute
  /// 🔥 FIXED: Now uses _producers Map like web implementation for reliable lookup
  void toggleAudio() {
    debugPrint('🎤 toggleAudio() called');
    debugPrint('   - _isDisposed: $_isDisposed');
    debugPrint('   - _producers keys: ${_producers.keys.toList()}');
    debugPrint('   - _producers["audio"]: ${_producers['audio']?.id ?? "NULL"}');
    debugPrint('   - _producers["video"]: ${_producers['video']?.id ?? "NULL"}');
    debugPrint('   - _isMuted: $_isMuted');

    if (_isDisposed) {
      debugPrint('❌ toggleAudio() - service is disposed');
      return;
    }

    // 🔥 Use Map lookup like web implementation: producersRef.current.get("audio")
    final audioProducer = _producers['audio'];

    if (audioProducer == null) {
      debugPrint('⚠️ Cannot toggle audio - _producers["audio"] is NULL!');
      debugPrint('   💡 This means _produceAudio() failed or producer callback did not capture audio');
      debugPrint('   💡 Available producer kinds: ${_producers.keys.toList()}');
      return;
    }

    if (_isMuted) {
      debugPrint('🔊 Unmuting audio - producer: ${audioProducer.id}');
      // Per web: socket.emit("resumeProducer", { producerId }) then audioProducer.resume()
      socketService.resumeProducer({'producerId': audioProducer.id});
      audioProducer.resume();
      _isMuted = false;
      debugPrint('✅ Audio unmuted');
    } else {
      debugPrint('🔇 Muting audio - producer: ${audioProducer.id}');
      // Per web: socket.emit("pauseProducer", { producerId }) then audioProducer.pause()
      socketService.pauseProducer({'producerId': audioProducer.id});
      audioProducer.pause();
      _isMuted = true;
      debugPrint('✅ Audio muted');
    }

    _safeAdd(_mutedController, _isMuted);
  }

  /// Toggle video on/off
  /// 🔥 FIXED: Now uses _producers Map like web implementation for reliable lookup
  void toggleVideo() {
    debugPrint('📹 toggleVideo() called');
    debugPrint('   - _isDisposed: $_isDisposed');
    debugPrint('   - _producers keys: ${_producers.keys.toList()}');
    debugPrint('   - _producers["video"]: ${_producers['video']?.id ?? "NULL"}');
    debugPrint('   - _isVideoOff: $_isVideoOff');

    if (_isDisposed) {
      debugPrint('❌ toggleVideo() - service is disposed');
      return;
    }

    // 🔥 Use Map lookup like web implementation: producersRef.current.get("video")
    final videoProducer = _producers['video'];

    if (videoProducer == null) {
      debugPrint('⚠️ Cannot toggle video - _producers["video"] is NULL!');
      debugPrint('   💡 Available producer kinds: ${_producers.keys.toList()}');
      return;
    }

    if (_isVideoOff) {
      debugPrint('📹 Turning video on - producer: ${videoProducer.id}');
      // Per web: socket.emit("resumeProducer", { producerId }) then videoProducer.resume()
      socketService.resumeProducer({'producerId': videoProducer.id});
      videoProducer.resume();
      _isVideoOff = false;
      debugPrint('✅ Video turned on');
    } else {
      debugPrint('📹 Turning video off - producer: ${videoProducer.id}');
      // Per web: socket.emit("pauseProducer", { producerId }) then videoProducer.pause()
      socketService.pauseProducer({'producerId': videoProducer.id});
      videoProducer.pause();
      _isVideoOff = true;
      debugPrint('✅ Video turned off');
    }

    _safeAdd(_videoOffController, _isVideoOff);
  }

  /// Switch between front and back camera
  /// This replaces the video track with a new one from the opposite camera
  Future<void> switchCamera() async {
    debugPrint('📷 switchCamera() called');
    debugPrint('   - _isDisposed: $_isDisposed');
    debugPrint('   - _isFrontCamera: $_isFrontCamera');
    debugPrint('   - _localStream: ${_localStream != null}');

    if (_isDisposed) {
      debugPrint('❌ switchCamera() - service is disposed');
      return;
    }

    if (_localStream == null) {
      debugPrint('❌ switchCamera() - no local stream');
      return;
    }

    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) {
      debugPrint('❌ switchCamera() - no video tracks');
      return;
    }

    try {
      // Use flutter_webrtc's Helper to switch camera
      final videoTrack = videoTracks.first;

      // Switch the camera using the track's switchCamera method
      final result = await Helper.switchCamera(videoTrack);
      debugPrint('📷 Camera switched, result: $result');

      // Toggle the front camera state
      _isFrontCamera = !_isFrontCamera;
      debugPrint('📷 Now using ${_isFrontCamera ? "front" : "back"} camera');

      // Notify listeners
      _safeAdd(_frontCameraController, _isFrontCamera);

      // Re-emit local stream to update UI
      _safeAdd(_localStreamController, _localStream);

      // Notify other participants about camera switch via socket
      if (_peerId != null) {
        socketService.emitCameraSwitched({
          'peerId': _peerId,
          'isFrontCamera': _isFrontCamera,
        });
      }

      debugPrint('✅ Camera switched successfully');
    } catch (e) {
      debugPrint('❌ Error switching camera: $e');
    }
  }

  // ============================================
  // CLEANUP (Reusable - clears call, keeps service alive)
  // ============================================

  /// Cleanup call resources without disposing the service.
  /// This allows the service to be reused for another call.
  ///
  /// IMPORTANT: This method:
  /// - Clears all call-related state
  /// - Detaches socket listeners to prevent late events
  /// - Does NOT close StreamControllers (allows UI to continue listening)
  /// - Sets _isActive to false to ignore any late socket events
  void cleanup() {
    if (_isDisposed) {
      debugPrint('⚠️ MediasoupService: Skipping cleanup - already disposed');
      return;
    }

    if (_isCleaningUp) {
      debugPrint('⚠️ MediasoupService: Cleanup already in progress');
      return;
    }

    _isCleaningUp = true;
    debugPrint('🧹 Cleaning up call resources...');

    // FIRST: Set flags to prevent any more event processing
    _isActive = false;
    _isInCall = false;
    _isConnecting = false;

    // Detach socket listeners BEFORE closing resources
    // This prevents late events from firing during cleanup
    _detachSocketListeners();

    // Close all producers from the Map (like web implementation)
    for (final entry in _producers.entries) {
      try {
        entry.value.close();
        debugPrint('✅ Closed ${entry.key} producer');
      } catch (e) {
        debugPrint('⚠️ Error closing ${entry.key} producer: $e');
      }
    }
    _producers.clear();

    // Close consumers
    for (final consumer in _consumers.values) {
      try {
        consumer.close();
      } catch (e) {
        debugPrint('⚠️ Error closing consumer: $e');
      }
    }
    _consumers.clear();

    // Close transports
    try {
      _sendTransport?.close();
    } catch (e) {
      debugPrint('⚠️ Error closing send transport: $e');
    }
    _sendTransport = null;

    try {
      _recvTransport?.close();
    } catch (e) {
      debugPrint('⚠️ Error closing recv transport: $e');
    }
    _recvTransport = null;

    // Stop local stream
    try {
      _localStream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (e) {
          debugPrint('⚠️ Error stopping track: $e');
        }
      });
      _localStream?.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing local stream: $e');
    }
    _localStream = null;

    // Clear remote streams
    for (final stream in _remoteStreams.values) {
      try {
        stream.dispose();
      } catch (e) {
        debugPrint('⚠️ Error disposing remote stream: $e');
      }
    }
    _remoteStreams.clear();

    // Clear participant data
    _participantNames.clear();
    _remoteParticipantStatus.clear();

    // Clear mappings
    _producerToPeer.clear();
    _pendingConsumers.clear();

    // Reset state
    _device = null;
    _currentCallId = null;
    _currentRoomId = null;
    _peerId = null;
    _isMuted = false;
    _isVideoOff = false;
    _isTransportsReady = false;
    _audioProduced = false;
    _videoProduced = false;
    _participantCount = 0;

    // Reset producer completers (both server ACK and local SDP)
    _audioProducerCompleter = null;
    _videoProducerCompleter = null;
    _audioProducerLocalCompleter = null;
    _videoProducerLocalCompleter = null;

    // Notify UI of state changes (using safe add)
    _safeAdd(_localStreamController, null);
    _safeAdd(
      _remoteStreamsController,
      Map<String, MediaStream>.from(_remoteStreams),
    );
    _safeAdd(
      _participantNamesController,
      Map<String, String>.from(_participantNames),
    );
    _safeAdd(
      _remoteParticipantStatusController,
      Map<String, RemoteParticipantStatus>.from(_remoteParticipantStatus),
    );
    _safeAdd(_callStateController, false);
    _safeAdd(_connectingController, false);
    _safeAdd(_mutedController, false);
    _safeAdd(_videoOffController, false);
    _safeAdd(_participantCountController, 0);

    _isCleaningUp = false;
    debugPrint('✅ Cleanup complete - all resources released');
  }

  // ============================================
  // DISPOSE (Final - closes everything)
  // ============================================

  /// Dispose service and clean up ALL resources.
  /// After this, the service cannot be reused.
  ///
  /// IMPORTANT: This method:
  /// - Calls cleanup() first to clear call resources
  /// - Closes all StreamControllers
  /// - Sets _isDisposed to true to prevent any further operations
  void dispose() {
    if (_isDisposed) {
      debugPrint('⚠️ MediasoupService: Already disposed');
      return;
    }

    debugPrint('🗑️ Disposing MediasoupService...');

    // Mark as disposed FIRST to prevent any operations during dispose
    _isDisposed = true;
    _isActive = false;

    // Cleanup any active call resources (this will also detach listeners)
    if (!_isCleaningUp) {
      cleanup();
    }

    // Close all stream controllers
    try {
      _localStreamController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing localStreamController: $e');
    }
    try {
      _remoteStreamsController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing remoteStreamsController: $e');
    }
    try {
      _participantNamesController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing participantNamesController: $e');
    }
    try {
      _remoteParticipantStatusController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing remoteParticipantStatusController: $e');
    }
    try {
      _callStateController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing callStateController: $e');
    }
    try {
      _connectingController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing connectingController: $e');
    }
    try {
      _mutedController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing mutedController: $e');
    }
    try {
      _videoOffController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing videoOffController: $e');
    }
    try {
      _frontCameraController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing frontCameraController: $e');
    }
    try {
      _participantCountController.close();
    } catch (e) {
      debugPrint('⚠️ Error closing participantCountController: $e');
    }

    // Clear saved callback references
    _savedOnNewProducer = null;
    _savedOnProducerPaused = null;
    _savedOnProducerResumed = null;
    _savedOnParticipantJoined = null;
    _savedOnParticipantLeft = null;
    _savedOnPeerClosed = null;
    _savedOnProducerClosed = null;
    _savedOnCameraSwitched = null;
    _savedOnCallEnded = null;

    debugPrint('✅ MediasoupService disposed');
  }
}  