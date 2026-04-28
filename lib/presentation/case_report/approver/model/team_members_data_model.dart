class Phone {
  final List<String> deskPh;
  final List<String> mobilePh;

  Phone({required this.deskPh, required this.mobilePh});

  factory Phone.fromJson(Map<String, dynamic> json) {
    return Phone(
      deskPh: List<String>.from(json['desk_ph'] ?? []),
      mobilePh: List<String>.from(json['mobile_ph'] ?? []),
    );
  }
}

class UserDetail {
  final String roleId;
  final String roleName;
  final String name;
  final String email;
  final Phone phone;

  UserDetail({
    required this.roleId,
    required this.roleName,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      roleId: json['roleId'] ?? '',
      roleName: json['roleName'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: Phone.fromJson(json['phone'] ?? {}),
    );
  }
}

class Task {
  final String taskId;
  final String long;
  final String short;

  Task({required this.taskId, required this.long, required this.short});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId'] ?? '',
      long: json['long'] ?? '',
      short: json['short'] ?? '',
    );
  }
}

class TeamMembersData {
  final List<UserDetail> userDetails;
  final List<Task> tasks;

  TeamMembersData({required this.userDetails, required this.tasks});

  factory TeamMembersData.fromJson(Map<String, dynamic> json) {
    return TeamMembersData(
      userDetails:
          (json['userDetails'] as List?)
              ?.map((x) => UserDetail.fromJson(x))
              .toList() ??
          [],
      tasks:
          (json['task'] as List?)?.map((x) => Task.fromJson(x)).toList() ?? [],
    );
  }
}
