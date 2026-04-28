import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:emergex/generated/assets.dart';

class CustomAudioPlayer extends StatefulWidget {
  final String fileName;
  final String fileUrl;

  const CustomAudioPlayer({
    super.key,
    required this.fileName,
    required this.fileUrl,
  });

  @override
  State<CustomAudioPlayer> createState() => _CustomAudioPlayerState();
}

class _CustomAudioPlayerState extends State<CustomAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isPlaying = false;
  String? localFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _downloadAndPrepareAudio();
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() {
        _duration = d;
      });
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  Future<void> _downloadAndPrepareAudio() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${widget.fileName}');
      if (!await file.exists()) {
        await Dio().download(widget.fileUrl, file.path);
      }
      localFilePath = file.path;
      await _audioPlayer.setSourceDeviceFile(localFilePath!);
    } catch (e) {
      debugPrint(" Audio download/prep failed: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: ColorHelper.surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.surfaceColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: ColorHelper.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(Assets.mp3, width: 18, height: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fileName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ColorHelper.textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  if (localFilePath == null) return;

                  if (isPlaying) {
                    await _audioPlayer.pause();
                    setState(() => isPlaying = false);
                  } else {
                    try {
                      if (_position >= _duration ||
                          _position == Duration.zero) {
                        await _audioPlayer.play(
                          DeviceFileSource(localFilePath!),
                        );
                      } else {
                        try {
                          await _audioPlayer.resume();
                        } catch (e) {
                          await _audioPlayer.play(
                            DeviceFileSource(localFilePath!),
                          );
                          await _audioPlayer.seek(_position);
                        }
                      }
                      setState(() => isPlaying = true);
                    } catch (e) {
                      debugPrint("Error playing audio: $e");
                    }
                  }
                },
                child: Image.asset(
                  isPlaying ? Assets.pause : Assets.play,
                  width: 18,
                  height: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,

                    // ---- Thumb Style (white circle) ----
                    thumbShape: const BorderedThumbShape(
                      thumbRadius: 8,
                      borderColor: ColorHelper.primaryColor,
                    ),
                    thumbColor: Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,

                    // ---- Track Colors ----
                    activeTrackColor: ColorHelper.primaryColor, // Green
                    inactiveTrackColor: Colors.grey.shade300, // Light grey
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds
                        .clamp(0, _duration.inSeconds)
                        .toDouble(),
                    onChanged: (value) async {
                      final newPos = Duration(seconds: value.toInt());
                      await _audioPlayer.seek(newPos);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ColorHelper.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class BorderedThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final Color borderColor;

  const BorderedThumbShape({
    this.thumbRadius = 8,
    this.borderColor = Colors.green,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Outer Border Circle
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Inner White Fill
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}
