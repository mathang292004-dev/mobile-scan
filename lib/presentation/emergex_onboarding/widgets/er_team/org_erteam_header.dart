import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/permission_helper.dart';

class OrganizationHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAddPressed;
  final String? roleId;
  final VoidCallback? onBackPressed;

  /// When true, shows the edit action button regardless of title.
  /// Used by Role Detail screen to enable consistent edit access.
  final bool showEditAction;

  const OrganizationHeader({
    super.key,
    required this.title,
    this.onAddPressed,
    this.onBackPressed,
    this.roleId,
    this.showEditAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 14,left: 14, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    back();
                  }
                },

                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorHelper.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ColorHelper.textLight, width: 1),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_left,
                    size: 24,
                    color: ColorHelper.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.organizationStructure,
                ),
              ),
            ],
          ),
          if (showEditAction || title == TextHelper.erteammember)
            if (PermissionHelper.hasEditPermission(
                  moduleName: "Client Admin",
                  featureName: "Role Management",
                ) ||
                PermissionHelper.hasEditPermission(
                  moduleName: "Client Admin",
                  featureName: "User Management",
                ))
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  openScreen(
                    Routes.organizationeditscreen,
                    args: {"roleId": roleId},
                    shouldReplace: showEditAction,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorHelper.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Image.asset(
                      Assets.reportApEdit,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          // Show edit button only if user has edit permission
        ],
      ),
    );
  }
}
