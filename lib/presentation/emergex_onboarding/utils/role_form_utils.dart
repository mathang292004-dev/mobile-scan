import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/role_form_cubit/role_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/upload_file_org_str_cubit/onboarding_organization_structure_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Utility class for role form operations
class RoleFormUtils {
  /// Handle role update
  static void handleUpdateRole(
    BuildContext context,
    String? roleId,
    String? projectId,
    RoleDetails? roleDetails,
    List<AssignedUser> assignedUsers,
  ) {
    if (roleId == null || roleId.isEmpty) {
      showSnackBar(context, 'Role ID is required', isSuccess: false);
      return;
    }

    if (projectId == null || projectId.isEmpty) {
      showSnackBar(context, 'Project ID is required', isSuccess: false);
      return;
    }

    final formCubit = context.read<RoleFormCubit>();
    final orgCubit = context.read<OnboardingOrganizationStructureCubit>();

    // Clear previous errors
    formCubit.clearAllErrors();

    // Validate form
    if (!formCubit.validateForm()) {
      return;
    }

    final formState = formCubit.state;

    // Build permissions array - use edit method for update mode
    final permissions = formCubit.buildPermissionsForEdit();

    // Log payload for debugging in debug mode
    if (kDebugMode) {
      formCubit.logPermissionsPayload(permissions, context: 'Update Role');
    }

    // Validate permissions payload before submission
    final validationErrors = formCubit.validatePermissionsPayload(permissions);
    if (validationErrors.isNotEmpty) {
      debugPrint('⚠️ PERMISSION PAYLOAD VALIDATION ERRORS:');
      for (final error in validationErrors) {
        debugPrint('  - $error');
      }
      // Show warning but allow submission (data might be intentionally empty)
      // Uncomment below to block submission on validation errors:
      // showSnackBar(context, 'Permission data validation failed', isSuccess: false);
      // return;
    }

    // Build payload with roleId included for update
    final payload = {
      'roleId': roleId,
      'projectId': projectId,
      'roleName': formState.roleName.trim(),
      'designation': formState.designation.trim(),
      'description': formState.description.trim(),
      'permissions': permissions,
      'members': assignedUsers.map((u) => u.userId).toList(),
      'status': 'Active',
    };

    // Call API using OnboardingOrganizationStructureCubit
    // The same createRole endpoint handles both create and update
    // based on the presence of roleId in the payload
    orgCubit.createRole(payload);
  }

  /// Handle back navigation with unsaved changes check
  static void handleBackNavigation(
    BuildContext context,
    List<AssignedUser> currentAssignedUsers,
  ) {
    final formCubit = context.read<RoleFormCubit>();
    if (formCubit.hasChanges(currentAssignedUsers)) {
      showErrorDialog(
        context,
        () {
          // Discard Changes - reset and navigate back
          formCubit.reset();
          back();
          back();
        },
        () {
          // Stay on Page - do nothing, just close dialog
          back();
        },
        'Unsaved Changes',
        'You have unsaved changes. Are you sure you want to leave?',
        'Discard Changes',
        'Stay on Page',
      );
    } else {
      // No changes, just navigate back
      formCubit.reset();
      back();
    }
  }
}
