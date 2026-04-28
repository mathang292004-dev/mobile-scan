class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profile;
  final String status;
  final List<String> roles;
  final List<String> projects;
  final String createdAt;

  bool get isActive => status.toLowerCase() == 'active';

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profile = '',
    this.status = '',
    this.roles = const [],
    this.projects = const [],
    this.createdAt = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profile: json['profile']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      roles:
          (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      projects:
          (json['projects'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class UserStatsModel {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;

  const UserStatsModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      inactiveUsers: json['inactiveUsers'] ?? 0,
    );
  }
}
