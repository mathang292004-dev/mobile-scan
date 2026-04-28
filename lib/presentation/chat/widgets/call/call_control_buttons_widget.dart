import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

/// Control buttons for call screens (mute, video, end call)
class CallControlButtonsWidget extends StatelessWidget {
  final bool isMuted;
  final bool isVideoEnabled;
  final VoidCallback onMuteToggle;
  final VoidCallback onVideoToggle;
  final VoidCallback onEndCall;
  final bool isAudioCall;

  const CallControlButtonsWidget({
    super.key,
    required this.isMuted,
    required this.isVideoEnabled,
    required this.onMuteToggle,
    required this.onVideoToggle,
    required this.onEndCall,
    this.isAudioCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute/Unmute button with visual feedback
        _buildControlButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          backgroundColor: isMuted ? const Color(0xFFFF4037) : ColorHelper.white,
          iconColor: isMuted ? ColorHelper.white : const Color(0xFF3DA229),
          onPressed: onMuteToggle,
          label: isMuted ? 'Unmute' : 'Mute',
        ),

        const SizedBox(width: 16),

        // Video toggle button (or switch to video for audio calls)
        if (!isAudioCall)
          _buildControlButton(
            icon: isVideoEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            backgroundColor: !isVideoEnabled ? const Color(0xFFFF4037) : ColorHelper.white,
            iconColor: !isVideoEnabled ? ColorHelper.white : const Color(0xFF3DA229),
            onPressed: onVideoToggle,
            label: isVideoEnabled ? 'Stop Video' : 'Start Video',
          )
        else
          _buildControlButton(
            icon: Icons.videocam_rounded,
            backgroundColor: ColorHelper.white,
            iconColor: const Color(0xFF3DA229),
            onPressed: onVideoToggle,
            label: 'Video',
          ),

        const SizedBox(width: 16),

        // End call button
        _buildControlButton(
          icon: Icons.call_end_rounded,
          backgroundColor: const Color(0xFFFF4037),
          iconColor: ColorHelper.white,
          onPressed: onEndCall,
          label: 'End',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
    String? label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000), // 10% opacity black
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon),
            iconSize: 24,
            color: iconColor,
            onPressed: onPressed,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2C3E2A),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ],
    );
  }
}
