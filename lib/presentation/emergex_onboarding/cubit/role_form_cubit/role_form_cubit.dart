import 'package:emergex/data/model/upload_doc/modules_and_features_response.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/upload_doc_use_case/upload_doc_use_case.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/permission_constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Export types used in this cubit
export 'package:emergex/data/model/upload_doc/role_details_response.dart'
    show RoleDetails, AssignedUser, ModulePermission;
export 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart'
    show FeaturePermission, PermissionActions;
export 'package:emergex/data/model/upload_doc/modules_and_features_response.dart'
    show Feature, Module;

/// Unified form mode
enum RoleFormMode { create, edit }

/// Unified form state for both create and edit
class RoleFormState extends Equatable {
  final RoleFormMode mode;
  final String roleName;
  final String designation;
  final String description;
  final String? roleNameError;
  final String? designationError;
  final String? descriptionError;

  // For create mode: Map<featureId, List<bool>>
  final Map<String, List<bool>> featureToggles;

  // For both modes
  final List<Feature> features;
  final List<Module> modules;
  final bool isLoadingFeatures;
  final String? featuresError;

  // For edit mode: stores current permissions from API
  final List<FeaturePermission> currentPermissions;

  // For create mode: selected users
  final List<AssignedUser> selectedUsers;

  // Original data for comparison (edit mode)
  final String? originalRoleId;
  final String? originalRoleName;
  final String? originalDesignation;
  final String? originalDescription;
  final List<FeaturePermission> originalPermissions;
  final List<AssignedUser> originalAssignedUsers;

  const RoleFormState({
    this.mode = RoleFormMode.create,
    this.roleName = '',
    this.designation = '',
    this.description = '',
    this.roleNameError,
    this.designationError,
    this.descriptionError,
    this.featureToggles = const {},
    this.features = const [],
    this.modules = const [],
    this.isLoadingFeatures = false,
    this.featuresError,
    this.currentPermissions = const [],
    this.selectedUsers = const [],
    this.originalRoleId,
    this.originalRoleName,
    this.originalDesignation,
    this.originalDescription,
    this.originalPermissions = const [],
    this.originalAssignedUsers = const [],
  });

  RoleFormState copyWith({
    RoleFormMode? mode,
    String? roleName,
    String? designation,
    String? description,
    String? roleNameError,
    String? designationError,
    String? descriptionError,
    bool clearRoleNameError = false,
    bool clearDesignationError = false,
    bool clearDescriptionError = false,
    Map<String, List<bool>>? featureToggles,
    List<Feature>? features,
    List<Module>? modules,
    bool? isLoadingFeatures,
    String? featuresError,
    bool clearFeaturesError = false,
    List<FeaturePermission>? currentPermissions,
    List<AssignedUser>? selectedUsers,
    String? originalRoleId,
    String? originalRoleName,
    String? originalDesignation,
    String? originalDescription,
    List<FeaturePermission>? originalPermissions,
    List<AssignedUser>? originalAssignedUsers,
  }) {
    return RoleFormState(
      mode: mode ?? this.mode,
      roleName: roleName ?? this.roleName,
      designation: designation ?? this.designation,
      description: description ?? this.description,
      roleNameError: clearRoleNameError
          ? null
          : (roleNameError ?? this.roleNameError),
      designationError: clearDesignationError
          ? null
          : (designationError ?? this.designationError),
      descriptionError: clearDescriptionError
          ? null
          : (descriptionError ?? this.descriptionError),
      featureToggles: featureToggles ?? this.featureToggles,
      features: features ?? this.features,
      modules: modules ?? this.modules,
      isLoadingFeatures: isLoadingFeatures ?? this.isLoadingFeatures,
      featuresError: clearFeaturesError
          ? null
          : (featuresError ?? this.featuresError),
      currentPermissions: currentPermissions ?? this.currentPermissions,
      selectedUsers: selectedUsers ?? this.selectedUsers,
      originalRoleId: originalRoleId ?? this.originalRoleId,
      originalRoleName: originalRoleName ?? this.originalRoleName,
      originalDesignation: originalDesignation ?? this.originalDesignation,
      originalDescription: originalDescription ?? this.originalDescription,
      originalPermissions: originalPermissions ?? this.originalPermissions,
      originalAssignedUsers:
          originalAssignedUsers ?? this.originalAssignedUsers,
    );
  }

  List<Map<String, dynamic>> get permissionSections {
    return features.map((feature) {
      final toggles =
          featureToggles[feature.featureId] ??
          [false, false, false, false, false];
      return {
        'title': feature.name,
        'toggles': toggles,
        'featureName': feature.name,
        'featureId': feature.featureId,
      };
    }).toList();
  }

  /// Get modules with their features grouped
  List<Map<String, dynamic>> get modulesWithFeatures {
    return modules.map((module) {
      final moduleFeatures = module.features.map((feature) {
        final toggles =
            featureToggles[feature.featureId] ??
            [false, false, false, false, false];
        return {
          'title': feature.name,
          'toggles': toggles,
          'featureName': feature.name,
          'featureId': feature.featureId,
        };
      }).toList();

      return {
        'moduleId': module.id,
        'moduleName': module.name,
        'moduleDesc': module.desc,
        'features': moduleFeatures,
      };
    }).toList();
  }

  @override
  List<Object?> get props => [
    mode,
    roleName,
    designation,
    description,
    roleNameError,
    designationError,
    descriptionError,
    featureToggles,
    features,
    modules,
    isLoadingFeatures,
    featuresError,
    currentPermissions,
    selectedUsers,
    originalRoleId,
    originalRoleName,
    originalDesignation,
    originalDescription,
    originalPermissions,
    originalAssignedUsers,
  ];
}

/// Permission Mapping Target - represents a target permission to be updated
class PermissionTarget {
  final String? targetModule;
  final String targetFeature;
  final String targetField;
  final bool targetValue;

  const PermissionTarget({
    this.targetModule,
    required this.targetFeature,
    required this.targetField,
    required this.targetValue,
  });
}

/// Permission Mapping Rule - defines cascading permission dependencies
class PermissionMappingRule {
  final String? sourceModule;
  final String sourceFeature;
  final String sourceField;
  final bool sourceValue;
  final List<PermissionTarget> targets;

  const PermissionMappingRule({
    this.sourceModule,
    required this.sourceFeature,
    required this.sourceField,
    required this.sourceValue,
    required this.targets,
  });
}

/// Unified cubit for both create and edit role forms
class RoleFormCubit extends Cubit<RoleFormState> {
  final OnboardingOrganizationStructureUseCase _useCase;

  // Permission mapping rules - comprehensive auto-enabling logic based on module and feature dependencies
  static const List<PermissionMappingRule> permissionMapping = [
    // ========================================
    // EmergeX Client Onboarding Module Rules
    // ========================================

    // Rule: Upload or Reupload files (fullAccess) → Enable EmergeX Client, Projects (view)
    PermissionMappingRule(
      sourceModule: "EmergeX Client Onboarding",
      sourceFeature: "Upload or Reupload files",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "EmergeX Client Onboarding",
          targetFeature: "EmergeX Client",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "EmergeX Client Onboarding",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Upload or Reupload files",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "view",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),
    // Rule: Role Management (create) → Enable Projects (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "create",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Member Management",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Member Management",
          targetField: "create",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Member Management",
          targetField: "delete",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Role Management (delete) → Enable Projects (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "delete",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Role Management (edit) → Enable Projects (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "edit",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Role Management (view) → Enable Projects (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "view",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Role Management (fullAccess) → Enable Projects (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Role Management",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Member Management (create) → Enable Projects, Role Management (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "create",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Member Management (delete) → Enable Projects, Role Management (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "delete",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Member Management (edit) → Enable Projects, Role Management (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "edit",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Member Management (view) → Enable Projects, Role Management (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "view",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Role Management",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Member Management (fullAccess) → Enable Projects, Role Management (view)
    PermissionMappingRule(
      sourceModule: "Client Admin",
      sourceFeature: "Member Management",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Client Admin",
          targetFeature: "Projects",
          targetField: "view",
          targetValue: true,
        ),
        PermissionTarget(
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

    // Rule: Upload file (fullAccess) → Enable EmergeX Case (view)
    PermissionMappingRule(
      sourceModule: "Incident Reporting & Monitoring",
      sourceFeature: "Upload file (img, pdf, etc)",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "EmergeX Case",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Switch Categories (fullAccess) → Enable EmergeX Case (view)
    PermissionMappingRule(
      sourceModule: "Incident Reporting & Monitoring",
      sourceFeature:
          "Switch Categories (Intervention, Observation, Incident, Near Miss)",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "EmergeX Case",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Approval of Incident (fullAccess) → Enable EmergeX Case (view)
    PermissionMappingRule(
      sourceModule: "Incident Reporting & Monitoring",
      sourceFeature: "Approval of Incident",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "EmergeX Case",
          targetField: "view",
          targetValue: true,
        ),
      ],
    ),

    // Rule: Approval of Incident (fullAccess) → Enable Upload File AND Switch Categories
    PermissionMappingRule(
      sourceModule: "Incident Reporting & Monitoring",
      sourceFeature: "Approval of Incident",
      sourceField: "fullAccess",
      sourceValue: true,
      targets: [
        PermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature: "Upload file (img, pdf, etc)",
          targetField: "fullAccess",
          targetValue: true,
        ),
        PermissionTarget(
          targetModule: "Incident Reporting & Monitoring",
          targetFeature:
              "Switch Categories (Intervention, Observation, Incident, Near Miss)",
          targetField: "fullAccess",
          targetValue: true,
        ),
      ],
    ),
  ];

  RoleFormCubit(this._useCase) : super(const RoleFormState());

  /// Initialize for create mode
  void initializeForCreate() {
    emit(const RoleFormState(mode: RoleFormMode.create));
  }

  /// Initialize for edit mode with existing role data
  void initializeForEdit(
    RoleDetails roleDetails,
    List<AssignedUser> assignedUsers,
  ) {
    // Convert permissions to feature toggles for UI
    final toggles = <String, List<bool>>{};

    // Helper function to normalize permissions
    FeaturePermission normalizePermission(FeaturePermission p) {
      final perms = p.permissions;
      return FeaturePermission(
        featureName: p.featureName,
        moduleName: p.moduleName,
        moduleDesc: p.moduleDesc,
        featureId: p.featureId,
        desc: p.desc,
        permissions: perms != null
            ? PermissionActions(
                create: perms.create ?? false,
                view: (perms.view ?? false) || (perms.read ?? false),
                read: (perms.read ?? false) || (perms.view ?? false),
                edit: (perms.edit ?? false) || (perms.update ?? false),
                update: (perms.update ?? false) || (perms.edit ?? false),
                delete: perms.delete ?? false,
                fullAccess: perms.fullAccess ?? false,
              )
            : PermissionActions(
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

    // Normalize both current and original permissions for consistent comparison
    final normalizedCurrentPermissions = roleDetails.permissions
        .map(normalizePermission)
        .toList();
    final normalizedOriginalPermissions = roleDetails.permissions
        .map(normalizePermission)
        .toList();

    // Create copy of assigned users for original comparison
    final assignedUsersCopy = assignedUsers.map((u) {
      return AssignedUser(userId: u.userId, name: u.name, email: u.email);
    }).toList();

    // Store original data for comparison
    emit(
      RoleFormState(
        mode: RoleFormMode.edit,
        roleName: roleDetails.roleName,
        designation: roleDetails.designation,
        description: roleDetails.description,
        currentPermissions: normalizedCurrentPermissions,
        originalRoleId: roleDetails.roleId,
        originalRoleName: roleDetails.roleName,
        originalDesignation: roleDetails.designation,
        originalDescription: roleDetails.description,
        originalPermissions: normalizedOriginalPermissions,
        originalAssignedUsers: assignedUsersCopy,
        featureToggles: toggles,
      ),
    );
  }

  /// Load features from API for a given project (create mode)
  Future<void> loadFeatures(String projectId) async {
    emit(state.copyWith(isLoadingFeatures: true, clearFeaturesError: true));

    final response = await _useCase.fetchFeatures(projectId);

    final data = response.data;
    if (response.success == true && data != null) {
      if (data.modules.isEmpty) {
        emit(
          state.copyWith(
            isLoadingFeatures: false,
            featuresError: 'No features found',
          ),
        );
        return;
      }
      // Extract all features from all modules
      final allFeatures = <Feature>[];
      for (final module in data.modules) {
        allFeatures.addAll(module.features);
      }

      // Initialize toggles for all features
      final toggles = <String, List<bool>>{};
      for (final feature in allFeatures) {
        toggles[feature.featureId] = [false, false, false, false, false];
      }

      emit(
        state.copyWith(
          modules: data.modules,
          features: allFeatures,
          featureToggles: toggles,
          isLoadingFeatures: false,
          clearFeaturesError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoadingFeatures: false,
          featuresError: response.error ?? 'Failed to load features',
        ),
      );
    }
  }

  void updateRoleName(String roleName) {
    emit(state.copyWith(roleName: roleName, clearRoleNameError: true));
  }

  void updateDesignation(String designation) {
    emit(state.copyWith(designation: designation, clearDesignationError: true));
  }

  void updateDescription(String description) {
    emit(state.copyWith(description: description, clearDescriptionError: true));
  }

  void setRoleNameError(String? error) {
    emit(state.copyWith(roleNameError: error));
  }

  void setDesignationError(String? error) {
    emit(state.copyWith(designationError: error));
  }

  void setDescriptionError(String? error) {
    emit(state.copyWith(descriptionError: error));
  }

  void clearAllErrors() {
    emit(
      state.copyWith(
        clearRoleNameError: true,
        clearDesignationError: true,
        clearDescriptionError: true,
      ),
    );
  }

  /// Convert field name to index
  /// Returns -1 if field name is invalid
  int _fieldNameToIndex(String fieldName) {
    switch (fieldName.toLowerCase()) {
      case 'create':
        return 0;
      case 'view':
      case 'read':
        return 1;
      case 'edit':
      case 'update':
        return 2;
      case 'delete':
        return 3;
      case 'fullaccess':
        return 4;
      default:
        return -1;
    }
  }

  /// Convert index to field name
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

  /// Find feature by name and return its featureId
  String? _findFeatureIdByName(String featureName) {
    try {
      final feature = state.features.firstWhere((f) => f.name == featureName);
      return feature.featureId;
    } catch (e) {
      return null;
    }
  }

  /// Find feature by module and feature name, return its featureId
  String? _findFeatureIdByModuleAndName(
    String? moduleName,
    String featureName,
  ) {
    if (moduleName == null) {
      return _findFeatureIdByName(featureName);
    }

    try {
      // Find the module first
      final module = state.modules.firstWhere((m) => m.name == moduleName);
      // Find the feature within that module
      final feature = module.features.firstWhere((f) => f.name == featureName);
      return feature.featureId;
    } catch (e) {
      return null;
    }
  }

  /// Find module name for a given feature
  String? _findModuleNameForFeature(String featureId) {
    try {
      final module = state.modules.firstWhere(
        (m) => m.features.any((f) => f.featureId == featureId),
      );
      return module.name;
    } catch (e) {
      return null;
    }
  }

  /// Apply permission mapping rules for create mode
  Map<String, List<bool>> _applyPermissionRules(
    Map<String, List<bool>> toggles,
    String featureId,
    String fieldName,
    bool value,
  ) {
    var updatedToggles = Map<String, List<bool>>.from(toggles);
    final fieldIndex = _fieldNameToIndex(fieldName);

    if (fieldIndex == -1) {
      return updatedToggles;
    }

    // Find the module for the current feature using featureId
    final currentFeature = state.features.firstWhere(
      (f) => f.featureId == featureId,
      orElse: () => Feature(featureId: '', name: '', desc: ''),
    );
    final featureName = currentFeature.name;
    final currentModuleName = currentFeature.featureId.isNotEmpty
        ? _findModuleNameForFeature(currentFeature.featureId)
        : null;

    // Track changes for cascading updates
    final changedFeatures = <String, Map<int, bool>>{};

    // Special Rule for Incident Reporting: If EmergeX Case View is disabled, disable all other permissions
    final emergeXCaseFeatureId = _findFeatureIdByModuleAndName(
      "Incident Reporting & Monitoring",
      "EmergeX Case",
    );
    if (emergeXCaseFeatureId != null &&
        currentFeature.featureId == emergeXCaseFeatureId &&
        fieldName == "view" &&
        value == false) {
      // Disable all permissions for EmergeX Case
      updatedToggles[emergeXCaseFeatureId] = [
        false,
        false,
        false,
        false,
        false,
      ];
    }

    // Forward rules: Apply when source changes
    for (final rule in permissionMapping) {
      // Check if this rule matches the current change
      final matchesModule =
          rule.sourceModule == null || rule.sourceModule == currentModuleName;
      final matchesFeature = rule.sourceFeature == featureName;
      final matchesField = rule.sourceField == fieldName;
      final matchesValue = rule.sourceValue == value;

      if (matchesModule && matchesFeature && matchesField && matchesValue) {
        // Apply all targets for this rule
        for (final target in rule.targets) {
          final targetFeatureId = _findFeatureIdByModuleAndName(
            target.targetModule,
            target.targetFeature,
          );

          if (targetFeatureId != null) {
            final targetFieldIndex = _fieldNameToIndex(target.targetField);
            if (targetFieldIndex != -1) {
              final targetToggles = List<bool>.from(
                updatedToggles[targetFeatureId] ??
                    [false, false, false, false, false],
              );

              // Only update if value is different to avoid infinite loops
              if (targetToggles[targetFieldIndex] != target.targetValue) {
                targetToggles[targetFieldIndex] = target.targetValue;
                updatedToggles[targetFeatureId] = targetToggles;

                // Track this change for potential cascading
                if (!changedFeatures.containsKey(targetFeatureId)) {
                  changedFeatures[targetFeatureId] = {};
                }
                changedFeatures[targetFeatureId]![targetFieldIndex] =
                    target.targetValue;
              }
            }
          }
        }
      }
    }

    // Reverse rules: When target is disabled, disable the source
    for (final rule in permissionMapping) {
      for (final target in rule.targets) {
        final targetMatchesModule =
            target.targetModule == null ||
            target.targetModule == currentModuleName;
        final targetMatchesFeature = target.targetFeature == featureName;
        final targetMatchesField = target.targetField == fieldName;

        if (targetMatchesModule &&
            targetMatchesFeature &&
            targetMatchesField &&
            value == false) {
          // Find the source feature
          final sourceFeatureId = _findFeatureIdByModuleAndName(
            rule.sourceModule,
            rule.sourceFeature,
          );

          if (sourceFeatureId != null) {
            final sourceToggles = List<bool>.from(
              updatedToggles[sourceFeatureId] ??
                  [false, false, false, false, false],
            );

            // If the target is being disabled, disable the source
            final sourceFieldIndex = _fieldNameToIndex(rule.sourceField);
            if (sourceFieldIndex != -1 && sourceToggles[sourceFieldIndex]) {
              sourceToggles[sourceFieldIndex] = false;

              // If the source field is fullAccess, disable all permissions for that feature
              if (rule.sourceField == 'fullAccess') {
                for (int i = 0; i < sourceToggles.length; i++) {
                  sourceToggles[i] = false;
                }
              }

              updatedToggles[sourceFeatureId] = sourceToggles;

              // Track this change for potential cascading
              if (!changedFeatures.containsKey(sourceFeatureId)) {
                changedFeatures[sourceFeatureId] = {};
              }
              changedFeatures[sourceFeatureId]![sourceFieldIndex] = false;
            }
          }
        }
      }
    }

    // Cascading behavior disabled - only direct rule targets are applied
    // This prevents unwanted chain reactions in permission dependencies

    return updatedToggles;
  }

  /// Apply permission mapping rules with cascading support
  /// For create mode: uses featureToggles Map
  /// For edit mode: uses currentPermissions List
  void _applyPermissionRulesForEdit(
    String featureName,
    String? moduleName,
    String fieldName,
    bool value,
  ) {
    final updatedPermissions = List<FeaturePermission>.from(
      state.currentPermissions,
    );

    // Track changes for cascading updates
    final changedFeatures = <String, Map<String, bool>>{};

    // Forward rules: Apply when source changes
    for (final rule in permissionMapping) {
      // Check if this rule matches the current change
      final matchesModule =
          rule.sourceModule == null || rule.sourceModule == moduleName;
      final matchesFeature = rule.sourceFeature == featureName;
      final matchesField = rule.sourceField == fieldName;
      final matchesValue = rule.sourceValue == value;

      if (matchesModule && matchesFeature && matchesField && matchesValue) {
        // Apply all targets for this rule
        for (final target in rule.targets) {
          final targetIndex = updatedPermissions.indexWhere(
            (p) =>
                p.featureName == target.targetFeature &&
                (target.targetModule == null ||
                    p.moduleName == target.targetModule),
          );

          if (targetIndex != -1) {
            final currentPerm = updatedPermissions[targetIndex];
            final perms = currentPerm.permissions;

            if (perms != null) {
              final targetFieldIndex = _fieldNameToIndex(target.targetField);
              final currentValue = _getPermissionValue(perms, targetFieldIndex);

              // Only update if value is different
              if (currentValue != target.targetValue) {
                final updatedPerms = _updatePermissionValue(
                  perms,
                  targetFieldIndex,
                  target.targetValue,
                );
                updatedPermissions[targetIndex] = FeaturePermission(
                  featureName: currentPerm.featureName ?? '',
                  moduleName: currentPerm.moduleName ?? '',
                  featureId: currentPerm.featureId,  // Preserve featureId
                  desc: currentPerm.desc,  // Preserve desc
                  moduleDesc: currentPerm.moduleDesc,  // Preserve moduleDesc
                  permissions: updatedPerms,
                );

                // Track this change
                if (!changedFeatures.containsKey(target.targetFeature)) {
                  changedFeatures[target.targetFeature] = {};
                }
                changedFeatures[target.targetFeature]![target.targetField] =
                    target.targetValue;
              }
            }
          }
        }
      }
    }

    // Reverse rules: When target is disabled, disable the source
    for (final rule in permissionMapping) {
      for (final target in rule.targets) {
        final targetMatchesModule =
            target.targetModule == null || target.targetModule == moduleName;
        final targetMatchesFeature = target.targetFeature == featureName;
        final targetMatchesField = target.targetField == fieldName;

        if (targetMatchesModule &&
            targetMatchesFeature &&
            targetMatchesField &&
            value == false) {
          // Find the source feature
          final sourceIndex = updatedPermissions.indexWhere(
            (p) =>
                p.featureName == rule.sourceFeature &&
                (rule.sourceModule == null ||
                    p.moduleName == rule.sourceModule),
          );

          if (sourceIndex != -1) {
            final sourcePerm = updatedPermissions[sourceIndex];
            final perms = sourcePerm.permissions;

            if (perms != null) {
              final sourceFieldIndex = _fieldNameToIndex(rule.sourceField);
              final currentValue = _getPermissionValue(perms, sourceFieldIndex);

              if (currentValue == true) {
                var updatedPerms = _updatePermissionValue(
                  perms,
                  sourceFieldIndex,
                  false,
                );

                // If the source field is fullAccess, disable all permissions
                if (rule.sourceField == 'fullAccess') {
                  updatedPerms = PermissionActions(
                    create: false,
                    view: false,
                    read: false,
                    edit: false,
                    update: false,
                    delete: false,
                    fullAccess: false,
                  );
                }

                updatedPermissions[sourceIndex] = FeaturePermission(
                  featureName: sourcePerm.featureName ?? '',
                  moduleName: sourcePerm.moduleName ?? '',
                  featureId: sourcePerm.featureId,  // Preserve featureId
                  desc: sourcePerm.desc,  // Preserve desc
                  moduleDesc: sourcePerm.moduleDesc,  // Preserve moduleDesc
                  permissions: updatedPerms,
                );
              }
            }
          }
        }
      }
    }

    emit(state.copyWith(currentPermissions: updatedPermissions));
  }

  /// Get permission value by index
  bool _getPermissionValue(PermissionActions perms, int index) {
    switch (index) {
      case 0:
        return perms.create ?? false;
      case 1:
        return (perms.view ?? false) || (perms.read ?? false);
      case 2:
        return (perms.edit ?? false) || (perms.update ?? false);
      case 3:
        return perms.delete ?? false;
      case 4:
        return perms.fullAccess ?? false;
      default:
        return false;
    }
  }

  /// Update permission value by index
  PermissionActions _updatePermissionValue(
    PermissionActions perms,
    int index,
    bool value,
  ) {
    switch (index) {
      case 0:
        return PermissionActions(
          create: value,
          view: perms.view,
          read: perms.read,
          edit: perms.edit,
          update: perms.update,
          delete: perms.delete,
          fullAccess: perms.fullAccess,
        );
      case 1:
        return PermissionActions(
          create: perms.create,
          view: value,
          read: value,
          edit: perms.edit,
          update: perms.update,
          delete: perms.delete,
          fullAccess: perms.fullAccess,
        );
      case 2:
        return PermissionActions(
          create: perms.create,
          view: perms.view,
          read: perms.read,
          edit: value,
          update: value,
          delete: perms.delete,
          fullAccess: perms.fullAccess,
        );
      case 3:
        return PermissionActions(
          create: perms.create,
          view: perms.view,
          read: perms.read,
          edit: perms.edit,
          update: perms.update,
          delete: value,
          fullAccess: perms.fullAccess,
        );
      case 4:
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

  /// Unified permission update method that works for both create and edit modes
  void updatePermission(
    String featureName,
    String? moduleName,
    int index,
    bool value,
  ) {
    if (state.mode == RoleFormMode.edit) {
      _updatePermissionEdit(featureName, moduleName, index, value);
    } else {
      // For create mode, use feature ID
      final featureId = _findFeatureIdByModuleAndName(moduleName, featureName);
      if (featureId != null) {
        togglePermission(featureId, index);
      }
    }
  }

  /// Update permission for edit mode
  void _updatePermissionEdit(
    String featureName,
    String? moduleName,
    int index,
    bool value,
  ) {
    final updatedPermissions = List<FeaturePermission>.from(
      state.currentPermissions,
    );

    // Find the permission to update
    final permissionIndex = updatedPermissions.indexWhere(
      (p) =>
          p.featureName == featureName &&
          (moduleName == null || p.moduleName == moduleName),
    );

    if (permissionIndex == -1) return;

    final currentPermission = updatedPermissions[permissionIndex];
    final perms = currentPermission.permissions;

    if (perms == null) return;

    // Check if this feature is full access only
    final isFullAccessOnly = isFullAccessOnlyFeature(featureName);

    // For full access only features, only allow toggling fullAccess (index 4)
    if (isFullAccessOnly && index != 4) {
      return;
    }

    bool create = perms.create ?? false;
    bool view = (perms.view ?? false) || (perms.read ?? false);
    bool edit = (perms.edit ?? false) || (perms.update ?? false);
    bool delete = perms.delete ?? false;
    bool fullAccess = perms.fullAccess ?? false;

    // Apply toggle logic based on index
    if (index == 4) {
      // fullAccess: toggle all permissions
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
      switch (index) {
        case 0:
          create = value;
          break;
        case 2:
          edit = value;
          break;
        case 3:
          delete = value;
          break;
      }

      // If turning on any permission, also turn on view
      if (value) {
        view = true;
      }

      // Check if all permissions are selected to set fullAccess
      fullAccess = create && view && edit && delete;
    }

    // Update the permission - preserve featureId, desc, moduleDesc from original
    updatedPermissions[permissionIndex] = FeaturePermission(
      featureName: featureName,
      moduleName: moduleName,
      featureId: currentPermission.featureId,  // Preserve featureId
      desc: currentPermission.desc,  // Preserve desc
      moduleDesc: currentPermission.moduleDesc,  // Preserve moduleDesc
      permissions: PermissionActions(
        create: create,
        view: view,
        read: view,
        edit: edit,
        update: edit,
        delete: delete,
        fullAccess: fullAccess,
      ),
    );

    emit(state.copyWith(currentPermissions: updatedPermissions));

    // Apply permission mapping rules
    final fieldName = _indexToFieldName(index);
    if (fieldName.isNotEmpty) {
      _applyPermissionRulesForEdit(featureName, moduleName, fieldName, value);
    }
  }

  /// Toggle permission for create mode
  void togglePermission(String featureId, int index) {
    final currentToggles =
        state.featureToggles[featureId] ?? [false, false, false, false, false];
    final newToggles = List<bool>.from(currentToggles);

    // Ensure index is within bounds
    if (index < 0 || index >= newToggles.length) {
      return;
    }

    // Find feature name for permission rules
    final feature = state.features.firstWhere(
      (f) => f.featureId == featureId,
      orElse: () => Feature(featureId: featureId, name: '', desc: ''),
    );
    final featureName = feature.name;
    final fieldName = _indexToFieldName(index);

    // Check if this feature is full access only
    final isFullAccessOnly = isFullAccessOnlyFeature(featureName);

    // For full access only features, only allow toggling the fullAccess permission (index 4)
    if (isFullAccessOnly && index != 4) {
      return;
    }

    // Index mapping: 0=create, 1=view, 2=edit, 3=delete, 4=fullAccess
    if (index == 4) {
      // fullAccess: toggle all permissions to the same value
      final newValue = !newToggles[4];
      for (int i = 0; i < newToggles.length; i++) {
        newToggles[i] = newValue;
      }
    } else if (index == 1) {
      // view: special logic
      final newViewValue = !newToggles[1];

      if (!newViewValue) {
        // Turning off view: turn off all permissions
        newToggles[1] = false;
        newToggles[0] = false;
        newToggles[2] = false;
        newToggles[3] = false;
        newToggles[4] = false;
      } else {
        // Turning on view: turn on view and check if all are selected
        newToggles[1] = true;
        final allSelected =
            newToggles[0] && newToggles[1] && newToggles[2] && newToggles[3];
        newToggles[4] = allSelected;
      }
    } else {
      // create (0), edit (2), or delete (3)
      final newValue = !newToggles[index];
      newToggles[index] = newValue;

      // If turning on any permission, also turn on view
      if (newValue) {
        newToggles[1] = true;
      }

      // Check if all permissions are selected to set fullAccess
      final allSelected =
          newToggles[0] && newToggles[1] && newToggles[2] && newToggles[3];
      newToggles[4] = allSelected;
    }

    // Update the toggles map
    var updatedToggles = Map<String, List<bool>>.from(state.featureToggles);
    updatedToggles[featureId] = newToggles;

    // Apply permission mapping rules
    if (featureName.isNotEmpty && fieldName.isNotEmpty) {
      updatedToggles = _applyPermissionRules(
        updatedToggles,
        featureId,
        fieldName,
        newToggles[index],
      );
    }

    emit(state.copyWith(featureToggles: updatedToggles));
  }

  /// Check if form has changes (for edit mode)
  bool hasChanges(List<AssignedUser> currentAssignedUsers) {
    if (state.mode != RoleFormMode.edit) return false;

    // Check text fields
    if (state.roleName != state.originalRoleName ||
        state.designation != state.originalDesignation ||
        state.description != state.originalDescription) {
      return true;
    }

    // Check assigned users
    if (currentAssignedUsers.length != state.originalAssignedUsers.length) {
      return true;
    }

    final currentUserIds = currentAssignedUsers.map((u) => u.userId).toSet();
    final originalUserIds = state.originalAssignedUsers
        .map((u) => u.userId)
        .toSet();
    if (!currentUserIds.containsAll(originalUserIds) ||
        !originalUserIds.containsAll(currentUserIds)) {
      return true;
    }

    // Check permissions
    if (state.currentPermissions.length != state.originalPermissions.length) {
      return true;
    }

    for (int i = 0; i < state.currentPermissions.length; i++) {
      final current = state.currentPermissions[i];
      // Match by both featureName and moduleName for accurate comparison
      final original = state.originalPermissions.firstWhere(
        (p) =>
            p.featureName == current.featureName &&
            p.moduleName == current.moduleName,
        orElse: () => const FeaturePermission(
          featureName: '',
          permissions: PermissionActions(),
        ),
      );

      // If no match found (featureName is empty), consider it a change
      if (original.featureName?.isEmpty ?? true) {
        return true;
      }

      if (!_permissionsEqual(current.permissions, original.permissions)) {
        return true;
      }
    }

    return false;
  }

  /// Compare two PermissionActions objects
  /// Treats null as false for boolean comparisons
  bool _permissionsEqual(PermissionActions? p1, PermissionActions? p2) {
    if (p1 == null && p2 == null) return true;

    // Treat null PermissionActions as all false
    final create1 = p1?.create ?? false;
    final create2 = p2?.create ?? false;
    final view1 = (p1?.view ?? false) || (p1?.read ?? false);
    final view2 = (p2?.view ?? false) || (p2?.read ?? false);
    final edit1 = (p1?.edit ?? false) || (p1?.update ?? false);
    final edit2 = (p2?.edit ?? false) || (p2?.update ?? false);
    final delete1 = p1?.delete ?? false;
    final delete2 = p2?.delete ?? false;
    final fullAccess1 = p1?.fullAccess ?? false;
    final fullAccess2 = p2?.fullAccess ?? false;

    return create1 == create2 &&
        view1 == view2 &&
        edit1 == edit2 &&
        delete1 == delete2 &&
        fullAccess1 == fullAccess2;
  }

  /// Add user to selected users (create mode)
  void addUser(AssignedUser user) {
    if (!state.selectedUsers.any((u) => u.userId == user.userId)) {
      emit(state.copyWith(selectedUsers: [...state.selectedUsers, user]));
    }
  }

  /// Remove user from selected users (create mode)
  void removeUser(String userId) {
    emit(
      state.copyWith(
        selectedUsers: state.selectedUsers
            .where((u) => u.userId != userId)
            .toList(),
      ),
    );
  }

  bool validateForm() {
    bool isValid = true;

    if (state.roleName.trim().isEmpty) {
      setRoleNameError('Role Name is required');
      isValid = false;
    }

    if (state.designation.trim().isEmpty) {
      setDesignationError('Designation is required');
      isValid = false;
    }

    if (state.description.trim().isEmpty) {
      setDescriptionError('Description is required');
      isValid = false;
    }

    return isValid;
  }

  /// Build permissions in the new structure grouped by modules (for create mode)
  List<Map<String, dynamic>> buildPermissions() {
    final result = state.modules.map((module) {
      // Build features array for this module
      final features = module.features
          .where((feature) {
            final isValid = feature.featureId.trim().isNotEmpty;
            return isValid;
          })
          .map((feature) {
            final toggles =
                state.featureToggles[feature.featureId] ??
                [false, false, false, false, false];

            return {
              'featureId': feature.featureId.trim(),
              'name': feature.name,
              'desc': feature.desc,
              'permissions': {
                'create': toggles[0],
                'view': toggles[1],
                'edit': toggles[2],
                'delete': toggles[3],
                'fullAccess': toggles[4],
              },
            };
          })
          .toList();

      return {'name': module.name, 'desc': module.desc, 'features': features};
    }).toList();

    return result;
  }

  /// Build permissions for edit mode
  List<Map<String, dynamic>> buildPermissionsForEdit() {
    // Group permissions by module
    final moduleMap = <String, List<FeaturePermission>>{};

    for (final permission in state.currentPermissions) {
      final moduleName = permission.moduleName ?? 'Unknown Module';
      if (!moduleMap.containsKey(moduleName)) {
        moduleMap[moduleName] = [];
      }
      moduleMap[moduleName]!.add(permission);
    }

    // Build the structure with featureId and desc
    return moduleMap.entries.map((entry) {
      // Get moduleDesc from first permission in this module
      final moduleDesc = entry.value.isNotEmpty
          ? entry.value.first.moduleDesc
          : null;

      final features = entry.value
          .map((permission) {
            final perms = permission.permissions;
            return {
              if (permission.featureId != null &&
                  permission.featureId!.isNotEmpty)
                'featureId': permission.featureId!,
              'name': permission.featureName ?? '',
              'desc': permission.desc ?? '',
              'permissions': {
                'create': perms?.create ?? false,
                'view': (perms?.view ?? false) || (perms?.read ?? false),
                'edit': (perms?.edit ?? false) || (perms?.update ?? false),
                'delete': perms?.delete ?? false,
                'fullAccess': perms?.fullAccess ?? false,
              },
            };
          })
          .toList();

      return {
        'name': entry.key,
        'desc': moduleDesc ?? '',
        'features': features,
      };
    }).toList();
  }

  void reset() {
    emit(const RoleFormState());
  }

  bool isFormValid() {
    return state.roleName.trim().isNotEmpty &&
        state.designation.trim().isNotEmpty &&
        state.description.trim().isNotEmpty;
  }

  /// Validate permissions payload before API submission
  /// Returns a list of validation errors, empty if valid
  List<String> validatePermissionsPayload(List<Map<String, dynamic>> permissions) {
    final errors = <String>[];

    for (final module in permissions) {
      final moduleName = module['name'] as String? ?? 'Unknown';
      final features = module['features'] as List<dynamic>? ?? [];

      if (features.isEmpty) {
        errors.add('Module "$moduleName" has empty features array - data may have been lost');
      }

      for (final feature in features) {
        if (feature is Map<String, dynamic>) {
          final featureId = feature['featureId'] as String?;
          final featureName = feature['name'] as String?;

          if (featureId == null || featureId.isEmpty) {
            errors.add('Feature "$featureName" in module "$moduleName" is missing featureId');
          }
        }
      }
    }

    return errors;
  }

  /// Log permissions payload for debugging
  void logPermissionsPayload(List<Map<String, dynamic>> permissions, {String context = ''}) {
    debugPrint('======= PERMISSIONS PAYLOAD ${context.isNotEmpty ? "($context)" : ""} =======');
    debugPrint('Total modules: ${permissions.length}');

    for (final module in permissions) {
      final moduleName = module['name'] as String? ?? 'Unknown';
      final features = module['features'] as List<dynamic>? ?? [];
      debugPrint('  Module: $moduleName (${features.length} features)');

      if (features.isEmpty) {
        debugPrint('    ⚠️ WARNING: Empty features array!');
      }

      for (final feature in features) {
        if (feature is Map<String, dynamic>) {
          final featureId = feature['featureId'] as String?;
          final featureName = feature['name'] as String?;
          final perms = feature['permissions'] as Map<String, dynamic>?;
          debugPrint('    - $featureName (id: ${featureId ?? "MISSING"})');
          if (perms != null) {
            debugPrint('      create: ${perms['create']}, view: ${perms['view']}, edit: ${perms['edit']}, delete: ${perms['delete']}, fullAccess: ${perms['fullAccess']}');
          }
        }
      }
    }
    debugPrint('======= END PERMISSIONS PAYLOAD =======');
  }
}
