import 'dart:ui';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:flutter/material.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/data/model/chat_room/incident_user_response.dart';
import '../../models/chat_member_model.dart';
import 'member_list_item_widget.dart';

class AddMembersModal extends StatefulWidget {
  final List<ChatMember> teamMembers;
  final List<ChatMember> inviteMembers;
  final List<IncidentUser> incidentUsers;
  final Function(ChatMember)? onMemberRemoved;
  final Function(ChatMember)? onMemberAdded;

  const AddMembersModal({
    super.key,
    required this.teamMembers,
    required this.inviteMembers,
    required this.incidentUsers,
    this.onMemberRemoved,
    this.onMemberAdded,
  });

  @override
  State<AddMembersModal> createState() => _AddMembersModalState();
}

class _AddMembersModalState extends State<AddMembersModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatMember> get _filteredInviteMembers {
    if (_searchQuery.isEmpty) return widget.inviteMembers;
    return widget.inviteMembers
        .where((m) => m.matchesSearch(_searchQuery))
        .toList();
  }

  List<ChatMember> get _filteredTeamMembers {
    if (_searchQuery.isEmpty) return widget.teamMembers;
    return widget.teamMembers
        .where((m) => m.matchesSearch(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => back(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                    child: Container(
                      width: 324,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Add members',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C2C2E),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => back(),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF3DA229),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFF3DA229),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: AppTextField(
                              controller: _searchController,
                              onChanged: (v) {
                                setState(() => _searchQuery = v);
                              },
                              hint: 'Search by email address',
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 20,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          /// LIST
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.5,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// TEAM MEMBERS
                                  if (_filteredTeamMembers.isNotEmpty) ...[
                                    const Text(
                                      'Team Members',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6E6E6E),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ..._filteredTeamMembers.map(
                                      (member) => MemberListItem(
                                        member: member,
                                        actionType: 'delete',
                                        onActionPressed: () => widget
                                            .onMemberRemoved
                                            ?.call(member),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  /// INVITE MEMBERS
                                  if (_searchQuery.isEmpty)
                                    const Text(
                                      'Invite Members',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2E),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  ..._filteredInviteMembers.map(
                                    (member) => MemberListItem(
                                      member: member,
                                      actionType: 'add',
                                      onActionPressed: () =>
                                          widget.onMemberAdded?.call(member),
                                    ),
                                  ),
                                  if (_filteredInviteMembers.isEmpty &&
                                      _searchQuery.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No members found',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
