import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class VoiceRecordingVisualization extends StatelessWidget {
  final bool isListening;
  final bool isPaused;
  final AnimationController waveController;
  final List<double> audioLevels;

  const VoiceRecordingVisualization({
    super.key,
    required this.isListening,
    required this.isPaused,
    required this.waveController,
    this.audioLevels = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isListening || isPaused ? 100 : 0,
      child: isListening
          ? _buildWaveform(true)
          : isPaused
          ? _buildWaveform(false)
          : const SizedBox(),
    );
  }

  Widget _buildWaveform(bool isAnimate) {
    return AnimatedBuilder(
      animation: waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(12, (index) {
            double barHeight;
            if (isAnimate &&
                audioLevels.isNotEmpty &&
                index < audioLevels.length) {
              final audioLevel = audioLevels[index];
              final scaledLevel = (audioLevel * 10).clamp(0.0, 10.0);
              if (scaledLevel > 5) {
                barHeight = scaledLevel * 5;
              } else {
                barHeight = scaledLevel * 2;
              }
            } else {
              barHeight = 2;
            }

            return Container(
              width: 6,
              height: barHeight,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: ColorHelper.successColor,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}
