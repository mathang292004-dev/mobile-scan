import 'dart:ui';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/client/client_dialog_box.dart';
import 'package:emergex/data/model/client_management/client_response.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/client/client_action_buttons.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/client/label_value_widget.dart';
import 'package:emergex/utils/date_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClientCardWidget extends StatelessWidget {
  final Client client;

  const ClientCardWidget({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final logo = client.profileData?.fileUrl ?? Assets.staticLogo;
    final name = client.clientName ?? "Unknown Client";
    final code = client.clientId ?? "—";
    final industry = client.industry ?? "N/A";
    final location = client.location ?? "N/A";
    final projects = client.projectCount ?? 0;
    final lastInteraction = client.createdAt != null
        ? AppDateUtils.formatDate(client.createdAt!)
        : "N/A";
    final rawStatus = client.status ?? "Inactive";
    final status = rawStatus.isNotEmpty
        ? '${rawStatus[0].toUpperCase()}${rawStatus.substring(1).toLowerCase()}'
        : rawStatus;
    final bool isActive = rawStatus.toLowerCase() == "active";
    final bool isAchieved = rawStatus.toLowerCase() == "archived";

    return Container(
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: ColorHelper.surfaceColor.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: logo.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: logo,
                                    // Stable cache key based on client ID prevents re-fetching
                                    cacheKey:
                                        'client_logo_${client.id ?? client.clientId}',
                                    width: 75,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    // Memory cache dimensions for efficient scrolling
                                    memCacheWidth:
                                        150, // 2x for retina displays
                                    memCacheHeight: 100,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    // Use useOldImageOnUrlChange to prevent flicker during rebuilds
                                    useOldImageOnUrlChange: true,
                                    placeholder: (context, url) => Image.asset(
                                      Assets.staticLogo,
                                      width: 75,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                          Assets.staticLogo,
                                          width: 75,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                  )
                                : Image.asset(
                                    logo,
                                    width: 75,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              Assets.staticLogo,
                                              width: 75,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: ColorHelper.titleMemberColor,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  code,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 12,
                                        color: ColorHelper.textQuaternary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isActive
                                    ? ColorHelper.primaryColor.withValues(
                                        alpha: 0.1,
                                      )
                                    :!isAchieved? ColorHelper.recycleBin.withValues(
                                        alpha: 0.1,
                                      ): ColorHelper.erteamleaderprogress.withValues(
                                        alpha: 0.1,
                                      )),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isActive
                                    ? ColorHelper.primaryColor.withValues(
                                        alpha: 0.2,
                                      )
                                    : !isAchieved
                                    ? ColorHelper.recycleBin.withValues(
                                        alpha: 0.2,
                                      )
                                    : ColorHelper.erteamleaderprogress.withValues(
                                        alpha: 0.2,
                                      )),
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? ColorHelper.primaryColor
                                    : !isAchieved
                                    ? ColorHelper.recycleBin
                                    : ColorHelper.erteamleaderprogress,

                                border: Border.all(
                                  color: (isActive
                                      ? ColorHelper.primaryColor
                                      : isAchieved
                                      ? ColorHelper.erteamleaderprogress
                                      : ColorHelper.recycleBin),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isActive
                                    ? ColorHelper.primaryDark
                                    : isAchieved
                                    ? ColorHelper.erteamleaderprogress
                                    : ColorHelper.errorColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: maxWidth * 0.45,
                      child: LabelValueWidget(
                        label: "Industry:",
                        value: industry,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        valueStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: maxWidth * 0.45,
                      child: LabelValueWidget(
                        label: "Last Interaction:",
                        value: lastInteraction,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        valueStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: maxWidth * 0.45,
                      child: LabelValueWidget(
                        label: "Location:",
                        value: location,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        valueStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: maxWidth * 0.45,
                      child: LabelValueWidget(
                        label: "Projects:",
                        value: "$projects",
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        valueStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment:
                      !isAchieved &&
                      PermissionHelper.hasDeletePermission(
                        moduleName: "EmergeX Client Onboarding",
                        featureName: "Onboard EmergeX Customers",
                      )
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                  children: [
                    if (!isAchieved &&
                        PermissionHelper.hasDeletePermission(
                          moduleName: "EmergeX Client Onboarding",
                          featureName: "Onboard EmergeX Customers",
                        ))
                      GestureDetector(
                        onTap: () {
                          // Delete client functionality
                          final cubit = AppDI.clientCubit;
                          if (client.id != null) {
                            showErrorDialog(
                              context,
                              () {
                                back();
                                cubit.deleteClient(client.clientId!);
                              },
                              () {
                                back();
                              },
                              TextHelper.areYouSure,
                              ' ${client.clientName} ${TextHelper.areYouSureYouWantToDeleteThisClient}',
                              TextHelper.delete,
                              TextHelper.cancel,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorHelper.white.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Image.asset(
                              Assets.reportIncidentRecycleBin,
                              width: 16,
                              height: 16,
                              color: ColorHelper.red,
                            ),
                          ),
                        ),
                      ),
                    ClientActionButtons(
                      primaryText: TextHelper.edit,
                      secondaryText: TextHelper.viewProjects,
                      showPrimaryButton: !isAchieved &&
                          PermissionHelper.hasEditPermission(
                            moduleName: "EmergeX Client Onboarding",
                            featureName: "Onboard EmergeX Customers",
                          ),
                      showSecondaryButton: !isAchieved &&
                          PermissionHelper.hasViewPermission(
                            moduleName: "EmergeX Client Onboarding",
                            featureName: "Projects",
                          ),
                      onPrimaryPressed:
                          PermissionHelper.hasEditPermission(
                            moduleName: "EmergeX Client Onboarding",
                            featureName: "Onboard EmergeX Customers",
                          )
                          ? () => showDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierColor: ColorHelper.black.withValues(
                                alpha: 0.3,
                              ),
                              builder: (context) {
                                return BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: ClientSearchDialog(
                                    clientName: client.clientName,
                                    clientId: client.clientId,
                                    email: client.email,
                                    industry: client.industry,
                                    location: client.location,
                                    profileUrl: client.profileData?.fileUrl,
                                    status: client.status,
                                  ),
                                );
                              },
                            )
                          : null,
                      onSecondaryPressed:
                          PermissionHelper.hasViewPermission(
                            moduleName: "EmergeX Client Onboarding",
                            featureName: "Projects",
                          )
                          ? () {
                              AppDI.projectCubit.getProjects(
                                clientId: client.clientId!,
                              );
                              loaderService.showLoader();
                              Future.delayed(const Duration(seconds: 1), () {
                                openScreen(
                                  Routes.viewprojectscreen,
                                  args: {
                                    'clientId': client.clientId,
                                    'clientName': client.clientName,
                                    'imageUrl': client.profileData?.fileUrl,
                                  },
                                );
                                loaderService.hideLoader();
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
