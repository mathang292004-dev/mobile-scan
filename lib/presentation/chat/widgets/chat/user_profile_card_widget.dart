import 'package:flutter/material.dart';
import '../../models/chat_member_model.dart';
import 'online_status_indicator_widget.dart';
import 'dart:ui';

/// A compact popup card showing user profile details
/// Displayed when tapping on a user's avatar in the chat
class UserProfileCard extends StatelessWidget {
  /// The member whose profile to display
  final ChatMember member;

  /// Callback when email button is pressed
  final VoidCallback? onEmailPressed;

  const UserProfileCard({super.key, required this.member, this.onEmailPressed});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with online indicator
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        member.avatar,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: OnlineStatusIndicator(
                        isOnline: member.isOnline,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Name
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2E),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Role and Team
              Text(
                '${member.role} • ${member.team}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7D7D7D),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Email button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DA229),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
