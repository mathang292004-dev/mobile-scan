/// Model class representing a team member in the chat
class ChatMember {
  /// Unique identifier for the member
  final String id;

  /// Full name of the member
  final String name;

  /// Email address of the member
  final String email;

  /// Avatar/profile image URL or path
  final String avatar;

  /// Job role/title of the member
  final String role;

  /// Team name the member belongs to
  final String team;

  /// Whether the member is currently online
  final bool isOnline;

  /// Whether the member is already in the chat
  final bool isTeamMember;

  /// Contact number (optional)
  final String? contactNumber;

  /// Whether the member is muted in call (for call screens)
  final bool isMuted;

  ChatMember({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.role,
    required this.team,
    this.isOnline = false,
    this.isTeamMember = false,
    this.contactNumber,
    this.isMuted = false,
  });

  /// Factory constructor to create a ChatMember from JSON
  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String,
      role: json['role'] as String,
      team: json['team'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      isTeamMember: json['isTeamMember'] as bool? ?? false,
      contactNumber: json['contactNumber'] as String?,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  /// Convert ChatMember to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'team': team,
      'isOnline': isOnline,
      'isTeamMember': isTeamMember,
      'contactNumber': contactNumber,
      'isMuted': isMuted,
    };
  }

  /// Create a copy of ChatMember with optional field updates
  ChatMember copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    String? team,
    bool? isOnline,
    bool? isTeamMember,
    String? contactNumber,
    bool? isMuted,
  }) {
    return ChatMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      team: team ?? this.team,
      isOnline: isOnline ?? this.isOnline,
      isTeamMember: isTeamMember ?? this.isTeamMember,
      contactNumber: contactNumber ?? this.contactNumber,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  /// Check if member matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        email.toLowerCase().contains(lowerQuery) ||
        (contactNumber?.toLowerCase().contains(lowerQuery) ?? false);
  }
}
