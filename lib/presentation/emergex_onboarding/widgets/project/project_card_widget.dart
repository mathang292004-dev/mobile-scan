import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/widgets/feedback/app_dialog_widget.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/client/client_action_buttons.dart';
import 'project_dialog_box.dart';

class ProjectCardWidget extends StatelessWidget {
  final Map<String, dynamic> project;
  final bool apexscreen;
  final bool? isClient;

  const ProjectCardWidget({
    super.key,
    required this.project,
    this.apexscreen = false,
    this.isClient = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = project["Title"] ?? "Untitled Project";
    final code = project["code"] ?? "N/A";
    final workSites = project["work sites"] ?? "Unknown";
    final location = project["location"] ?? "Unknown";
    final employees = project["Employees"]?.toString() ?? "0";
    final createdDate = project["CreatedDate"] ?? "N/A";
    final status = project["status"] ?? "Inactive";
    final isActive = status == "Active";
    final uploadedStatus = project["uploadedStatus"] ?? '';
    final description = project["description"] ?? "UnKnown";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE + EDIT
            Row(
              children: [
                Expanded( 
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (PermissionHelper.hasEditPermission(
                  moduleName: isClient == false
                      ? "EmergeX Client Onboarding"
                      : "Client Admin",
                  featureName: "Projects",
                ))
                  GestureDetector(
                    onTap: () async {
                      await ProjectDialogBox.show(
                        context,
                        title: project["Title"],
                        code: project["code"],
                        workSite: project["work sites"],
                        location: project["location"],
                        employees: project["Employees"].toString(),
                        createdDate: project["CreatedDate"],
                        status: project["status"],
                        description: project["description"],
                        permissions:
                            PermissionHelper.getAllFeaturePermissions(),
                      );
                    },
                    child: Image.asset(
                      Assets.reportApEdit,
                      width: 24,
                      height: 24,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            /// PROJECT CODE
            Text(
              code,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorHelper.black.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            /// STATUS + DONE
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        _statusCircle(24, isActive, 0.1),
                        _statusCircle(16, isActive, 0.2),
                        _statusCircle(10, isActive, 1),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isActive
                            ? ColorHelper.primaryDark
                            : ColorHelper.errorColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: uploadedStatus == 'Done'
                        ? ColorHelper.doneColor.withValues(alpha: 0.4)
                        : ColorHelper.draftColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    uploadedStatus,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: uploadedStatus == 'Done'
                          ? ColorHelper.primaryColor
                          : ColorHelper.draftColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// DESCRIPTION
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: ColorHelper.black.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: 14),

            /// LOCATION, WORK SITES, EMPLOYEES & CREATED DATE GRID
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorHelper.black,
                        ),
                      ),
                      Text(
                        location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.black.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work Sites:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorHelper.black,
                        ),
                      ),
                      Text(
                        workSites,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.black.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employees:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorHelper.black,
                        ),
                      ),
                      Text(
                        employees,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.black.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created Date:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorHelper.black,
                        ),
                      ),
                      Text(
                        createdDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.black.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// BOTTOM ACTIONS
            Row(
              mainAxisAlignment:
                  PermissionHelper.hasDeletePermission(
                    moduleName: isClient == false
                        ? "EmergeX Client Onboarding"
                        : "Client Admin",
                    featureName: "Projects",
                  )
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (PermissionHelper.hasDeletePermission(
                  moduleName: isClient == false
                      ? "EmergeX Client Onboarding"
                      : "Client Admin",
                  featureName: "Projects",
                ))
                  GestureDetector(
                    onTap: () {
                      CustomDialog.showError(
                        context: context,
                        title: TextHelper.areYouSure,
                        subtitle: Text(
                          TextHelper.projectError,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        primaryButtonText: TextHelper.delete,
                        secondaryButtonText: TextHelper.cancel,
                        onPrimaryPressed: () {
                          back();
                          AppDI.projectCubit.deleteProject(code);
                        },
                        onSecondaryPressed: () => back(),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorHelper.recycleBin.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Image.asset(
                          Assets.reportIncidentRecycleBin,
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                  ),
                ClientActionButtons(
                  primaryText: uploadedStatus != 'Draft'
                      ? TextHelper.amendDoc
                      : TextHelper.reupload,
                  secondaryText: TextHelper.viewOrgstructure,
                  showPrimaryButton: PermissionHelper.hasFullAccessPermission(
                    moduleName: isClient == false
                        ? "EmergeX Client Onboarding"
                        : "Client Admin",
                    featureName: "Upload Files (Amend Features)",
                  ),
                  showSecondaryButton: PermissionHelper.hasViewPermission(
                    moduleName: "Client Admin",
                    featureName: "Role Management",
                  ),
                  onPrimaryPressed: () {
                    final cubit = AppDI.onboardingOrganizationStructureCubit;
                    final isAmend = uploadedStatus != 'Draft';
                    cubit.setAmendDoc(isAmend);
                    cubit.viewDetails(code, 'docs');
                    loaderService.showLoader();
                    Future.delayed(const Duration(seconds: 1), () {
                      cubit.fetchRoles(code);
                      openScreen(Routes.uploadDocumentsScreen);
                      loaderService.hideLoader();
                    });
                  },
                  onSecondaryPressed: () {
                    // Set navigation source based on flow:
                    // isClient=true → Drawer flow → back to projectListScreen
                    // isClient=false → Client flow → back to viewProjectScreen
                    final source = isClient == true
                        ? 'projectListScreen'
                        : 'viewProjectScreen';
                    AppDI.onboardingOrganizationStructureCubit
                        .setNavigationSource(source);
                    AppDI.onboardingOrganizationStructureCubit.fetchRoles(code);
                    openScreen(Routes.rolesScreen);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCircle(double size, bool active, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? ColorHelper.primaryColor.withValues(alpha: opacity)
            : ColorHelper.recycleBin.withValues(alpha: opacity),
        border: size == 10
            ? Border.all(
                color: active
                    ? ColorHelper.primaryColor
                    : ColorHelper.recycleBin,
                width: 1.5,
              )
            : null,
      ),
    );
  }
}
