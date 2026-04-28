import 'package:emergex/generated/assets.dart';
import 'package:flutter/material.dart';
import '../../models/chat_member_model.dart';

class MemberListItem extends StatelessWidget {
  final ChatMember member;
  final VoidCallback? onActionPressed;
  final String actionType; // 'delete' | 'add'

  const MemberListItem({
    super.key,
    required this.member,
    this.onActionPressed,
    this.actionType = 'add',
  });

  @override
  Widget build(BuildContext context) {
    final bool isDelete = actionType == 'delete';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          /// AVATAR + ONLINE DOT
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  member.avatar,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: Colors.grey.shade500,
                      ),
                    );
                  },
                ),
              ),

              /// ONLINE STATUS DOT
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: member.isOnline
                        ? const Color(0xFF00D26A)
                        : const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          /// NAME + EMAIL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272727),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          /// ACTION ICON
          GestureDetector(
            onTap: onActionPressed,
            child: isDelete
                ? Image.asset(
                  Assets.reportIncidentRecycleBin,
                  width: 16,
                  height: 16,
                  color: Color(0xFFE53935),
                )
                : const Icon(
                  Icons.add,
                  size: 16,
                  color: Color(0xFF3DA229),
                ),
          ),
        ],
      ),
    );
  }
}
