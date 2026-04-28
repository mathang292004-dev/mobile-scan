import 'package:equatable/equatable.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';

/// AI Analysis Model (from API response)
class AIAnalysis extends Equatable {
  final String? desc;
  final String? integrationAnalysis;
  final String? responsibilityOverlap;

  const AIAnalysis({
    this.desc,
    this.integrationAnalysis,
    this.responsibilityOverlap,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      desc: json['desc']?.toString(),
      integrationAnalysis: json['integrationAnalysis']?.toString(),
      responsibilityOverlap:
          json['responsiblityOverlap']?.toString() ??
          json['responsibilityOverlap']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'desc': desc,
      'integrationAnalysis': integrationAnalysis,
      'responsiblityOverlap': responsibilityOverlap,
    };
  }

  @override
  List<Object?> get props => [desc, integrationAnalysis, responsibilityOverlap];
}

/// AI Insights Model
class AiInsights extends Equatable {
  final int? roleMatch;
  final int? hierarchyMatch;
  final int? responsibilityOverlap;
  final int? documentContext;

  const AiInsights({
    this.roleMatch,
    this.hierarchyMatch,
    this.responsibilityOverlap,
    this.documentContext,
  });

  factory AiInsights.fromJson(Map<String, dynamic> json) {
    return AiInsights(
      roleMatch: json['roleMatch'] is int
          ? json['roleMatch'] as int
          : json['roleMatch'] is num
          ? (json['roleMatch'] as num).toInt()
          : null,
      hierarchyMatch: json['hierarchyMatch'] is int
          ? json['hierarchyMatch'] as int
          : json['hierarchyMatch'] is num
          ? (json['hierarchyMatch'] as num).toInt()
          : null,
      responsibilityOverlap: json['responsibilityOverlap'] is int
          ? json['responsibilityOverlap'] as int
          : json['responsibilityOverlap'] is num
          ? (json['responsibilityOverlap'] as num).toInt()
          : null,
      documentContext: json['documentContext'] is int
          ? json['documentContext'] as int
          : json['documentContext'] is num
          ? (json['documentContext'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleMatch': roleMatch,
      'hierarchyMatch': hierarchyMatch,
      'responsibilityOverlap': responsibilityOverlap,
      'documentContext': documentContext,
    };
  }

  @override
  List<Object?> get props => [
    roleMatch,
    hierarchyMatch,
    responsibilityOverlap,
    documentContext,
  ];
}

/// Role Details Response Model
class RoleDetailsResponse extends Equatable {
  final RoleDetails roleDetails;
  final List<AssignedUser> assignedUsers;
  final AiInsights? aiInsights;

  const RoleDetailsResponse({
    required this.roleDetails,
    required this.assignedUsers,
    this.aiInsights,
  });

  factory RoleDetailsResponse.fromJson(Map<String, dynamic> json) {
    AiInsights? extractedAiInsights;
    RoleDetails? extractedRoleDetails;
    List<AssignedUser> extractedAssignedUsers = [];

    // Handle nested data structure: { "data": { "roleDetails": {...}, "assignedUsers": [...] } }
    if (json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;

      // Extract roleDetails from data.roleDetails
      if (dataMap['roleDetails'] != null &&
          dataMap['roleDetails'] is Map<String, dynamic>) {
        extractedRoleDetails = RoleDetails.fromJson(
          dataMap['roleDetails'] as Map<String, dynamic>,
        );
      }

      // Extract assignedUsers from data.assignedUsers
      if (dataMap['assignedUsers'] is List) {
        extractedAssignedUsers = (dataMap['assignedUsers'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => AssignedUser.fromJson(e))
            .toList();
      }

      // Extract aiInsights from data level if present
      if (dataMap['aiInsights'] != null &&
          dataMap['aiInsights'] is Map<String, dynamic>) {
        extractedAiInsights = AiInsights.fromJson(
          dataMap['aiInsights'] as Map<String, dynamic>,
        );
      }

      // Check if data.data exists (nested array structure)
      if (dataMap['data'] is List) {
        final dataList = dataMap['data'] as List;
        if (dataList.isNotEmpty && dataList.first is Map<String, dynamic>) {
          final firstRole = dataList.first as Map<String, dynamic>;
          return RoleDetailsResponse(
            roleDetails:
                extractedRoleDetails ?? RoleDetails.fromJson(firstRole),
            assignedUsers: extractedAssignedUsers,
            aiInsights: extractedAiInsights,
          );
        }
      }

      // If we have roleDetails from data.roleDetails, return it
      if (extractedRoleDetails != null) {
        return RoleDetailsResponse(
          roleDetails: extractedRoleDetails,
          assignedUsers: extractedAssignedUsers,
          aiInsights: extractedAiInsights,
        );
      }

      // If data is a single role object with roleId at same level
      if (dataMap.containsKey('roleId') || dataMap.containsKey('role_id')) {
        return RoleDetailsResponse(
          roleDetails: RoleDetails.fromJson(dataMap),
          assignedUsers: extractedAssignedUsers.isNotEmpty
              ? extractedAssignedUsers
              : (dataMap['assignedUsers'] is List
                    ? (dataMap['assignedUsers'] as List)
                          .whereType<Map<String, dynamic>>()
                          .map((e) => AssignedUser.fromJson(e))
                          .toList()
                    : []),
          aiInsights: extractedAiInsights,
        );
      }
    }

    // Handle standard structure with roleDetails key at root level
    return RoleDetailsResponse(
      roleDetails: json['roleDetails'] != null
          ? RoleDetails.fromJson(json['roleDetails'] as Map<String, dynamic>)
          : throw Exception('roleDetails is required'),
      assignedUsers: json['assignedUsers'] is List
          ? (json['assignedUsers'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => AssignedUser.fromJson(e))
                .toList()
          : [],
      aiInsights:
          json['aiInsights'] != null &&
              json['aiInsights'] is Map<String, dynamic>
          ? AiInsights.fromJson(json['aiInsights'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleDetails': roleDetails.toJson(),
      'assignedUsers': assignedUsers.map((e) => e.toJson()).toList(),
      'aiInsights': aiInsights?.toJson(),
    };
  }

  @override
  List<Object?> get props => [roleDetails, assignedUsers, aiInsights];
}

/// Module Permission Model - stores module with its features
class ModulePermission extends Equatable {
  final String moduleName;
  final List<FeaturePermission> features;

  const ModulePermission({required this.moduleName, required this.features});

  @override
  List<Object?> get props => [moduleName, features];
}

/// Role Details Model
class RoleDetails extends Equatable {
  final String roleId;
  final String roleName;
  final String designation;
  final String description;
  final String projectId;
  final List<FeaturePermission> permissions;
  final List<ModulePermission>?
  modulePermissions; // New field for module-based structure
  final AIAnalysis? aiAnalysis; // AI Analysis from API

  const RoleDetails({
    required this.roleId,
    required this.roleName,
    required this.designation,
    required this.description,
    required this.projectId,
    required this.permissions,
    this.modulePermissions,
    this.aiAnalysis,
  });

  factory RoleDetails.fromJson(Map<String, dynamic> json) {
    List<FeaturePermission> permissions = [];
    List<ModulePermission>? modulePermissions;

    if (json['permissions'] is List) {
      final permissionsList = json['permissions'] as List;
      final List<ModulePermission> modules = [];

      for (var item in permissionsList) {
        if (item is Map<String, dynamic>) {
          // Check if it's the new module-based structure
          // Support both 'module' and 'name' keys for module name
          if ((item.containsKey('module') || item.containsKey('name')) &&
              item.containsKey('features')) {
            // New structure: { "module": "..." OR "name": "...", "features": [...] }
            final moduleName =
                item['module']?.toString() ?? item['name']?.toString() ?? '';
            final moduleDesc = item['desc']?.toString();
            final features = item['features'];
            final List<FeaturePermission> moduleFeatures = [];

            if (features is List) {
              for (var feature in features) {
                if (feature is Map<String, dynamic>) {
                  // Convert feature to FeaturePermission with moduleName, featureId, and desc
                  final featurePermission = FeaturePermission(
                    featureName: feature['name']?.toString(),
                    moduleName: moduleName,
                    featureId: feature['featureId']?.toString(),
                    desc: feature['desc']?.toString(),
                    moduleDesc: moduleDesc,
                    permissions: feature['permissions'] != null
                        ? PermissionActions.fromJson(
                            feature['permissions'] as Map<String, dynamic>,
                          )
                        : null,
                  );
                  permissions.add(featurePermission);
                  moduleFeatures.add(featurePermission);
                }
              }
            }

            if (moduleName.isNotEmpty) {
              modules.add(
                ModulePermission(
                  moduleName: moduleName,
                  features: moduleFeatures,
                ),
              );
            }
          } else if (item.containsKey('featureName')) {
            // Old structure: flat list of FeaturePermission objects with 'featureName' key
            permissions.add(FeaturePermission.fromJson(item));
          }
        }
      }

      if (modules.isNotEmpty) {
        modulePermissions = modules;
      }
    }

    // Extract AIAnalysis if present
    AIAnalysis? aiAnalysis;
    if (json['AIAnalysis'] != null &&
        json['AIAnalysis'] is Map<String, dynamic>) {
      aiAnalysis = AIAnalysis.fromJson(
        json['AIAnalysis'] as Map<String, dynamic>,
      );
    }

    return RoleDetails(
      roleId: json['role_id']?.toString() ?? json['roleId']?.toString() ?? '',
      roleName:
          json['role_name']?.toString() ?? json['roleName']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      permissions: permissions,
      modulePermissions: modulePermissions,
      aiAnalysis: aiAnalysis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': roleId,
      'role_name': roleName,
      'designation': designation,
      'description': description,
      'projectId': projectId,
      'permissions': permissions.map((e) => e.toJson()).toList(),
      if (aiAnalysis != null) 'AIAnalysis': aiAnalysis!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    roleId,
    roleName,
    designation,
    description,
    projectId,
    permissions,
    modulePermissions,
    aiAnalysis,
  ];
}

/// Assigned User Model
class AssignedUser extends Equatable {
  final String userId;
  final String name;
  final String email;

  const AssignedUser({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'name': name, 'email': email};
  }

  @override
  List<Object?> get props => [userId, name, email];
}
