import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:emergex/generated/color_helper.dart';
import '../../models/chat_member_model.dart';
import 'package:emergex/generated/assets.dart';

/// Grid widget displaying all video call participants
class VideoParticipantGridWidget extends StatelessWidget {
  final List<ChatMember> participants;
  final bool currentUserMuted;
  final bool currentUserVideoOff;
  final bool isFrontCamera;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onVideoToggle;
  final VoidCallback? onCameraSwitch;
  final VoidCallback? onEndCall;
  final String? currentUserAvatar;
  final String? currentUserName;
  final RTCVideoRenderer? localRenderer;
  final Map<String, RTCVideoRenderer> remoteRenderers;
  final Map<String, bool> participantVideoOff;
  final Map<String, bool> participantMuted;
  final Map<String, bool>
  participantFrontCamera; // Track which camera each participant is using

  const VideoParticipantGridWidget({
    super.key,
    required this.participants,
    this.currentUserMuted = false,
    this.currentUserVideoOff = false,
    this.isFrontCamera = true,
    this.onMuteToggle,
    this.onVideoToggle,
    this.onCameraSwitch,
    this.onEndCall,
    this.currentUserAvatar,
    this.currentUserName,
    this.localRenderer,
    required this.remoteRenderers,
    this.participantVideoOff = const {},
    this.participantMuted = const {},
    this.participantFrontCamera = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Detect duplicate names and create display names
    final Map<String, String> participantDisplayNames = {};
    final Map<String, int> nameCount = {};

    // Count occurrences of each name
    for (final participant in participants) {
      nameCount[participant.name] = (nameCount[participant.name] ?? 0) + 1;
    }

    // Create display names - show "Participant" for duplicates
    for (final participant in participants) {
      if (nameCount[participant.name]! > 1) {
        // This is a duplicate name - show as "Participant"
        participantDisplayNames[participant.id] = 'Participant';
      } else {
        // Unique name
        participantDisplayNames[participant.id] = participant.name;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildMainUserCard(),
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
                  final participant = participants[index];
                  final renderer = remoteRenderers[participant.id];
                  final isVideoOff =
                      participantVideoOff[participant.id] ?? false;
                  final isMuted =
                      participantMuted[participant.id] ?? participant.isMuted;
                  final isParticipantFrontCamera =
                      participantFrontCamera[participant.id] ?? true;
                  final displayName = participantDisplayNames[participant.id] ?? participant.name;

                  return _buildParticipantCard(
                    participant: participant,
                    displayName: displayName,
                    renderer: renderer,
                    isVideoOff: isVideoOff,
                    isMuted: isMuted,
                    isFrontCamera: isParticipantFrontCamera,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// MAIN USER CARD
  Widget _buildMainUserCard() {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFFECF6EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1F3DA229)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            /// VIDEO / AVATAR
            if (!currentUserVideoOff && localRenderer?.srcObject != null)
              Positioned.fill(
                  child: RTCVideoView(
                    localRenderer!,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
              )
            else
              Positioned.fill(
                child: Center(child: _buildAvatar(currentUserName ?? 'You')),
              ),

            /// CONTROLS
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButtonAsset(
                    assetPath: currentUserMuted
                        ? Assets.mutemic
                        : Assets.callmic,
                    backgroundColor: currentUserMuted
                        ? const Color(0xFFFF4037)
                        : ColorHelper.white,
                    tintColor: currentUserMuted
                        ? ColorHelper.white
                        : const Color(0xFF3DA229),
                    onPressed: onMuteToggle,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onVideoToggle,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: currentUserVideoOff
                            ? const Color(0xFFFF4037)
                            : ColorHelper.white,
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
                        child: currentUserVideoOff
                            ? Icon(
                                Icons.videocam_off_rounded,
                                size: 22,
                                color: ColorHelper.white,
                              )
                            : Image.asset(
                                Assets.chatVideoIcon,
                                width: 22,
                                height: 22,
                                color: const Color(0xFF3DA229),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onCameraSwitch,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ColorHelper.white,
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
                        child: Icon(
                          Icons.cameraswitch_rounded,
                          size: 22,
                          color: const Color(0xFF3DA229),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildControlButtonAsset(
                    assetPath: Assets.callcut,
                    backgroundColor: const Color(0xFFFF4037),
                    tintColor: ColorHelper.white,
                    onPressed: onEndCall,
                    size: 48,
                  ),
                ],
              ),
            ),

            /// USER BADGE
            Positioned(top: 12, left: 12, child: _buildUserBadge()),

            /// AUDIO INDICATOR (only when not muted)
            if (!currentUserMuted)
              Positioned(top: 12, right: 12, child: _buildAudioIndicator()),
          ],
        ),
      ),
    );
  }

  /// PARTICIPANT CARD
  Widget _buildParticipantCard({
    required ChatMember participant,
    required String displayName,
    RTCVideoRenderer? renderer,
    required bool isVideoOff,
    required bool isMuted,
    required bool isFrontCamera,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECF6EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1F3DA229)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (!isVideoOff && renderer?.srcObject != null)
              Positioned.fill(
                child: _RotationAwareVideoView(
                  renderer: renderer!,
                  isFrontCamera: isFrontCamera,
                ),
              )
            else
              Center(child: _buildAvatar(participant.name)),

            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Flexible(child: _buildNameBadge(displayName)),
                  const SizedBox(width: 8),
                  _buildMuteIndicator(isMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HELPERS

  Widget _buildAvatar(String name) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3DA229), width: 2),
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: Color(0xFF3DA229),
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtonAsset({
    required String assetPath,
    required Color backgroundColor,
    Color? tintColor,
    VoidCallback? onPressed,
    double size = 52,
  }) {
    final iconSize = size * 0.46;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
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
            width: iconSize,
            height: iconSize,
            color: tintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMuteIndicator(bool isMuted) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isMuted ? const Color(0xFFFF4037) : const Color(0xFF3DA229),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          isMuted ? Assets.mutemic : Assets.callmic,
          width: 16,
          height: 16,
          color: ColorHelper.white,
        ),
      ),
    );
  }

  Widget _buildNameBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(45),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: ColorHelper.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Text(
        'You',
        style: TextStyle(
          color: ColorHelper.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAudioIndicator() {
    return Container(
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
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Video view widget that auto-rotates based on video dimensions
/// When video width > height (landscape) but container is portrait, rotate 90 degrees
class _RotationAwareVideoView extends StatefulWidget {
  final RTCVideoRenderer renderer;
  final bool isFrontCamera;

  const _RotationAwareVideoView({
    required this.renderer,
    this.isFrontCamera = true,
  });

  @override
  State<_RotationAwareVideoView> createState() =>
      _RotationAwareVideoViewState();
}

class _RotationAwareVideoViewState extends State<_RotationAwareVideoView> {
  int _videoWidth = 0;
  int _videoHeight = 0;

  @override
  void initState() {
    super.initState();
    widget.renderer.addListener(_onVideoSizeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onVideoSizeChanged());
  }

  @override
  void didUpdateWidget(_RotationAwareVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.renderer != widget.renderer) {
      oldWidget.renderer.removeListener(_onVideoSizeChanged);
      widget.renderer.addListener(_onVideoSizeChanged);
      _onVideoSizeChanged();
    }
  }

  @override
  void dispose() {
    widget.renderer.removeListener(_onVideoSizeChanged);
    super.dispose();
  }

  void _onVideoSizeChanged() {
    if (!mounted) return;

    final videoWidth = widget.renderer.videoWidth;
    final videoHeight = widget.renderer.videoHeight;

    if (videoWidth > 0 && videoHeight > 0) {
      if (_videoWidth != videoWidth || _videoHeight != videoHeight) {
        setState(() {
          _videoWidth = videoWidth;
          _videoHeight = videoHeight;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {

        // If no valid video dimensions yet, show without rotation
        if (_videoWidth <= 0 || _videoHeight <= 0) {
          // Apply 180° rotation for front camera even without video dimensions
          if (widget.isFrontCamera) {
            return Transform.rotate(
              angle: 3.14159, // 180 degrees (π)
              child: RTCVideoView(
                widget.renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            );
          }
          return RTCVideoView(
            widget.renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          );
        }


        // Apply 90° rotation for mobile videos
        // Note: This rotates ALL videos. For web support, need to add isMobile parameter
        // to distinguish web participants (no rotation) from mobile (needs rotation)
        return Transform.rotate(
          angle: widget.isFrontCamera ? -1.5708 : 1.5708, // ±90 degrees
          child: RTCVideoView(
            widget.renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        );
      },
    );
  }
}
