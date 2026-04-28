import 'package:equatable/equatable.dart';

/// Upload Documents Onboarding Model
class OnboardingOrganizationStructure extends Equatable {
  final List<Role>? roles;
  final List<Task>? tasks;
  final List<User>? users;

  const OnboardingOrganizationStructure({this.roles, this.tasks, this.users});

  factory OnboardingOrganizationStructure.fromJson(Map<String, dynamic> json) {
    return OnboardingOrganizationStructure(
      roles: json['roles'] is List
          ? (json['roles'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Role.fromJson(e))
                .toList()
          : null,
      tasks: json['tasks'] is List
          ? (json['tasks'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Task.fromJson(e))
                .toList()
          : null,
      users: json['users'] is List
          ? (json['users'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => User.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roles': roles?.map((e) => e.toJson()).toList(),
      'tasks': tasks?.map((e) => e.toJson()).toList(),
      'users': users?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [roles, tasks, users];
}

/// Role Model
class Role extends Equatable {
  final String? roleId;
  final String? roleName;
  final String? description;
  final String? designation;
  final List<FeaturePermission>? permissions;

  const Role({
    this.roleId,
    this.roleName,
    this.description,
    this.designation,
    this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['role_id']?.toString() ?? json['roleId']?.toString(),
      roleName: json['role_name']?.toString() ?? json['roleName']?.toString(),
      description: json['description']?.toString(),
      designation: json['designation']?.toString(),
      permissions: json['permissions'] is List
          ? (json['permissions'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => FeaturePermission.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'roleName': roleName,
      'description': description,
      'designation': designation,
      'permissions': permissions?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    roleId,
    roleName,
    description,
    designation,
    permissions,
  ];
}

/// Feature Permission Model
class FeaturePermission extends Equatable {
  final String? featureName;
  final String? moduleName;
  final String? featureId;
  final String? desc;
  final String? moduleDesc;
  final PermissionActions? permissions;

  const FeaturePermission({
    this.featureName,
    this.moduleName,
    this.featureId,
    this.desc,
    this.moduleDesc,
    this.permissions,
  });

  factory FeaturePermission.fromJson(Map<String, dynamic> json) {
    return FeaturePermission(
      featureName: json['featureName']?.toString() ?? json['name']?.toString(),
      moduleName: json['moduleName']?.toString(),
      featureId: json['featureId']?.toString(),
      desc: json['desc']?.toString(),
      moduleDesc: json['moduleDesc']?.toString(),
      permissions: json['permissions'] != null
          ? PermissionActions.fromJson(
              json['permissions'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'featureName': featureName,
      'moduleName': moduleName,
      if (featureId != null) 'featureId': featureId,
      if (desc != null) 'desc': desc,
      if (moduleDesc != null) 'moduleDesc': moduleDesc,
      'permissions': permissions?.toJson(),
    };
  }

  @override
  List<Object?> get props => [featureName, moduleName, featureId, desc, moduleDesc, permissions];
}

/// Permission Actions Model
class PermissionActions extends Equatable {
  final bool? create;
  final bool? read;
  final bool? update;
  final bool? delete;
  final bool? view;
  final bool? edit;
  final bool? fullAccess;

  const PermissionActions({
    this.create,
    this.read,
    this.update,
    this.delete,
    this.view,
    this.edit,
    this.fullAccess,
  });

  factory PermissionActions.fromJson(Map<String, dynamic> json) {
    return PermissionActions(
      create: json['create'] as bool?,
      read: json['read'] as bool?,
      update: json['update'] as bool?,
      delete: json['delete'] as bool?,
      view: json['view'] as bool?,
      edit: json['edit'] as bool?,
      fullAccess: json['fullAccess'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'create': create,
      'read': read,
      'update': update,
      'delete': delete,
      'view': view,
      'edit': edit,
      'fullAccess': fullAccess,
    };
  }

  @override
  List<Object?> get props => [
    create,
    read,
    update,
    delete,
    view,
    edit,
    fullAccess,
  ];
}

/// Task Model
class Task extends Equatable {
  final String? taskId;
  final String? taskName;
  final String? taskDetails;

  const Task({this.taskId, this.taskName, this.taskDetails});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId']?.toString(),
      taskName: json['taskName']?.toString(),
      taskDetails: json['taskDetails']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'taskId': taskId, 'taskName': taskName, 'taskDetails': taskDetails};
  }

  @override
  List<Object?> get props => [taskId, taskName, taskDetails];
}

/// User Model
class User extends Equatable {
  final String? userId;
  final String? name;
  final String? email;
  final String? role;
  final int? phone;
  final String? roleId;

  const User({
    this.userId,
    this.name,
    this.email,
    this.role,
    this.phone,
    this.roleId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      phone: json['phone'] is int
          ? json['phone'] as int?
          : json['phone'] is String
          ? int.tryParse(json['phone'] as String)
          : null,
      roleId: json['roleId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'roleId': roleId,
    };
  }

  @override
  List<Object?> get props => [userId, name, email, role, phone, roleId];
}
