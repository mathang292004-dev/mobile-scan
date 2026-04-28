import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';

/// Utility class for organization structure related operations
class OrganizationStructureUtils {
  /// Convert Role objects from cubit to the format expected by RoleListWidget
  static List<Map<String, dynamic>> convertRolesToMap(List<Role>? roles) {
    if (roles == null || roles.isEmpty) {
      return [];
    }

    return roles
        .where((role) => role.roleId != null && role.roleId!.isNotEmpty)
        .map((role) {
          return {
            'title': role.roleName ?? 'Untitled Role',
            'subtitle': role.designation ?? '',
            'description': role.description ?? '',
            'roleId': role.roleId!,
          };
        })
        .toList();
  }
}
