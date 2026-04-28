import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import '../../models/chat_member_model.dart';
import 'participant_card_widget.dart';
import 'package:emergex/generated/assets.dart';

/// Grid widget displaying all call participants
class CallParticipantGridWidget extends StatelessWidget {
  final List<ChatMember> participants;
  final bool isVideoCall;
  final bool currentUserMuted;
  final bool currentUserVideoOff;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onEndCall;
  final String? currentUserAvatar;

  const CallParticipantGridWidget({
    super.key,
    required this.participants,
    required this.isVideoCall,
    this.currentUserMuted = false,
    this.currentUserVideoOff = false,
    this.onMuteToggle,
    this.onEndCall,
    this.currentUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = ChatMember(
      id: 'currentUser',
      name: 'You',
      email: 'you@example.com',
      avatar: currentUserAvatar ?? '',
      isOnline: true,
      isTeamMember: true,
      role: 'Team Leader',
      team: 'Emergency Response',
      isMuted: currentUserMuted,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildMainUserCard(currentUser),
          const SizedBox(height: 12),

          if (participants.isNotEmpty)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  return ParticipantCardWidget(
                    member: participants[index],
                    isVideoCall: isVideoCall,
                    isCurrentUser: false,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Main user card
  Widget _buildMainUserCard(ChatMember currentUser) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFFECF6EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1F3DA229), width: 1),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(),
                const SizedBox(height: 60),

                /// CONTROL BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// MIC BUTTON (ASSET)
                    _buildControlButton(
                      assetPath: currentUserMuted
                          ? Assets
                                .mutemic // muted icon
                          : Assets.callmic, // normal mic

                      backgroundColor: currentUserMuted
                          ? const Color(0xFFFF4037)
                          : ColorHelper.white,
                      tintColor: currentUserMuted
                          ? ColorHelper.white
                          : const Color(0xFF3DA229),
                      onPressed: onMuteToggle,
                    ),
                    const SizedBox(width: 20),

                    /// CALL CUT BUTTON (ASSET)
                    _buildControlButton(
                      assetPath: Assets.callcut,
                      backgroundColor: const Color(0xFFFF4037),
                      tintColor: ColorHelper.white,
                      onPressed: onEndCall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// TOP LEFT USER BADGE
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x66000000),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF3DA229),
                    backgroundImage: currentUser.avatar.isNotEmpty
                        ? NetworkImage(currentUser.avatar)
                        : null,
                    child: currentUser.avatar.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'You',
                    style: TextStyle(
                      color: ColorHelper.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// TOP RIGHT AUDIO INDICATOR
          if (!currentUserMuted)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x66000000),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'II|II',
                  style: TextStyle(
                    color: ColorHelper.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// AVATAR (CURRENT USER ONLY)
  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3DA229), width: 2.5),
      ),
      child: ClipOval(
        child: currentUserAvatar != null && currentUserAvatar!.isNotEmpty
            ? Image.network(
                currentUserAvatar!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildYouFallback(),
              )
            : _buildYouFallback(),
      ),
    );
  }

  Widget _buildYouFallback() {
    return Container(
      color: const Color(0xFFEAF2E8),
      child: const Center(
        child: Text(
          'YO',
          style: TextStyle(
            color: Color(0xFF3DA229),
            fontSize: 36,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  /// CONTROL BUTTON (ASSET BASED)
  Widget _buildControlButton({
    required String assetPath,
    required Color backgroundColor,
    Color? tintColor,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 26,
            height: 26,
            color: tintColor,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
