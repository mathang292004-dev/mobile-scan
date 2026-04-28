/// Model representing a member within an organization role
class OrgMember {
  /// Unique identifier for the member
  final String id;

  /// Member's full name
  final String name;

  /// Member's email address
  final String email;

  /// Member's avatar URL
  final String avatar;

  /// Whether the member is currently online
  final bool isOnline;

  /// Member's job title or position
  final String position;

  const OrgMember({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.isOnline,
    required this.position,
  });

  /// Checks if member matches the search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        email.toLowerCase().contains(lowerQuery) ||
        position.toLowerCase().contains(lowerQuery);
  }
}

