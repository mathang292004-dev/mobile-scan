import 'package:equatable/equatable.dart';

/// Fetch Members Response Model
class FetchMembersResponse extends Equatable {
  final List<Member> members;
  final int totalMembers;

  const FetchMembersResponse({
    required this.members,
    required this.totalMembers,
  });

  factory FetchMembersResponse.fromJson(Map<String, dynamic> json) {
    // Handle both 'members' and 'users' keys for API compatibility
    final membersList = json['members'] ?? json['users'];
    return FetchMembersResponse(
      members: membersList is List
          ? membersList
              .whereType<Map<String, dynamic>>()
              .map((e) => Member.fromJson(e))
              .toList()
          : [],
      totalMembers: json['totalMembers'] as int? ?? 
          (membersList is List ? membersList.length : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'members': members.map((e) => e.toJson()).toList(),
      'totalMembers': totalMembers,
    };
  }

  @override
  List<Object?> get props => [members, totalMembers];
}

/// Member Model
class Member extends Equatable {
  final String userId;
  final String name;
  final String email;

  const Member({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [userId, name, email];
}

