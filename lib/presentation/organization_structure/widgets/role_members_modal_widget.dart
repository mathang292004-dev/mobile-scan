import 'dart:ui';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:flutter/material.dart';
import '../model/org_role_model.dart';
import '../model/org_member_model.dart';

/// Modal widget showing all members of a selected role in bottom sheet style
/// Displays member avatars, names, emails, and online status (Figma design)
class RoleMembersModal extends StatefulWidget {
  /// The role whose members to display
  final OrgRole role;

  const RoleMembersModal({super.key, required this.role});

  @override
  State<RoleMembersModal> createState() => _RoleMembersModalState();
}

class _RoleMembersModalState extends State<RoleMembersModal> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => back(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBEBEB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 0.5),
                      left: BorderSide(color: Colors.white, width: 0.5),
                      right: BorderSide(color: Colors.white, width: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Green header
                      Container(
                        width: double.infinity,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3DA229),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.41),
                              blurRadius: 13.5,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Role Members Lists',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                          ),
                        ),
                      ),
                      // Members list
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 16,
                            bottom: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: widget.role.members.isEmpty
                              ? Center(
                                  child: Text(
                                    'No members assigned to this role',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[600],
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: widget.role.members.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    return _MemberItem(
                                      member: widget.role.members[index],
                                    );
                                  },
                                ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal widget for displaying a single member item
class _MemberItem extends StatelessWidget {
  final OrgMember member;

  const _MemberItem({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Color.fromARGB(255, 254, 255, 253),
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar with online status
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  children: [
                    ClipOval(
                      child: Image.network(
                        member.avatar,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 24,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: member.isOnline
                              ? const Color(0xFF4CD964)
                              : const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.email,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
