class ManualTaskEntry {
  final String taskTitle;
  final String taskDetails;

  const ManualTaskEntry({required this.taskTitle, required this.taskDetails});
}

class AssignedTaskModel {
  final String taskId;
  final String taskTitle;
  final String taskDetails;
  final String libraryTaskId;
  final String status;

  AssignedTaskModel({
    required this.taskId,
    required this.taskTitle,
    required this.taskDetails,
    required this.libraryTaskId,
    required this.status,
  });

  factory AssignedTaskModel.fromJson(Map<String, dynamic> json) {
    return AssignedTaskModel(
      taskId: json['taskId']?.toString() ?? '',
      taskTitle:
          json['taskTitle']?.toString() ?? json['taskName']?.toString() ?? '',
      taskDetails: json['taskDetails']?.toString() ?? '',
      libraryTaskId: json['libraryTaskId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class EligibleUserModel {
  final String userId;
  final String name;
  final String email;
  final String profile;
  final int taskCount;
  final String role;
  final bool isCurrentTl;
  final bool isCurrentMember;
  final List<AssignedTaskModel> assignedTasks;

  EligibleUserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.profile,
    required this.taskCount,
    required this.role,
    required this.isCurrentTl,
    required this.isCurrentMember,
    required this.assignedTasks,
  });

  factory EligibleUserModel.fromJson(Map<String, dynamic> json) {
    return EligibleUserModel(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profile: json['profile']?.toString() ?? '',
      taskCount: (json['taskCount'] as num?)?.toInt() ?? 0,
      role: json['role']?.toString() ?? '',
      isCurrentTl: json['isCurrentTl'] == true,
      isCurrentMember: json['isCurrentMember'] == true,
      assignedTasks:
          (json['assignedTasks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((t) => AssignedTaskModel.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class EligibleTaskModel {
  final String taskId;
  final String taskTitle;
  final String taskDetails;
  final String libraryTaskId;
  final String status;

  EligibleTaskModel({
    required this.taskId,
    required this.taskTitle,
    required this.taskDetails,
    required this.libraryTaskId,
    required this.status,
  });

  factory EligibleTaskModel.fromJson(Map<String, dynamic> json) {
    return EligibleTaskModel(
      taskId: json['taskId']?.toString() ?? '',
      taskTitle:
          json['taskTitle']?.toString() ?? json['taskName']?.toString() ?? '',
      taskDetails: json['taskDetails']?.toString() ?? '',
      libraryTaskId: json['libraryTaskId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class TaskCategoryModel {
  final String category;
  final List<EligibleTaskModel> tasks;

  TaskCategoryModel({required this.category, required this.tasks});

  factory TaskCategoryModel.fromJson(Map<String, dynamic> json) {
    return TaskCategoryModel(
      category: json['category']?.toString() ?? '',
      tasks:
          (json['tasks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((t) => EligibleTaskModel.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class ReassignEligibleUsersResponse {
  final List<EligibleUserModel> users;
  final List<EligibleTaskModel> tasks;
  final List<TaskCategoryModel> categoryTasks;
  final List<AssignedTaskModel> assignedTasks;

  ReassignEligibleUsersResponse({
    required this.users,
    required this.tasks,
    required this.categoryTasks,
    required this.assignedTasks,
  });

  factory ReassignEligibleUsersResponse.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'];

    List<TaskCategoryModel> categoryTasks = [];
    List<EligibleTaskModel> flatTasks = [];

    if (rawTasks is List && rawTasks.isNotEmpty) {
      final first = rawTasks.first;
      if (first is Map && first.containsKey('category')) {
        // Categorized format: [{category, tasks:[...]}]
        categoryTasks =
            rawTasks
                .whereType<Map<String, dynamic>>()
                .map((c) => TaskCategoryModel.fromJson(c))
                .toList();
        flatTasks = categoryTasks.expand((c) => c.tasks).toList();
      } else {
        // Flat format: [{taskTitle, ...}]
        flatTasks =
            rawTasks
                .whereType<Map<String, dynamic>>()
                .map((t) => EligibleTaskModel.fromJson(t))
                .toList();
      }
    } else if (rawTasks is Map) {
      final ertTasks = (rawTasks['ertTasks'] as List? ?? []);
      flatTasks =
          ertTasks
              .whereType<Map<String, dynamic>>()
              .map((t) => EligibleTaskModel.fromJson(t))
              .toList();
    }

    return ReassignEligibleUsersResponse(
      users:
          (json['users'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((u) => EligibleUserModel.fromJson(u))
              .toList() ??
          [],
      tasks: flatTasks,
      categoryTasks: categoryTasks,
      assignedTasks:
          (json['assigned_tasks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((t) => AssignedTaskModel.fromJson(t))
              .toList() ??
          [],
    );
  }
}
