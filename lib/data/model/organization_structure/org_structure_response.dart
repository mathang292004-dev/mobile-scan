import 'package:equatable/equatable.dart';

/// Organization Structure API Response Model
class OrgStructureResponse extends Equatable {
  final String? id;
  final String organizationId;
  final String projectId;
  final AiAnalysis? aiAnalysis;
  final OrganizationStructure organizationStructure;
  final List<RoleMember> roleMembers;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrgStructureResponse({
    this.id,
    required this.organizationId,
    required this.projectId,
    this.aiAnalysis,
    required this.organizationStructure,
    required this.roleMembers,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory OrgStructureResponse.fromJson(Map<String, dynamic> json) {
    return OrgStructureResponse(
      id: json['_id']?.toString(),
      organizationId: json['organizationId']?.toString() ?? '',
      projectId: json['projectId']?.toString() ?? '',
      aiAnalysis: json['aiAnalysis'] != null
          ? AiAnalysis.fromJson(json['aiAnalysis'] as Map<String, dynamic>)
          : null,
      organizationStructure: OrganizationStructure.fromJson(
        json['organizationStructure'] as Map<String, dynamic>,
      ),
      roleMembers: (json['roleMembers'] as List?)
              ?.map((e) => RoleMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'organizationId': organizationId,
      'projectId': projectId,
      'aiAnalysis': aiAnalysis?.toJson(),
      'organizationStructure': organizationStructure.toJson(),
      'roleMembers': roleMembers.map((e) => e.toJson()).toList(),
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        projectId,
        aiAnalysis,
        organizationStructure,
        roleMembers,
        isDeleted,
        createdAt,
        updatedAt,
      ];
}

/// AI Analysis Model
class AiAnalysis extends Equatable {
  final int roleMatch;
  final int hierarchyMatch;
  final int responsibilityOverlap;
  final int documentContext;

  const AiAnalysis({
    required this.roleMatch,
    required this.hierarchyMatch,
    required this.responsibilityOverlap,
    required this.documentContext,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      roleMatch: json['roleMatch'] ?? 0,
      hierarchyMatch: json['hierarchyMatch'] ?? 0,
      responsibilityOverlap: json['responsibilityOverlap'] ?? 0,
      documentContext: json['documentContext'] ?? 0,
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

/// Organization Structure Model (nested structure)
class OrganizationStructure extends Equatable {
  final String roleName;
  final int level;
  final List<OrganizationStructure> children;

  const OrganizationStructure({
    required this.roleName,
    required this.level,
    required this.children,
  });

  factory OrganizationStructure.fromJson(Map<String, dynamic> json) {
    return OrganizationStructure(
      roleName: json['roleName']?.toString() ?? '',
      level: json['level'] ?? 0,
      children: (json['children'] as List?)
              ?.map((e) =>
                  OrganizationStructure.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleName': roleName,
      'level': level,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [roleName, level, children];
}

/// Role Member Model
class RoleMember extends Equatable {
  final String? id;
  final String roleName;
  final List<Member> members;

  const RoleMember({
    this.id,
    required this.roleName,
    required this.members,
  });

  factory RoleMember.fromJson(Map<String, dynamic> json) {
    return RoleMember(
      id: json['_id']?.toString(),
      roleName: json['roleName']?.toString() ?? '',
      members: (json['members'] as List?)
              ?.map((e) => Member.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roleName': roleName,
      'members': members.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, roleName, members];
}

/// Member Model
class Member extends Equatable {
  final String? id;
  final String memberName;
  final String memberEmail;

  const Member({
    this.id,
    required this.memberName,
    required this.memberEmail,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['_id']?.toString(),
      memberName: json['memberName']?.toString() ?? '',
      memberEmail: json['memberEmail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'memberName': memberName,
      'memberEmail': memberEmail,
    };
  }

  @override
  List<Object?> get props => [id, memberName, memberEmail];
}

