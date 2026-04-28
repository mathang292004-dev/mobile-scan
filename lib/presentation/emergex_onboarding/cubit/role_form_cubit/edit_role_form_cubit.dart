import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/permission_constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Target for permission mapping rule (for edit flow)
class EditPermissionTarget {
  final String? targetModule;
  final String targetFeature;
  final String targetField;
  final bool targetValue;

  const EditPermissionTarget({
    this.targetModule,
    required this.targetFeature,
    required this.targetField,
    required this.targetValue,
  });
}

/// Permission mapping rule definition (for edit flow)
class EditPermissionMappingRule {
  final String? sourceModule;
  final String sourceFeature;
  final String sourceField;
  final bool sourceValue;
  final List<EditPermissionTarget> targets;

  const EditPermissionMappingRule({
    this.sourceModule,
    required this.sourceFeature,
    required this.sourceField,
    required this.sourceValue,
    required this.targets,
  });
}

class EditRoleFormState extends Equatable {
  final String roleName;
  final String designation;
  final String description;
  final bool isFormPopulated;
  final String originalRoleName;
  final String originalDesignation;
  final String originalDescription;
  final List<AssignedUser> originalAssignedUsers;
  final List<AssignedUser> snapshotAssignedUsers;
  final List<FeaturePermission> currentPermissions;
  final List<FeaturePermission> originalPermissions;

  const EditRoleFormState({
    this.roleName = '',
    this.designation = '',
    this.description = '',
    this.isFormPopulated = false,
    this.originalRoleName = '',
    this.originalDesignation = '',
    this.originalDescription = '',
    this.originalAssignedUsers = const [],
    this.snapshotAssignedUsers = const [],
    this.currentPermissions = const [],
    this.originalPermissions = const [],
  });

  EditRoleFormState copyWith({
    String? roleName,
    String? designation,
    String? description,
    bool? isFormPopulated,
    String? originalRoleName,
    String? originalDesignation,
    String? originalDescription,
    List<AssignedUser>? originalAssignedUsers,
    List<AssignedUser>? snapshotAssignedUsers,
    List<FeaturePermission>? currentPermissions,
    List<FeaturePermission>? originalPermissions,
  }) {
    return EditRoleFormState(
      roleName: roleName ?? this.roleName,
      designation: designation ?? this.designation,
      description: description ?? this.description,
      isFormPopulated: isFormPopulated ?? this.isFormPopulated,
      originalRoleName: originalRoleName ?? this.originalRoleName,
      originalDesignation: originalDesignation ?? this.originalDesignation,
      originalDescription: originalDescription ?? this.originalDescription,
      originalAssignedUsers:
          originalAssignedUsers ?? this.originalAssignedUsers,
      snapshotAssignedUsers:
          snapshotAssignedUsers ?? this.snapshotAssignedUsers,
      currentPermissions: currentPermissions ?? this.currentPermissions,
      originalPermissions: originalPermissions ?? this.originalPermissions,
    );
  }

  @override
  List<Object?> get props => [
    roleName,
    designation,
    description,
    isFormPopulated,
    originalRoleName,
    originalDesignation,
    originalDescription,
    originalAssignedUsers,
    snapshotAssignedUsers,
    currentPermissions,
    originalPermissions,
  ];
}

class EditRoleFormCubit extends Cubit<EditRoleFormState> {
  EditRoleFormCubit() : super(const EditRoleFormState());

  /// Permission mapping rules for edit flow
  static const List<EditPermissionMappingRule> permissionMapping = [
    // ========================================
    // EmergeX Client Onboarding Module Rules
    // ========================================
    EditPermissionMappingRule(
      sourceModule: "EmergeX Client Onboarding",
      sourceFeature: "Upload or Reupload files",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "EmergeX Client Onboarding",
          targetFeature: "EmergeX Client",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "EmergeX Client Onboarding",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // ========================================
    // Client Admin Module Rules
    // ========================================
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Upload or Reupload files",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Role Management (view) → Enable Projects (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "view",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // 2. When Role Management has Create/Delete/Edit enabled → Projects → View
    // Role Management (create) → Enable Projects (view) + Member Management (view, create, delete)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "create",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Member Management",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Member Management",
          targetField: "create",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Member Management",
          targetField: "delete",
          targetValue: true,
        ),
      ],
    ),

    // Role Management (delete) → Enable Projects (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "delete",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Role Management (edit) → Enable Projects (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "edit",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Role Management (fullAccess) → Enable Projects (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // 3. When Member Management has Create/Delete/Edit enabled:
    //    → Projects → View
    //    → Role Management → View
    // Member Management (create) → Enable Projects, Role Management (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "create",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Member Management (delete) → Enable Projects, Role Management (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "delete",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Member Management (edit) → Enable Projects, Role Management (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "edit",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Member Management (view) → Enable Projects, Role Management (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "view",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Member Management (fullAccess) → Enable Projects, Role Management (view)
    EditPermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // ========================================
    // Incident Reporting & Monitoring Rules
    // ========================================

    // Upload file (fullAccess) → Enable EmergeX Case (view)
    EditPermissionMappingRule(
      sourceModule: "Incident Reporting & Monitoring",
      sourceFeature: "Upload file (img, pdf, etc)",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "EmergeX Case",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Switch Categories (fullAccess) → Enable EmergeX Case (view)
    EditPermissionMappingRule(
      sourceModule: "Incident Reporting & Monitoring",
      sourceFeature:
          "Switch Categories (Intervention, Observation, Incident, Near Miss)",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "EmergeX Case",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // 3. When Approval of Incident is enabled:
    //    → EmergeX Case → View
    //    → Upload File
    //    → Switch Categories
    EditPermissionMappingRule(
      sourceModule: "Incident Reporting & Monitoring",
      sourceFeature: "Approval of Incident",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        EditPermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "EmergeX Case",
          targetField: "view",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "Upload file (img, pdf, etc)",
          targetField: "fullAccess",
          targetValue: true,
        ),
        EditPermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature:
              "Switch Categories (Intervention, Observation, Incident, Near Miss)",
          targetField: "fullAccess",
          targetValue: true,
        ),
      ],
    ),
  ];

  void updateRoleName(String roleName) {
    emit(state.copyWith(roleName: roleName));
  }

  void updateDesignation(String designation) {
    emit(state.copyWith(designation: designation));
  }

  void updateDescription(String description) {
    emit(state.copyWith(description: description));
  }

  void populateForm({
    required String roleName,
    required String designation,
    required String description,
    List<FeaturePermission>? permissions,
  }) {
    final isDifferentRole =
        !state.isFormPopulated ||
        state.originalRoleName != roleName ||
        state.originalDesignation != designation ||
        state.originalDescription != description;

    if (isDifferentRole) {
      final perms = permissions ?? [];
      emit(
        state.copyWith(
          roleName: roleName,
          designation: designation,
          description: description,
          isFormPopulated: true,
          originalRoleName: roleName,
          originalDesignation: designation,
          originalDescription: description,
          currentPermissions: perms,
          originalPermissions: perms,
          originalAssignedUsers: [],
          snapshotAssignedUsers: [],
        ),
      );
    }
  }

  void reset() {
    emit(const EditRoleFormState());
  }

  void setOriginalAssignedUsers(List<AssignedUser> users) {
    if (state.originalAssignedUsers.isEmpty) {
      emit(state.copyWith(originalAssignedUsers: users));
    }
  }

  void setSnapshotAssignedUsers(List<AssignedUser> users) {
    emit(
      state.copyWith(
        snapshotAssignedUsers: AppDI.roleDetailsCubit.state.assignedUsers ?? [],
      ),
    );
  }

  void forceUpdateOriginalAssignedUsers(List<AssignedUser> users) {
    emit(state.copyWith(originalAssignedUsers: users));
  }

  void updatePermission(
    String featureName,
    String? moduleName,
    int index,
    bool value,
  ) {
    // Check if this feature is full access only
    final isFullAccessOnly = isFullAccessOnlyFeature(featureName);

    // For full access only features, only allow toggling the fullAccess permission (index 4)
    if (isFullAccessOnly && index != 4) {
      return;
    }

    // Determine the module name
    String? sourceModuleName = moduleName;
    if (sourceModuleName == null) {
      final sourcePermission = state.currentPermissions.firstWhere(
        (perm) => perm.featureName == featureName,
        orElse: () => const FeaturePermission(),
      );
      sourceModuleName = sourcePermission.moduleName;
    }

    // Special Rule for Incident Reporting: If EmergeX Case View is disabled, disable all other permissions
    if (sourceModuleName == "Incident Reporting & Monitoring" &&
        featureName == "EmergeX Case" &&
        index == 1 &&
        !value) {
      final updatedPermissions = state.currentPermissions.map((perm) {
        if (perm.featureName == featureName &&
            perm.moduleName == sourceModuleName &&
            perm.permissions != null) {
          return FeaturePermission(
            featureName: perm.featureName,
            moduleName: perm.moduleName,
            featureId: perm.featureId,  // Preserve featureId
            desc: perm.desc,  // Preserve desc
            moduleDesc: perm.moduleDesc,  // Preserve moduleDesc
            permissions: const PermissionActions(
              create: false,
              view: false,
              read: false,
              edit: false,
              update: false,
              delete: false,
              fullAccess: false,
            ),
          );
        }
        return perm;
      }).toList();
      emit(state.copyWith(currentPermissions: updatedPermissions));
      return;
    }

    // Update the permission
    final updatedPermissions = state.currentPermissions.map((perm) {
      final matchesFeature = perm.featureName == featureName;
      // Module matching: if sourceModuleName is null, match any module; otherwise must match exactly
      final matchesModule =
          sourceModuleName == null || sourceModuleName == perm.moduleName;

      if (matchesFeature && matchesModule && perm.permissions != null) {
        final perms = perm.permissions!;

        bool create = perms.create ?? false;
        bool view = perms.view ?? perms.read ?? false;
        bool edit = perms.edit ?? perms.update ?? false;
        bool delete = perms.delete ?? false;
        bool fullAccess = perms.fullAccess ?? false;

        if (index == 4) {
          // fullAccess: set all permissions to the same value
          create = value;
          view = value;
          edit = value;
          delete = value;
          fullAccess = value;
        } else if (index == 1) {
          // view: special logic
          if (!value) {
            // Turning off view: turn off all permissions
            create = false;
            view = false;
            edit = false;
            delete = false;
            fullAccess = false;
          } else {
            // Turning on view: turn on view and check if all are selected
            view = true;
            fullAccess = create && view && edit && delete;
          }
        } else {
          // create (0), edit (2), or delete (3)
          if (index == 0) create = value;
          if (index == 2) edit = value;
          if (index == 3) delete = value;

          // If turning on any permission, also turn on view
          if (value) {
            view = true;
          }

          // Check if all permissions are selected to set fullAccess
          fullAccess = create && view && edit && delete;
        }

        final updatedPerms = PermissionActions(
          create: create,
          view: view,
          read: view,
          edit: edit,
          update: edit,
          delete: delete,
          fullAccess: fullAccess,
        );

        return FeaturePermission(
          featureName: perm.featureName,
          moduleName: perm.moduleName,
          featureId: perm.featureId,  // Preserve featureId
          desc: perm.desc,  // Preserve desc
          moduleDesc: perm.moduleDesc,  // Preserve moduleDesc
          permissions: updatedPerms,
        );
      }
      return perm;
    }).toList();

    // Apply cascading permission rules
    final fieldName = _indexToFieldName(index);
    final finalPermissions = _applyPermissionMappingRules(
      updatedPermissions,
      sourceModuleName,
      featureName,
      fieldName,
      value,
    );

    emit(state.copyWith(currentPermissions: finalPermissions));
  }

  /// Apply permission mapping rules (only direct targets, no cascading)
  List<FeaturePermission> _applyPermissionMappingRules(
    List<FeaturePermission> permissions,
    String? sourceModuleName,
    String sourceFeatureName,
    String sourceFieldName,
    bool sourceValue,
  ) {
    var updatedPermissions = List<FeaturePermission>.from(permissions);

    if (sourceFieldName.isEmpty) return updatedPermissions;

    // Track changes for cascading (not used since cascading is disabled)
    final changedFeatures = <String, Map<String, Map<String, bool>>>{};

    // Track the original source to prevent unwanted cascading
    final originalSource = {
      'module': sourceModuleName,
      'feature': sourceFeatureName,
      'field': sourceFieldName,
    };

    // Apply forward rules: When source is enabled, enable targets
    updatedPermissions = _applyForwardRules(
      updatedPermissions,
      sourceModuleName,
      sourceFeatureName,
      sourceFieldName,
      sourceValue,
      changedFeatures,
      originalSource,
    );

    // Apply reverse rules: When target is disabled, disable sources
    updatedPermissions = _applyReverseRules(
      updatedPermissions,
      sourceModuleName,
      sourceFeatureName,
      sourceFieldName,
      sourceValue,
      changedFeatures,
    );

    // Cascading behavior disabled - only direct rule targets are applied
    // This prevents unwanted chain reactions in permission dependencies

    return updatedPermissions;
  }

  List<FeaturePermission> _applyForwardRules(
    List<FeaturePermission> permissions,
    String? sourceModuleName,
    String sourceFeatureName,
    String sourceFieldName,
    bool sourceValue,
    Map<String, Map<String, Map<String, bool>>> changesToApply,
    Map<String, dynamic> originalSource,
  ) {
    var updatedPermissions = List<FeaturePermission>.from(permissions);

    for (final rule in permissionMapping) {
      final matchesModule =
          rule.sourceModule == null || rule.sourceModule == sourceModuleName;
      final matchesFeature = rule.sourceFeature == sourceFeatureName;
      final matchesField = rule.sourceField == sourceFieldName;
      final matchesValue = rule.sourceValue == sourceValue;

      if (matchesModule && matchesFeature && matchesField && matchesValue) {
        for (final target in rule.targets) {
          final targetModuleName = target.targetModule;
          final targetFeatureName = target.targetFeature;
          final targetFieldName = target.targetField;
          final targetValue = target.targetValue;

          for (int i = 0; i < updatedPermissions.length; i++) {
            final perm = updatedPermissions[i];
            final matchesTargetFeature = perm.featureName == targetFeatureName;
            final matchesTargetModule =
                targetModuleName == null || targetModuleName == perm.moduleName;

            if (matchesTargetFeature &&
                matchesTargetModule &&
                perm.permissions != null) {
              final perms = perm.permissions!;
              final currentValue = _getPermissionFieldValue(
                perms,
                targetFieldName,
              );

              if (currentValue != targetValue) {
                final updatedPerms = _setPermissionFieldValue(
                  perms,
                  targetFieldName,
                  targetValue,
                );
                updatedPermissions[i] = FeaturePermission(
                  featureName: perm.featureName,
                  moduleName: perm.moduleName,
                  featureId: perm.featureId,  // Preserve featureId
                  desc: perm.desc,  // Preserve desc
                  moduleDesc: perm.moduleDesc,  // Preserve moduleDesc
                  permissions: updatedPerms,
                );

                // Track for cascading (not used since cascading is disabled)
                if (!changesToApply.containsKey(targetFeatureName)) {
                  changesToApply[targetFeatureName] = {};
                }
                if (!changesToApply[targetFeatureName]!.containsKey(
                  perm.moduleName ?? '',
                )) {
                  changesToApply[targetFeatureName]![perm.moduleName ?? ''] =
                      {};
                }
                changesToApply[targetFeatureName]![perm.moduleName ??
                        '']![targetFieldName] =
                    targetValue;
              }
              break;
            }
          }
        }
      }
    }

    return updatedPermissions;
  }

  List<FeaturePermission> _applyReverseRules(
    List<FeaturePermission> permissions,
    String? targetModuleName,
    String targetFeatureName,
    String targetFieldName,
    bool targetValue,
    Map<String, Map<String, Map<String, bool>>> changesToApply,
  ) {
    if (targetValue) return permissions;

    var updatedPermissions = List<FeaturePermission>.from(permissions);

    for (final rule in permissionMapping) {
      for (final target in rule.targets) {
        final matchesTargetModule =
            target.targetModule == null ||
            target.targetModule == targetModuleName;
        final matchesTargetFeature = target.targetFeature == targetFeatureName;
        final matchesTargetField = target.targetField == targetFieldName;

        if (matchesTargetModule && matchesTargetFeature && matchesTargetField) {
          final sourceModuleName = rule.sourceModule;
          final sourceFeatureName = rule.sourceFeature;
          final sourceFieldName = rule.sourceField;

          for (int i = 0; i < updatedPermissions.length; i++) {
            final perm = updatedPermissions[i];
            final matchesSourceFeature = perm.featureName == sourceFeatureName;
            final matchesSourceModule =
                sourceModuleName == null || sourceModuleName == perm.moduleName;

            if (matchesSourceFeature &&
                matchesSourceModule &&
                perm.permissions != null) {
              final perms = perm.permissions!;
              final currentValue = _getPermissionFieldValue(
                perms,
                sourceFieldName,
              );

              if (currentValue) {
                PermissionActions updatedPerms;
                if (sourceFieldName == 'fullAccess') {
                  updatedPerms = const PermissionActions(
                    create: false,
                    view: false,
                    read: false,
                    edit: false,
                    update: false,
                    delete: false,
                    fullAccess: false,
                  );
                } else {
                  updatedPerms = _setPermissionFieldValue(
                    perms,
                    sourceFieldName,
                    false,
                  );
                }
                updatedPermissions[i] = FeaturePermission(
                  featureName: perm.featureName,
                  moduleName: perm.moduleName,
                  featureId: perm.featureId,  // Preserve featureId
                  desc: perm.desc,  // Preserve desc
                  moduleDesc: perm.moduleDesc,  // Preserve moduleDesc
                  permissions: updatedPerms,
                );

                // Track for cascading (not used since cascading is disabled)
                if (!changesToApply.containsKey(sourceFeatureName)) {
                  changesToApply[sourceFeatureName] = {};
                }
                if (!changesToApply[sourceFeatureName]!.containsKey(
                  perm.moduleName ?? '',
                )) {
                  changesToApply[sourceFeatureName]![perm.moduleName ?? ''] =
                      {};
                }
                changesToApply[sourceFeatureName]![perm.moduleName ??
                        '']![sourceFieldName] =
                    false;
              }
              break;
            }
          }
        }
      }
    }

    return updatedPermissions;
  }

  String _indexToFieldName(int index) {
    switch (index) {
      case 0:
        return 'create';
      case 1:
        return 'view';
      case 2:
        return 'edit';
      case 3:
        return 'delete';
      case 4:
        return 'fullAccess';
      default:
        return '';
    }
  }

  bool _getPermissionFieldValue(PermissionActions perms, String fieldName) {
    switch (fieldName) {
      case 'create':
        return perms.create ?? false;
      case 'view':
        return perms.view ?? perms.read ?? false;
      case 'edit':
        return perms.edit ?? perms.update ?? false;
      case 'delete':
        return perms.delete ?? false;
      case 'fullAccess':
        return perms.fullAccess ?? false;
      default:
        return false;
    }
  }

  PermissionActions _setPermissionFieldValue(
    PermissionActions perms,
    String fieldName,
    bool value,
  ) {
    bool calculateFullAccess(bool create, bool view, bool edit, bool delete) {
      return create && view && edit && delete;
    }

    switch (fieldName) {
      case 'create':
        final create = value;
        final view = perms.view ?? perms.read ?? false;
        final edit = perms.edit ?? perms.update ?? false;
        final delete = perms.delete ?? false;
        return PermissionActions(
          create: create,
          view: view,
          read: view,
          edit: edit,
          update: edit,
          delete: delete,
          fullAccess: calculateFullAccess(create, view, edit, delete),
        );
      case 'view':
        final create = perms.create ?? false;
        final view = value;
        final edit = perms.edit ?? perms.update ?? false;
        final delete = perms.delete ?? false;
        return PermissionActions(
          create: create,
          view: view,
          read: view,
          edit: edit,
          update: edit,
          delete: delete,
          fullAccess: calculateFullAccess(create, view, edit, delete),
        );
      case 'edit':
        final create = perms.create ?? false;
        final view = perms.view ?? perms.read ?? false;
        final edit = value;
        final delete = perms.delete ?? false;
        return PermissionActions(
          create: create,
          view: view,
          read: view,
          edit: edit,
          update: edit,
          delete: delete,
          fullAccess: calculateFullAccess(create, view, edit, delete),
        );
      case 'delete':
        final create = perms.create ?? false;
        final view = perms.view ?? perms.read ?? false;
        final edit = perms.edit ?? perms.update ?? false;
        final delete = value;
        return PermissionActions(
          create: create,
          view: view,
          read: view,
          edit: edit,
          update: edit,
          delete: delete,
          fullAccess: calculateFullAccess(create, view, edit, delete),
        );
      case 'fullAccess':
        return PermissionActions(
          create: value,
          view: value,
          read: value,
          edit: value,
          update: value,
          delete: value,
          fullAccess: value,
        );
      default:
        return perms;
    }
  }

  bool hasChanges(List<AssignedUser> currentAssignedUsers) {
    final hasFormChanges =
        state.roleName.trim() != state.originalRoleName.trim() ||
        state.designation.trim() != state.originalDesignation.trim() ||
        state.description.trim() != state.originalDescription.trim();

    final snapshotUserIds = state.snapshotAssignedUsers
        .map((u) => u.userId)
        .toSet();
    final currentUserIds = currentAssignedUsers.map((u) => u.userId).toSet();
    final hasUserChanges =
        snapshotUserIds.length != currentUserIds.length ||
        !snapshotUserIds.containsAll(currentUserIds) ||
        !currentUserIds.containsAll(snapshotUserIds);

    final hasPermissionChanges = _hasPermissionChanges();

    return hasFormChanges || hasUserChanges || hasPermissionChanges;
  }

  bool _hasPermissionChanges() {
    if (state.originalPermissions.isEmpty && state.currentPermissions.isEmpty) {
      return false;
    }

    if (state.originalPermissions.length != state.currentPermissions.length) {
      return true;
    }

    if (state.originalPermissions.isEmpty || state.currentPermissions.isEmpty) {
      return true;
    }

    for (int i = 0; i < state.originalPermissions.length; i++) {
      final original = state.originalPermissions[i];
      final current = state.currentPermissions[i];

      if (original.featureName != current.featureName) {
        return true;
      }

      final origPerms = original.permissions;
      final currPerms = current.permissions;

      if (origPerms == null && currPerms != null) return true;
      if (origPerms != null && currPerms == null) return true;
      if (origPerms == null && currPerms == null) continue;

      final origCreate = origPerms!.create ?? false;
      final currCreate = currPerms!.create ?? false;

      final origView = origPerms.view ?? origPerms.read ?? false;
      final currView = currPerms.view ?? currPerms.read ?? false;

      final origEdit = origPerms.edit ?? origPerms.update ?? false;
      final currEdit = currPerms.edit ?? currPerms.update ?? false;

      final origDelete = origPerms.delete ?? false;
      final currDelete = currPerms.delete ?? false;

      final origFullAccess = origPerms.fullAccess ?? false;
      final currFullAccess = currPerms.fullAccess ?? false;

      if (origCreate != currCreate ||
          origView != currView ||
          origEdit != currEdit ||
          origDelete != currDelete ||
          origFullAccess != currFullAccess) {
        return true;
      }
    }

    return false;
  }
}
