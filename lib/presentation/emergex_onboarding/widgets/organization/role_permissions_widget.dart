import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/permission_constants.dart';
import 'package:flutter/material.dart';
import 'column_row_togglebutton.dart';

class RolePermissionsWidget extends StatefulWidget {
  final RoleDetails? roleDetails;
  final bool isReadOnly;
  final Function(String featureName, String? moduleName, int index, bool value)?
  onPermissionChanged;

  const RolePermissionsWidget({
    super.key,
    this.roleDetails,
    this.isReadOnly = false,
    this.onPermissionChanged,
  });

  @override
  State<RolePermissionsWidget> createState() => _RolePermissionsWidgetState();
}

class _RolePermissionsWidgetState extends State<RolePermissionsWidget> {
  @override
  Widget build(BuildContext context) {
    // Use modulePermissions if available, otherwise fall back to flat permissions
    final modulePermissions = widget.roleDetails?.modulePermissions;
    final hasModules = modulePermissions?.isNotEmpty ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              TextHelper.permissions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.black4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Display modules if available, otherwise show flat permissions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  if (hasModules && modulePermissions != null)
                    ...modulePermissions.map((module) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorHelper.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ColorHelper.white),
                        ),
                        child: _buildModuleExpansionTile(module),
                      );
                    })
                  else
                    _buildFlatPermissionsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleExpansionTile(ModulePermission module) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      collapsedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          module.moduleName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorHelper.black4,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: module.features.map((permission) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildPermissionSubSection(
                  permission,
                  module.moduleName,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFlatPermissionsSection() {
    final permissions = widget.roleDetails?.permissions ?? [];

    if (permissions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No permissions available',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
        ),
      );
    }

    // Group permissions by feature name to create separate expandable sections
    return Column(
      children: permissions.map((permission) {
        final featureName = permission.featureName ?? 'Unknown Feature';
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorHelper.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ColorHelper.white),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                featureName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.black4,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPermissionSubSection(permission),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionSubSection(
    FeaturePermission permission, [
    String? overrideModuleName,
  ]) {
    final perms = permission.permissions;
    final featureName = permission.featureName ?? 'Unknown Feature';
    final isFullAccessOnly = isFullAccessOnlyFeature(featureName);
    // Create a unique key based on permissions to force rebuild when permissions change
    final permissionKey =
        '${featureName}_${overrideModuleName ?? permission.moduleName}_${perms?.create}_${perms?.view}_${perms?.edit}_${perms?.delete}_${perms?.fullAccess}';

    return ToggleSectionWidget(
      key: ValueKey(permissionKey),
      title: featureName,
      toggles: perms != null
          ? [
              perms.create == true,
              perms.view == true || perms.read == true,
              perms.edit == true || perms.update == true,
              perms.delete == true,
              perms.fullAccess == true,
            ]
          : [false, false, false, false, false],
      isReadOnly: widget.isReadOnly,
      isFullAccessOnly: isFullAccessOnly,
      onToggleChanged: widget.isReadOnly
          ? null
          : (index, newValue) {
              final featureName = permission.featureName ?? 'Unknown Feature';
              // Use overrideModuleName if provided (from parent module), otherwise use permission.moduleName
              final finalModuleName =
                  overrideModuleName ?? permission.moduleName;
              widget.onPermissionChanged?.call(
                featureName,
                finalModuleName,
                index,
                newValue,
              );
            },
    );
  }
}
