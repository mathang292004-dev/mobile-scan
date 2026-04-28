import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoViewWidget extends StatefulWidget {
  final MediaStream? stream;
  final String peerId;
  final bool mirror;
  final void Function(String peerId)? onRendererReady;

  const VideoViewWidget({
    super.key,
    required this.peerId,
    required this.stream,
    this.mirror = false,
    this.onRendererReady,
  });

  @override
  State<VideoViewWidget> createState() => _VideoViewWidgetState();
}

class _VideoViewWidgetState extends State<VideoViewWidget> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _initialized = false;
  MediaStream? _attachedStream;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  @override
  void didUpdateWidget(VideoViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream?.id != widget.stream?.id) {
      debugPrint(
        '🎥 [VideoView] Stream changed for peer ${widget.peerId}',
      );
      _updateStream();
    }
  }

  Future<void> _initRenderer() async {
    try {
      debugPrint('🎥 [VideoView] Initializing renderer...');
      await _renderer.initialize();
      debugPrint('✅ [VideoView] Renderer initialized');

      if (!mounted) return;

      setState(() => _initialized = true);
      _updateStream();
    } catch (e) {
      debugPrint('❌ [VideoView] Renderer init failed: $e');
    }
  }

  void _updateStream() {
    if (!_initialized || widget.stream == null) return;

    // 🔥 CRITICAL: Prevent re-attaching same stream
    if (_attachedStream?.id == widget.stream!.id) {
      debugPrint(
        'ℹ️ [VideoView] Stream already attached for peer ${widget.peerId}',
      );
      return;
    }

    debugPrint(
      '🎥 [VideoView] Attaching stream ${widget.stream!.id} '
      'for peer ${widget.peerId}',
    );

    _renderer.srcObject = widget.stream;
    _attachedStream = widget.stream;

    // 🔥 SIGNAL renderer ready AFTER frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRendererReady?.call(widget.peerId);
      debugPrint(
        '▶️ [VideoView] Renderer ready for peer ${widget.peerId}',
      );
    });

    setState(() {});
  }

  @override
  void dispose() {
    debugPrint('🔚 [VideoView] Disposing renderer for ${widget.peerId}');
    try {
      _renderer.srcObject = null; // 🔥 VERY IMPORTANT
    } catch (_) {}
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.stream == null) {
      return const Center(child: Icon(Icons.person, size: 60));
    }

    return RTCVideoView(
      _renderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      mirror: widget.mirror,
    );
  }
}
