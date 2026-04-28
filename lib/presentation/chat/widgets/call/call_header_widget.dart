import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';

/// Header widget for call screens showing incident info and member count
class CallHeaderWidget extends StatelessWidget {
  final String incidentId;
  final int onlineCount;
  final int totalMembers;
  final VoidCallback onBackPressed;
  final VoidCallback? onChatPressed;
  final VoidCallback? onMembersPressed;
  final VoidCallback? onAddMemberPressed;

  const CallHeaderWidget({
    super.key,
    required this.incidentId,
    required this.onlineCount,
    required this.totalMembers,
    required this.onBackPressed,
    this.onChatPressed,
    this.onMembersPressed,
    this.onAddMemberPressed,
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
          /// BACK
          
          const SizedBox(width: 6),

          /// GROUP ICON (SAME AS CHAT HEADER)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD7FFD5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Image.asset(
                Assets.chatGroup,
                width: 26,
                height: 26,
              ),
            ),
          ),
          const SizedBox(width: 10),

          /// INCIDENT INFO
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incident $incidentId',
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
                    Text(
                      '$onlineCount Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha:0.9),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onMembersPressed,
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: Colors.white.withValues(alpha:0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalMembers Members',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha:0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// ADD MEMBER BUTTON (CHAT HEADER STYLE)
          _iconButton(
            asset: Assets.chatAdd,
            onTap: onAddMemberPressed,
          ),
          const SizedBox(width: 6),

          /// MESSAGE BUTTON
          _iconButton(
            asset: Assets.message,
            onTap: onChatPressed ?? onBackPressed,
          ),
        ],
      ),
    );
  }
}

/// Reusable white icon button (same as chat header)
Widget _iconButton({required String asset, VoidCallback? onTap}) {
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
        child: Image.asset(
          asset,
          width: 20,
          height: 20,
          color: const Color(0xFF3DA229),
        ),
      ),
    ),
  );
}
