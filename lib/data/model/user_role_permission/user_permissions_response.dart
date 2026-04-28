import 'package:equatable/equatable.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';

/// User Permissions Response Model
class UserPermissionsResponse extends Equatable {
  final String? id;
  final String email;
  final String name;
  final List<String> roleIds;
  final String profile;
  final List<String>? projectIds; // Optional - derived from projects array
  final List<UserProject> projects;
  final List<UserRolePermission> permissions;
  final String? projectId; // Extracted from roles object (Active Project ID)

  const UserPermissionsResponse({
    this.id,
    required this.email,
    required this.name,
    required this.roleIds,
    required this.profile,
    this.projectIds,
    required this.projects,
    required this.permissions,
    this.projectId,
  });

  /// Get projectIds from projects list (for backward compatibility)
  List<String> get projectIdsList =>
      projectIds ?? projects.map((p) => p.projectId).toList();

  factory UserPermissionsResponse.fromJson(Map<String, dynamic> json) {
    // Extract projects array with both projectId and projectName
    final List<UserProject> extractedProjects = [];
    final List<String> extractedProjectIds = [];

    if (json['projects'] is List) {
      for (var projectData in json['projects'] as List) {
        if (projectData is Map<String, dynamic>) {
          // Handle both projectId and projectid (case variations)
          final projectId =
              projectData['projectId']?.toString() ??
              projectData['projectid']?.toString() ??
              '';
          // Handle both projectName and projectname (case variations)
          final projectName =
              projectData['projectName']?.toString() ??
              projectData['projectname']?.toString() ??
              '';

          if (projectId.isNotEmpty) {
            extractedProjectIds.add(projectId);
            extractedProjects.add(
              UserProject(projectId: projectId, projectName: projectName),
            );
          }
        }
      }
    }

    // Extract roleIds and permissions from roles object
    final List<String> extractedRoleIds = [];
    final List<UserRolePermission> extractedPermissions = [];
    String? extractedProjectId;

    // Handle the new API response structure: roles is now an object (not array)
    if (json['roles'] is Map<String, dynamic>) {
      final rolesData = json['roles'] as Map<String, dynamic>;
      // Handle case variations: clientId, clientid, clientID
      final clientId =
          rolesData['clientId']?.toString() ??
          rolesData['clientid']?.toString() ??
          rolesData['clientID']?.toString() ??
          '';

      extractedProjectId = rolesData['projectId']?.toString();

      // Extract rolesinfo array (handle case variations)
      final rolesInfoList = rolesData['rolesinfo'] is List
          ? rolesData['rolesinfo'] as List
          : (rolesData['rolesInfo'] is List
                ? rolesData['rolesInfo'] as List
                : (rolesData['rolesINFO'] is List
                      ? rolesData['rolesINFO'] as List
                      : <dynamic>[]));

      if (rolesInfoList.isNotEmpty) {
        // Extract permissions array from roles object
        final List<UserModulePermission> modulePermissions = [];
        if (rolesData['permissions'] is List) {
          for (var moduleData in rolesData['permissions'] as List) {
            if (moduleData is Map<String, dynamic>) {
              // Handle case variations: moduleName, modulename, moduleID, moduleId
              final moduleName =
                  moduleData['moduleName']?.toString() ??
                  moduleData['modulename']?.toString() ??
                  '';
              final moduleId =
                  moduleData['moduleId']?.toString() ??
                  moduleData['moduleID']?.toString() ??
                  '';
              final List<UserFeaturePermission> features = [];

              // Handle case variations: featurePermissions, featurepermissions, featurePermissions
              final featurePermissionsList =
                  moduleData['featurePermissions'] is List
                  ? moduleData['featurePermissions'] as List
                  : (moduleData['featurepermissions'] is List
                        ? moduleData['featurepermissions'] as List
                        : <dynamic>[]);

              if (featurePermissionsList.isNotEmpty) {
                for (var featureData in featurePermissionsList) {
                  if (featureData is Map<String, dynamic>) {
                    // Handle case variations: featureName, featurename
                    final featureName =
                        featureData['featureName']?.toString() ??
                        featureData['featurename']?.toString() ??
                        '';
                    final featureId =
                        featureData['featureId']?.toString() ??
                        featureData['featureID']?.toString() ??
                        '';
                    final rules = featureData['rules'];

                    if (featureName.isNotEmpty &&
                        rules is Map<String, dynamic>) {
                      features.add(
                        UserFeaturePermission(
                          name: featureName,
                          featureId: featureId,
                          desc: '', // API doesn't provide desc
                          permissions: PermissionActions.fromJson(rules),
                        ),
                      );
                    }
                  }
                }
              }

              if (moduleName.isNotEmpty) {
                modulePermissions.add(
                  UserModulePermission(
                    module: moduleName,
                    moduleId: moduleId,
                    features: features,
                  ),
                );
              }
            }
          }
        }

        // Create a UserRolePermission for each role in rolesinfo
        for (var roleInfo in rolesInfoList) {
          if (roleInfo is Map<String, dynamic>) {
            // Handle case variations: roleid, roleId, roleID
            final roleId =
                roleInfo['roleid']?.toString() ??
                roleInfo['roleId']?.toString() ??
                roleInfo['roleID']?.toString() ??
                '';
            // Handle case variations: rolename, roleName, roleName
            final roleName =
                roleInfo['rolename']?.toString() ??
                roleInfo['roleName']?.toString() ??
                roleInfo['roleNAME']?.toString() ??
                '';

            if (roleId.isNotEmpty) {
              extractedRoleIds.add(roleId);
            }

            if (roleId.isNotEmpty && roleName.isNotEmpty) {
              extractedPermissions.add(
                UserRolePermission(
                  roleId: roleId,
                  roleName: roleName,
                  clientId: clientId,
                  permissions: modulePermissions,
                ),
              );
            }
          }
        }
      }
    }

    // Fallback to old structure if roles is an array (backward compatibility)
    if (extractedPermissions.isEmpty && json['roles'] is List) {
      final rolesList = json['roles'] as List;
      for (var roleData in rolesList) {
        if (roleData is Map<String, dynamic>) {
          final rolesInfoList = roleData['rolesinfo'] is List
              ? roleData['rolesinfo'] as List
              : (roleData['rolesInfo'] is List
                    ? roleData['rolesInfo'] as List
                    : (roleData['rolesINFO'] is List
                          ? roleData['rolesINFO'] as List
                          : <dynamic>[]));

          if (rolesInfoList.isNotEmpty) {
            final roleInfo = rolesInfoList.first;
            if (roleInfo is Map<String, dynamic>) {
              final roleId =
                  roleInfo['roleid']?.toString() ??
                  roleInfo['roleId']?.toString() ??
                  roleInfo['roleID']?.toString() ??
                  '';
              final roleName =
                  roleInfo['rolename']?.toString() ??
                  roleInfo['roleName']?.toString() ??
                  roleInfo['roleNAME']?.toString() ??
                  '';

              if (roleId.isNotEmpty) {
                extractedRoleIds.add(roleId);
              }

              final List<UserModulePermission> modulePermissions = [];
              if (roleData['permissions'] is List) {
                for (var moduleData in roleData['permissions'] as List) {
                  if (moduleData is Map<String, dynamic>) {
                    final moduleName =
                        moduleData['moduleName']?.toString() ??
                        moduleData['modulename']?.toString() ??
                        '';
                    final moduleId =
                        moduleData['moduleId']?.toString() ??
                        moduleData['moduleID']?.toString() ??
                        '';
                    final List<UserFeaturePermission> features = [];

                    final featurePermissionsList =
                        moduleData['featurePermissions'] is List
                        ? moduleData['featurePermissions'] as List
                        : (moduleData['featurepermissions'] is List
                              ? moduleData['featurepermissions'] as List
                              : <dynamic>[]);

                    if (featurePermissionsList.isNotEmpty) {
                      for (var featureData in featurePermissionsList) {
                        if (featureData is Map<String, dynamic>) {
                          final featureName =
                              featureData['featureName']?.toString() ??
                              featureData['featurename']?.toString() ??
                              '';
                          final featureId =
                              featureData['featureId']?.toString() ??
                              featureData['featureID']?.toString() ??
                              '';
                          final rules = featureData['rules'];

                          if (featureName.isNotEmpty &&
                              rules is Map<String, dynamic>) {
                            features.add(
                              UserFeaturePermission(
                                name: featureName,
                                featureId: featureId,
                                desc: '',
                                permissions: PermissionActions.fromJson(rules),
                              ),
                            );
                          }
                        }
                      }
                    }

                    if (moduleName.isNotEmpty) {
                      modulePermissions.add(
                        UserModulePermission(
                          module: moduleName,
                          moduleId: moduleId,
                          features: features,
                        ),
                      );
                    }
                  }
                }
              }

              final clientId = roleData['clientId']?.toString() ?? '';

              if (roleId.isNotEmpty && roleName.isNotEmpty) {
                extractedPermissions.add(
                  UserRolePermission(
                    roleId: roleId,
                    roleName: roleName,
                    clientId: clientId,
                    permissions: modulePermissions,
                  ),
                );
              }
            }
          }
        }
      }
    }

    // Fallback to old structure if permissions is directly in json
    if (extractedPermissions.isEmpty && json['permissions'] is List) {
      final permissionsList = json['permissions'] as List;
      extractedPermissions.addAll(
        permissionsList
            .whereType<Map<String, dynamic>>()
            .map((e) => UserRolePermission.fromJson(e))
            .toList(),
      );
    }

    return UserPermissionsResponse(
      id:
          json['id']?.toString() ??
          json['_id']?.toString() ??
          json['userId']?.toString(),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      roleIds: json['roleIds'] is List
          ? (json['roleIds'] as List).map((e) => e.toString()).toList()
          : extractedRoleIds,
      profile: json['profile']?.toString() ?? '',
      // projectIds is optional - use extracted from projects or from json if available
      projectIds: json['projectIds'] is List
          ? (json['projectIds'] as List).map((e) => e.toString()).toList()
          : (extractedProjectIds.isNotEmpty ? extractedProjectIds : null),
      projects: extractedProjects,
      permissions: extractedPermissions,
      projectId: extractedProjectId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'roleIds': roleIds,
      'profile': profile,
      if (projectIds != null) 'projectIds': projectIds,
      'projects': projects.map((e) => e.toJson()).toList(),
      'permissions': permissions.map((e) => e.toJson()).toList(),
      if (projectId != null) 'projectId': projectId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    roleIds,
    profile,
    projectIds,
    projects,
    permissions,
    projectId,
  ];
}

/// User Project Model
class UserProject extends Equatable {
  final String projectId;
  final String projectName;

  const UserProject({required this.projectId, required this.projectName});

  factory UserProject.fromJson(Map<String, dynamic> json) {
    return UserProject(
      projectId:
          json['projectId']?.toString() ?? json['projectid']?.toString() ?? '',
      projectName:
          json['projectName']?.toString() ??
          json['projectname']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'projectId': projectId, 'projectName': projectName};
  }

  @override
  List<Object?> get props => [projectId, projectName];
}

/// User Role Permission Model
class UserRolePermission extends Equatable {
  final String roleId;
  final String roleName;
  final String clientId;
  final List<UserModulePermission> permissions;

  const UserRolePermission({
    required this.roleId,
    required this.roleName,
    required this.clientId,
    required this.permissions,
  });

  factory UserRolePermission.fromJson(Map<String, dynamic> json) {
    return UserRolePermission(
      roleId:
          json['roleId']?.toString() ??
          json['roleid']?.toString() ??
          json['roleID']?.toString() ??
          '',
      roleName:
          json['roleName']?.toString() ??
          json['rolename']?.toString() ??
          json['roleNAME']?.toString() ??
          '',
      clientId:
          json['clientId']?.toString() ??
          json['clientid']?.toString() ??
          json['clientID']?.toString() ??
          '',
      permissions: json['permissions'] is List
          ? (json['permissions'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => UserModulePermission.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'roleName': roleName,
      'clientId': clientId,
      'permissions': permissions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [roleId, roleName, clientId, permissions];
}

/// User Module Permission Model
class UserModulePermission extends Equatable {
  final String module;
  final String moduleId;
  final List<UserFeaturePermission> features;

  const UserModulePermission({
    required this.module,
    required this.moduleId,
    required this.features,
  });

  factory UserModulePermission.fromJson(Map<String, dynamic> json) {
    return UserModulePermission(
      module:
          json['module']?.toString() ?? json['moduleName']?.toString() ?? '',
      moduleId:
          json['moduleId']?.toString() ?? json['moduleID']?.toString() ?? '',
      features: json['features'] is List
          ? (json['features'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => UserFeaturePermission.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module': module,
      'moduleId': moduleId,
      'features': features.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [module, moduleId, features];
}

/// User Feature Permission Model
class UserFeaturePermission extends Equatable {
  final String name;
  final String featureId;
  final String desc;
  final PermissionActions permissions;

  const UserFeaturePermission({
    required this.name,
    required this.featureId,
    required this.desc,
    required this.permissions,
  });

  factory UserFeaturePermission.fromJson(Map<String, dynamic> json) {
    return UserFeaturePermission(
      name: json['name']?.toString() ?? json['featureName']?.toString() ?? '',
      featureId:
          json['featureId']?.toString() ?? json['featureID']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      permissions: json['permissions'] != null
          ? PermissionActions.fromJson(
              json['permissions'] as Map<String, dynamic>,
            )
          : const PermissionActions(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'featureId': featureId,
      'desc': desc,
      'permissions': permissions.toJson(),
    };
  }

  @override
  List<Object?> get props => [name, featureId, desc, permissions];
}
