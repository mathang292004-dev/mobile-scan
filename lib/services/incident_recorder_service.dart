import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/preference_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../presentation/case_report/model/ai_summary_details.dart';

class IncidentRecorderService {
  IncidentRecorderService();

  // WebSocket connection
  io.Socket? _socket;
  final String _websocketUrl = "https://dev-emergex.zapptor.com";
  final String _websocketPath = "/websocket";

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _recordingTimer;
  Timer? _heartbeatTimer;

  // Audio streaming
  String? _currentRecordingPath;
  File? _currentRecordingFile;
  int _lastReadPosition = 0;

  // Stream controllers for real-time updates
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<String> _summaryController =
      StreamController<String>.broadcast();

  // State management
  bool _isConnected = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String _currentTranscript = "";
  String _aiSummary = "";

  // Callbacks
  Function(String transcript)? onTranscriptUpdate;
  Function(AiSummaryResponse summaryRes)? onSummaryApiUpdate;
  Function(String summary)? onSummaryUpdate;
  Function(List<String> questions)? onQuestionsUpdate;
  Function(List<String> examples)? onExamplesUpdate;
  Function(int totalQuestionsLength)? onTotalQuestionsLengthUpdate;
  Function(int unansweredQuestionsLength)? onUnansweredQuestionsLengthUpdate;
  Function(bool isConnected)? onConnectionStatusChange;
  Function(bool isRecording)? onRecordingStatusChange;
  Function(List<double> audioLevels)? onAudioLevelsUpdate;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String get currentTranscript => _currentTranscript;
  String get aiSummary => _aiSummary;
  String? get socketId => _socket?.id;
  Future<bool> hasPermission() => _recorder.hasPermission();
  CancelToken? _aiSummaryCancelToken;
  // Stream getters for real-time updates
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get summaryStream => _summaryController.stream;

  /// Initialize WebSocket connection
  Future<void> initializeWebSocket() async {
    try {
      // Dispose existing connection if any
      _socket?.disconnect();
      _socket = null;
      _isConnected = false;

      debugPrint(
        "Attempting to connect to WebSocket: $_websocketUrl$_websocketPath",
      );

      _socket = io.io(
        _websocketUrl,
        io.OptionBuilder()
            .setPath(_websocketPath)
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket!.onConnect((_) {
        debugPrint("=== WEBSOCKET CONNECTED ===");

        // Safety check - if socket was disposed mid-connection
        if (_socket == null) {
          debugPrint("Socket is null (disposed) - ignoring connection event");
          return;
        }

        debugPrint("Socket connected successfully: ${_socket!.id}");
        debugPrint("Socket URL: $_websocketUrl$_websocketPath");
        _isConnected = true;
        onConnectionStatusChange?.call(true);
        _startHeartbeat();

        // Send a test message to verify server communication
        _socket!.emit('test', {'message': 'Hello from Flutter client'});
        debugPrint("=== TEST MESSAGE SENT ===");

        debugPrint("=== CONNECTION ESTABLISHED ===");
      });

      _socket!.onAny((event, data) {
        debugPrint("=== WEBSOCKET EVENT RECEIVED ===");
        debugPrint("Event: $event");
        debugPrint("Data: $data");
        debugPrint("Data type: ${data.runtimeType}");
        debugPrint("=== END EVENT ===");
      });

      // Add a test event to verify server communication
      _socket!.on('test', (data) {
        debugPrint("=== TEST EVENT RECEIVED ===");
        debugPrint("Test data: $data");
        debugPrint("=== END TEST EVENT ===");
      });

      // Add listeners for all possible transcript events
      _socket!.on('result', (data) {
        debugPrint("=== TRANSCRIPT RESULT EVENT ===");
        debugPrint("Full response data: $data");
        debugPrint("Data type: ${data.runtimeType}");

        if (data != null) {
          debugPrint("fullText: ${data['fullText']}");
          debugPrint("text: ${data['text']}");
          debugPrint("isFinal: ${data['isFinal']}");
        }

        // Match React implementation - use fullText if available, otherwise text
        String? transcriptText;
        if (data != null &&
            data['fullText'] != null &&
            data['fullText'].toString().isNotEmpty) {
          transcriptText = data['fullText'].toString();
          debugPrint("Using fullText: $transcriptText");
        } else if (data != null &&
            data['text'] != null &&
            data['text'].toString().isNotEmpty) {
          transcriptText = data['text'].toString();
          debugPrint("Using text: $transcriptText");
        }

        if (transcriptText != null && transcriptText.isNotEmpty) {
          _currentTranscript = transcriptText;
          debugPrint("Updated current transcript: $_currentTranscript");
          debugPrint("Transcript length: ${transcriptText.length}");

          if (!_transcriptController.isClosed) {
            _transcriptController.add(_currentTranscript);
          }
          onTranscriptUpdate?.call(_currentTranscript);
          debugPrint("=== TRANSCRIPT UPDATED ===");
        } else {
          debugPrint("Received null or empty transcript data - ignoring");
        }
        debugPrint("=== END TRANSCRIPT RESULT ===");
      });

      // Add listener for 'transcript' event (alternative event name)
      _socket!.on('transcript', (data) {
        debugPrint("=== TRANSCRIPT EVENT ===");
        debugPrint("Transcript data: $data");
        debugPrint("=== END TRANSCRIPT EVENT ===");
      });

      // Add listener for 'speech' event (alternative event name)
      _socket!.on('speech', (data) {
        debugPrint("=== SPEECH EVENT ===");
        debugPrint("Speech data: $data");
        debugPrint("=== END SPEECH EVENT ===");
      });

      // Add listener for 'recognition' event (alternative event name)
      _socket!.on('recognition', (data) {
        debugPrint("=== RECOGNITION EVENT ===");
        debugPrint("Recognition data: $data");
        debugPrint("=== END RECOGNITION EVENT ===");
      });

      // Remove pause/resume event handlers - React doesn't use these
      // The React implementation handles AI summary through HTTP API calls

      // Remove other event handlers - React doesn't use these

      _socket!.onDisconnect((_) {
        debugPrint("=== WEBSOCKET DISCONNECTED ===");
        debugPrint("Socket disconnected");
        _isConnected = false;
        _stopHeartbeat();
        onConnectionStatusChange?.call(false);
        debugPrint("=== DISCONNECTION COMPLETE ===");
      });

      _socket!.onError((error) {
        debugPrint("=== WEBSOCKET ERROR ===");
        debugPrint("Socket error: $error");
        _isConnected = false;
        onConnectionStatusChange?.call(false);
        debugPrint("=== ERROR HANDLED ===");
      });

      _socket!.onConnectError((error) {
        debugPrint("=== WEBSOCKET CONNECTION ERROR ===");
        debugPrint("Socket connection error: $error");
        _isConnected = false;
        onConnectionStatusChange?.call(false);
        debugPrint("=== CONNECTION ERROR HANDLED ===");
      });
    } catch (e) {
      debugPrint("Failed to initialize WebSocket: $e");
      _isConnected = false;
      onConnectionStatusChange?.call(false);
    }
  }

  /// Start recording with WebSocket streaming
  Future<void> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        throw Exception("Microphone permission not granted");
      }

      // Reset transcript and summary when starting new recording
      _currentTranscript = "";
      _aiSummary = "";

      // Initialize WebSocket if not connected
      if (!_isConnected) {
        await initializeWebSocket();

        int retryCount = 0;
        const maxRetries = 8;
        const baseDelay = Duration(milliseconds: 500);

        while (!_isConnected && retryCount < maxRetries) {
          final delay = Duration(
            milliseconds: baseDelay.inMilliseconds + (retryCount * 250),
          );
          await Future.delayed(delay);
          retryCount++;
          debugPrint(
            "Waiting for WebSocket connection... attempt $retryCount/$maxRetries (${delay.inMilliseconds}ms delay)",
          );

          if (_isConnected) {
            debugPrint("WebSocket connected during wait period");
            break;
          }
        }

        if (!_isConnected) {
          throw Exception(
            "WebSocket connection failed after $maxRetries attempts. Please check if the server is running at $_websocketUrl$_websocketPath",
          );
        }
      }

      // Emit initial reset to streams
      if (!_transcriptController.isClosed) {
        _transcriptController.add(_currentTranscript);
      }
      if (!_summaryController.isClosed) {
        _summaryController.add(_aiSummary);
      }

      // Start audio recording
      final directory = await _getApplicationDocumentsDirectory();
      _currentRecordingPath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        RecordConfig(
          encoder: Platform.isAndroid ? AudioEncoder.opus : AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 48000,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      _currentRecordingFile = File(_currentRecordingPath!);
      _lastReadPosition = 0;
      _isRecording = true;
      _isPaused = false;
      onRecordingStatusChange?.call(true);

      // Call callbacks with reset values
      onTranscriptUpdate?.call(_currentTranscript);
      onSummaryUpdate?.call(_aiSummary);

      // Start audio level monitoring
      _startAudioLevelMonitoring();

      // Start streaming audio chunks
      debugPrint("Starting audio streaming...");
      _startAudioStreaming();
    } catch (e) {
      debugPrint("Failed to start recording: $e");
      _isRecording = false;
      onRecordingStatusChange?.call(false);
      rethrow;
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    try {
      _isRecording = false;
      _isPaused = false;
      onRecordingStatusChange?.call(false);

      // Stop audio level monitoring
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      // Stop recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Stop recording
      final path = await _recorder.stop();
      // dispose();
      _socket?.disconnect();
      _socket = null;
      // Send final audio chunk if connected
      if (_isConnected && _socket != null && _currentRecordingFile != null) {
        await _sendFinalAudioChunk();
      }

      // Reset file tracking
      _currentRecordingFile = null;
      _currentRecordingPath = null;
      _lastReadPosition = 0;

      return path;
    } catch (e) {
      debugPrint("Failed to stop recording: $e");
      rethrow;
    }
  }

  /// Pause/Resume recording
  Future<void> pauseResumeRecording(String recordedTxt) async {
    try {
      debugPrint(
        "pauseResumeRecording called - isRecording: $_isRecording, isPaused: $_isPaused",
      );

      if (_isRecording && !_isPaused) {
        debugPrint("Pausing recording...");
        await _recorder.pause();
        _isPaused = true;
        _amplitudeSubscription?.cancel();
        _recordingTimer?.cancel();

        // Send pause signal to server matching React implementation
        if (_isConnected && _socket != null) {
          _socket!.emit('pauseRecording');
          debugPrint("Sent pauseRecording signal to server");
        }

        // Get AI summary when paused
        debugPrint("Calling AI summary after pause...");
        await getAISummary(recordedTxt);
      } else if (_isRecording && _isPaused) {
        debugPrint("Resuming recording...");
        await _recorder.resume();
        _isPaused = false;
        _startAudioLevelMonitoring();
        _startAudioStreaming(); // Restart streaming

        // Send resume signal to server matching React implementation
        if (_isConnected && _socket != null) {
          _socket!.emit('resumeRecording');
          debugPrint("Sent resumeRecording signal to server");
        }
      } else {
        debugPrint("pauseResumeRecording called but not in recording state");
      }
    } catch (e) {
      debugPrint("Failed to pause/resume recording: $e");
    }
  }

  /// Start audio level monitoring for visualization
  void _startAudioLevelMonitoring() {
    _amplitudeSubscription?.cancel();

    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amplitude) {
          if (_isRecording && !_isPaused) {
            // Convert amplitude to visualization levels
            final currentLevel = amplitude.current;
            final normalizedLevel = ((currentLevel + 60) / 60.0).clamp(
              0.0,
              1.0,
            );

            // Create 12 bars for visualization
            final List<double> audioLevels = List.generate(12, (index) {
              return (normalizedLevel * (0.8 + (index % 3) * 0.05)).clamp(
                0.1,
                1.0,
              );
            });

            onAudioLevelsUpdate?.call(audioLevels);
          }
        });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _socket != null) {
        _socket!.emit('ping', {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        debugPrint("Sent heartbeat ping");
      }
    });
  }

  /// Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Start audio streaming to WebSocket
  void _startAudioStreaming() {
    debugPrint("Starting audio streaming to WebSocket...");

    _recordingTimer?.cancel();
    // Send audio chunks every 1000ms (1 second) for real-time streaming
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) async {
      if (_isRecording && !_isPaused && _isConnected && _socket != null) {
        await _sendCurrentAudioChunk();
      }
    });
  }

  /// Send current audio chunk from the recording file
  Future<void> _sendCurrentAudioChunk() async {
    try {
      if (_currentRecordingFile == null ||
          !await _currentRecordingFile!.exists()) {
        debugPrint("Recording file not found, skipping chunk");
        return;
      }

      // Get current file size
      final fileSize = await _currentRecordingFile!.length();

      // If file hasn't grown since last read, skip
      if (fileSize <= _lastReadPosition) {
        debugPrint("No new audio data, skipping chunk");
        return;
      }

      // Read new audio data since last position
      final randomAccessFile = await _currentRecordingFile!.open();
      await randomAccessFile.setPosition(_lastReadPosition);

      // Read chunk (max 64KB to avoid large messages)
      const chunkSize = 65536; // 64KB
      final remainingBytes = fileSize - _lastReadPosition;
      final bytesToRead = math.min(chunkSize, remainingBytes);

      final audioBytes = await randomAccessFile.read(bytesToRead);
      await randomAccessFile.close();

      // Update last read position
      _lastReadPosition += bytesToRead;

      if (audioBytes.isNotEmpty) {
        // Send audio chunk matching React implementation
        final audioData = {'chunk': audioBytes, 'isFinal': false};

        _socket?.emit('audio', audioData);
        debugPrint("=== AUDIO CHUNK SENT ===");
        debugPrint("Audio data: $audioData");
        debugPrint("Chunk size: ${audioBytes.length} bytes");
        debugPrint("Total processed: $_lastReadPosition");
        debugPrint("Socket connected: $_isConnected");
        debugPrint("Socket ID: ${_socket?.id}");
        debugPrint("=== END AUDIO CHUNK ===");
      }
    } catch (e) {
      debugPrint("Error sending audio chunk: $e");
    }
  }

  /// Send final audio chunk when recording stops
  Future<void> _sendFinalAudioChunk() async {
    try {
      if (_currentRecordingFile == null ||
          !await _currentRecordingFile!.exists()) {
        debugPrint("Recording file not found for final chunk");
        return;
      }

      // Read any remaining audio data
      await _sendCurrentAudioChunk();

      // Send final signal matching React implementation
      final finalData = {
        'chunk': Uint8List(0), // Empty chunk to indicate end
        'isFinal': true,
      };

      _socket?.emit('audio', finalData);
      debugPrint("Sent final audio chunk signal");
    } catch (e) {
      debugPrint("Error sending final audio chunk: $e");
    }
  }

  /// Get AI summary when recording is paused
  Future<void> getAISummary(String inputTxt, {String? incidentId}) async {
    final PreferenceHelper preferenceHelper = PreferenceHelper();
    final userToken = await preferenceHelper.getUserToken();

    // Cancel any existing AI summary request
    _aiSummaryCancelToken?.cancel();
    _aiSummaryCancelToken = CancelToken();

    try {
      final dio = Dio();
      final aiSummaryUrl =
          "https://dev-emergex.zapptor.com/api/incident/getAISummary";

      debugPrint("Calling AI Summary API: $aiSummaryUrl");
      debugPrint("Sending inputTxt: $inputTxt");
      debugPrint("Sending incidentId: $incidentId");

      // Prepare data payload
      final Map<String, dynamic> data = {'text': inputTxt};
      if (incidentId != null && incidentId.isNotEmpty) {
        data['incidentId'] = incidentId;
      }

      // Get project ID from app cubit
      final appCubit = AppDI.emergexAppCubit;
      final selectedProjectId = appCubit.state.selectedProjectId;
      final projects = appCubit.state.userPermissions?.projects ?? [];
      final firstProjectId = projects.isNotEmpty
          ? projects.first.projectId
          : null;
      final projectId = selectedProjectId?.isNotEmpty == true
          ? selectedProjectId
          : firstProjectId;

      final response = await dio.post(
        aiSummaryUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $userToken',
            if (projectId != null) 'x-project-id': projectId,
          },
        ),
        data: data,
        cancelToken: _aiSummaryCancelToken,
      );

      debugPrint("AI Summary API Response Status: ${response.statusCode}");
      debugPrint("AI Summary API Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final summaryRes = AiSummaryResponse.fromJson(response.data);

        _aiSummary = summaryRes.summary;

        onSummaryApiUpdate?.call(summaryRes);

        debugPrint("AI Summary processed and updated: $_aiSummary");
      } else {
        debugPrint("AI Summary API returned status: ${response.statusCode}");
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint("AI Summary API call was cancelled");
      } else {
        debugPrint("Failed to get AI summary: $e");
      }
    }
  }

  /// Cancel AI summary API call
  void cancelAISummary() {
    _aiSummaryCancelToken?.cancel();
    debugPrint("AI Summary API call cancelled");
  }

  /// Upload incident with audio file
  Future<Map<String, dynamic>> uploadIncident({
    required String audioFilePath,
    String? incidentId,
    String? incidentText,
  }) async {
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        if (incidentId != null)
          'files': await MultipartFile.fromFile(audioFilePath),
        if (incidentId == null)
          'file': await MultipartFile.fromFile(audioFilePath),
      });

      final url = incidentId != null
          ? '$_websocketUrl/update-incident/$incidentId'
          : '$_websocketUrl/incident-upload';

      final response = await dio.post(url, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': 'Upload failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint("Failed to upload incident: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get application documents directory
  Future<Directory> _getApplicationDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Dispose resources
  void dispose() {
    _socket?.disconnect();
    _socket = null;
    _amplitudeSubscription?.cancel();
    _recordingTimer?.cancel();
    _stopHeartbeat();
    _recorder.dispose();
    if (!_transcriptController.isClosed) {
      _transcriptController.close();
    }
    if (!_summaryController.isClosed) {
      _summaryController.close();
    }
    _isConnected = false;
    _isRecording = false;
    _isPaused = false;
    _currentRecordingFile = null;
    _currentRecordingPath = null;
    _lastReadPosition = 0;
  }
}

// Extension for sin function
extension MathExtension on double {
  double sin() => math.sin(this);
}
