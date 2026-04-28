import 'package:emergex/generated/assets.dart';
import 'package:emergex/di/app_di.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/client/client_dialog_box.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/project/project_dialog_box.dart';
import 'package:emergex/presentation/emergex_onboarding/utils/client_utils.dart';

class ClientSearchHeader extends StatelessWidget {
  final GlobalKey<SearchBarWidgetState> searchBarKey;
  final bool isApex;
  final bool clientSection;
  final bool projectSection;
  final bool? isClient;
  final String? hintText;

  const ClientSearchHeader({
    super.key,
    required this.searchBarKey,
    this.isApex = false,
    this.clientSection = false,
    this.projectSection = false,
    this.isClient = false,
    this.hintText,
  });
  String get _hintText {
    // If custom hintText is provided, use it
    if (hintText != null && hintText!.isNotEmpty) {
      return hintText!;
    }
    // Otherwise, determine based on section flags
    if (projectSection) return TextHelper.searchProjects; // ✅ Project
    if (clientSection) return TextHelper.searchClients; // ✅ Client
    return 'Search'; // fallback
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: SearchBarWidget(
              key: searchBarKey,
              hintText: _hintText,
              textStyle: const TextStyle(
                color: ColorHelper.searchInputTextColor,
              ),

              prefixIcon: Icons.search_rounded,
              prefixIconSize: 16,
              prefixIconColor: ColorHelper.searchInputTextColor,
              suffixIconWidget: Transform.scale(
                scale: 0.4,
                child: Image.asset(Assets.funnelIcon, height: 3, width: 30),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: ColorHelper.surfaceColor,
                  width: 1,
                ),
              ),
              clientSection: clientSection,
              projectSection: projectSection,
              onChanged: (value) {
                if (clientSection) {
                  ClientUtils.applySearch(value);
                } else if (projectSection) {
                  ClientUtils.applyProjectSearch(value);
                }
              },
            ),
          ),

          const SizedBox(width: 12),

          // Show create button only if user has create permission
          // For project: Check "Client" module, "Projects" feature
          // For client: Check "EmergeX Client Onboarding" module, "EmergeX Client" feature
          if (isApex &&
              PermissionHelper.hasCreatePermission(
                moduleName: isClient == false
                    ? "EmergeX Client Onboarding"
                    : "Client Admin",
                featureName: "Projects",
              ))
            ElevatedButton.icon(
              onPressed: () {
                // Set navigation source based on context:
                // isClient=false (Client Flow) → viewProjectScreen
                // isClient=true (Global/Drawer Flow) → projectListScreen
                final source = isClient == false
                    ? 'viewProjectScreen'
                    : 'projectListScreen';
                AppDI.onboardingOrganizationStructureCubit.setNavigationSource(
                  source,
                );

                ProjectDialogBox.show(
                  context,
                  permissions: PermissionHelper.getAllFeaturePermissions(),
                );
              },
              icon: const Icon(
                Icons.add,
                color: ColorHelper.primaryColor,
                size: 20,
              ),
              label: Text(
                TextHelper.newproject,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.primaryColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorHelper.newClient.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: ColorHelper.addMemberColor, width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          if (!isApex &&
              PermissionHelper.hasCreatePermission(
                moduleName: "EmergeX Client Onboarding",
                featureName: "Onboard EmergeX Customers",
              ))
            ElevatedButton.icon(
              onPressed: () {
                ClientSearchDialog.show(context);
              },
              icon: const Icon(
                Icons.add,
                color: ColorHelper.primaryColor,
                size: 16,
              ),
              label: Text(
                TextHelper.newClient,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.primaryColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorHelper.newClient.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: ColorHelper.addMemberColor,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
