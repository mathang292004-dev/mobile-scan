import 'org_member_model.dart';

/// Model representing a role/position in the organization hierarchy
class OrgRole {
  /// Unique identifier for the role
  final String id;

  /// Role title (e.g., "CEO", "Manager", "Team Lead")
  final String title;

  /// List of members assigned to this role
  final List<OrgMember> members;

  /// Child roles reporting to this role
  final List<OrgRole> children;

  /// Hierarchy level (0 = top level, 1 = second level, etc.)
  final int level;

  /// Color for the role node (green for top, yellow for middle, orange for lower)
  final String colorCode;

  const OrgRole({
    required this.id,
    required this.title,
    required this.members,
    required this.children,
    required this.level,
    required this.colorCode,
  });

  /// Returns the total number of members in this role
  int get memberCount => members.length;

  /// Returns the number of online members
  int get onlineMemberCount =>
      members.where((member) => member.isOnline).length;

  /// Checks if the role has any children
  bool get hasChildren => children.isNotEmpty;
}

