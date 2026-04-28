import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import '../../models/chat_member_model.dart';
import 'package:emergex/generated/assets.dart';
/// Individual participant card showing avatar/video and status
class ParticipantCardWidget extends StatelessWidget {
  final ChatMember member;
  final bool isVideoCall;
  final bool isCurrentUser;
  final bool isVideoOff;

  const ParticipantCardWidget({
    super.key,
    required this.member,
    required this.isVideoCall,
    this.isCurrentUser = false,
    this.isVideoOff = false,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorHelper.white.withAlpha((0.9 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x1F3DA229),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Video/Avatar content
          if (isVideoCall)
            _buildVideoContent()
          else
            _buildAudioContent(),

          // Bottom overlay with name and mute status
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Row(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    /// Name badge — FIXED
    Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0x80000000),
          borderRadius: BorderRadius.circular(45),
        ),
        child: Text(
          member.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ColorHelper.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    ),

    const SizedBox(width: 8),

    /// Mute icon — fixed size
    Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: member.isMuted
            ? const Color(0xFFFF4037)
            : const Color(0xFF3DA229),
        shape: BoxShape.circle,
      ),
     child: Center(
  child: member.isMuted
      ? Image.asset(
          Assets.mutemic, // muted mic asset
          width: 16,
          height: 16,
          color: ColorHelper.white,
        )
      : Image.asset(
    Assets.callmic,
    width: 16,
    height: 16,
    color: ColorHelper.white,
  ),
     ),
),

  ],
),

          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    // For video calls, show placeholder image or video feed
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFFECF6EA),
        child: Center(
          child: Icon(
            Icons.person,
            size: 60,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioContent() {
    // For audio calls, show large initials in center
    return Center(
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF3DA229),
            width: 2,
          ),
          color: Colors.transparent,
        ),
        child: Center(
          child: Text(
            _getInitials(member.name),
            style: const TextStyle(
              color: Color(0xFF3DA229),
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}
