import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/data/model/call_models.dart';

class ChatHeaderWidget extends StatelessWidget {
  final String incidentId;
  final int onlineCount;
  final int totalMembers;

  final VoidCallback? onBackPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onVideoPressed;
  final VoidCallback? onMembersPressed;
  final VoidCallback? onMenuPressed;

  /// Whether there's an active call that can be joined
  final bool hasActiveCall;
  /// The type of active call (audio or video)
  final CallType? activeCallType;

  const ChatHeaderWidget({
    super.key,
    required this.incidentId,
    required this.onlineCount,
    required this.totalMembers,
    this.onBackPressed,
    this.onCallPressed,
    this.onVideoPressed,
    this.onMembersPressed,
    this.onMenuPressed,
    this.hasActiveCall = false,
    this.activeCallType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3DA229), Color(0xFF147B00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          /// Back
          GestureDetector(
            onTap: onBackPressed ?? () => back(),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),

          /// Group icon (rounded box)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD7FFD5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Image.asset(Assets.chatGroup, width: 26, height: 26),
            ),
          ),
          const SizedBox(width: 10),

          /// Incident text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incident # $incidentId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF51EB5C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$onlineCount Online',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha:0.9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: GestureDetector(
                        onTap: onMembersPressed,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.white.withValues(alpha:0.9),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$totalMembers Members',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha:0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// RIGHT SIDE – CLOUD + ICONS
          /// Push everything after incident info to the right

          /// RIGHT SIDE – CLOUD + ICONS (right corner)
          /// RIGHT SIDE – CLOUD + ICONS (NO EXTRA SPACE)
          Align(
            alignment: Alignment.centerRight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Cloud background
                Image.asset(Assets.chatHeader, height: 54, fit: BoxFit.contain),

                /// Icons on top
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _iconButton(
                      asset: Assets.chatAdd,
                      onTap: onMenuPressed ?? onMembersPressed,
                    ),
                    const SizedBox(width: 6),
                    // Audio call button with optional "Join Call" text
                    _callIconButton(
                      icon: Icons.call,
                      onTap: onCallPressed,
                      showJoinCall: hasActiveCall && activeCallType == CallType.audio,
                    ),
                    const SizedBox(width: 6),
                    // Video call button with optional "Join Call" text
                    _callIconButton(
                      asset: Assets.chatVideoIcon,
                      onTap: onVideoPressed,
                      showJoinCall: hasActiveCall && activeCallType == CallType.video,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable white icon button
Widget _iconButton({IconData? icon, String? asset, VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 20, color: const Color(0xFF3DA229))
            : Image.asset(asset!, width: 20, height: 20),
      ),
    ),
  );
}

/// Call icon button with optional "Join Call" text shown behind
Widget _callIconButton({
  IconData? icon,
  String? asset,
  VoidCallback? onTap,
  bool showJoinCall = false,
}) {
  if (!showJoinCall) {
    // Regular button without Join Call text
    return _iconButton(icon: icon, asset: asset, onTap: onTap);
  }

  // Button with "Join Call" text behind the icon
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3DA229).withValues(alpha:0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF3DA229).withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 16, color: const Color(0xFF3DA229))
                  : Image.asset(asset!, width: 16, height: 16),
            ),
          ),
          const SizedBox(width: 4),
          // Join Call text
          const Text(
            'Join',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3DA229),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    ),
  );
}
