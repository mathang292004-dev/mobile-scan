import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/widgets/inputs/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/generated/assets.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;

  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Controls whether to show the notification bell icon (default: true - always visible)
  final bool showNotificationIcon;

  /// Controls whether to show the unread badge on notification icon
  /// When true, shows a red dot badge on the bell icon
  final bool hasUnreadNotifications;
  final bool showBottomBackButton;
  final bool showAppBarButton;
  final String? bottomTitle;
  final VoidCallback? onPressed;
  final bool isRecording;
  final bool? showDropdown;
  final List<String>? dropdownItems;
  final ValueChanged<String>? onDropdownChanged;
  final String? dropdownInitialValue;
  final bool? withoutMenu;

  /// Flag to show active (green) state when on notifications screen
  final bool isOnNotificationsScreen;

  /// Show eye icon on the right side of the bottom title row
  final bool showEyeIcon;
  final VoidCallback? onEyeIconPressed;

  /// Suffix appended to the bottomTitle (e.g. "– Approval Panel")
  final String? bottomTitleSuffix;

  /// Show dropdown as full-width row below the title row
  final bool fullWidthDropdown;
  final GlobalKey? eyeIconKey;

  const AppBarWidget({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor = ColorHelper.primaryBackground,
    this.foregroundColor,
    this.showNotificationIcon = true,
    this.hasUnreadNotifications = false,
    // Backward compatibility: hasNotifications now controls the badge (same as hasUnreadNotifications)
    bool hasNotifications = false,
    this.showBottomBackButton = false,
    this.bottomTitle,
    this.onPressed,
    this.isRecording = false,
    this.showDropdown,
    this.dropdownItems,
    this.onDropdownChanged,
    this.showAppBarButton = false,
    this.dropdownInitialValue,
    this.withoutMenu = true,
    this.isOnNotificationsScreen = false,
    this.showEyeIcon = false,
    this.onEyeIconPressed,
    this.bottomTitleSuffix,
    this.fullWidthDropdown = false,
    this.eyeIconKey,
  }) : _legacyHasNotifications = hasNotifications;

  // Store the legacy parameter for backward compatibility
  final bool _legacyHasNotifications;

  @override
  Size get preferredSize {
    double extra = 0;
    if (showBottomBackButton) extra += 60.0;
    if (fullWidthDropdown && showDropdown == true) extra += 48.0;
    return Size.fromHeight(kToolbarHeight + extra);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor ?? ColorHelper.textLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: showBackButton,
          leading: showBackButton
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isRecording
                        ? (foregroundColor ?? ColorHelper.textLight).withValues(
                            alpha: 0.3,
                          )
                        : foregroundColor ?? ColorHelper.textLight,
                  ),
                  onPressed: isRecording ? null : (onBackPressed ?? () {}),
                )
              : null,
          title: Row(
            children: [Image.asset(Assets.applogo, height: 32, width: 120)],
          ),
          actions: _buildDefaultActions(context),
        ),
        if (showBottomBackButton) _buildBottomBackButton(context),
      ],
    );
  }

  Widget _buildBottomBackButton(BuildContext context) {
    final displayTitle = bottomTitleSuffix != null && bottomTitle != null
        ? '$bottomTitle $bottomTitleSuffix'
        : bottomTitle ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row: back arrow | title | eye icon (or inline dropdown)
          Row(
            children: [
              GestureDetector(
                onTap: isRecording ? null : onPressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRecording
                        ? ColorHelper.white.withValues(alpha: 0.1)
                        : ColorHelper.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRecording
                          ? ColorHelper.textLight.withValues(alpha: 0.3)
                          : ColorHelper.textLight,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_left,
                    size: 24,
                    color: isRecording
                        ? ColorHelper.textSecondary.withValues(alpha: 0.3)
                        : ColorHelper.textSecondary,
                  ),
                ),
              ),
              if (displayTitle.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ColorHelper.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // Inline dropdown (old layout)
              if (!fullWidthDropdown &&
                  showDropdown == true &&
                  dropdownItems != null) ...[
                const SizedBox(width: 12),
                CustomDropdown(
                  items: dropdownItems ?? [],
                  initialValue:
                      dropdownInitialValue ?? dropdownItems?.first ?? '',
                  onChanged: onDropdownChanged ?? (value) {},
                ),
              ],
              // Eye icon
              if (showEyeIcon) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  key: eyeIconKey,
                  onTap: onEyeIconPressed,
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      color: ColorHelper.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorHelper.red,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        Assets.eyeIcon,
                        width: 14,
                        height: 14,
                        color: ColorHelper.black,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Full-width dropdown row (new layout)
          if (fullWidthDropdown &&
              showDropdown == true &&
              dropdownItems != null) ...[
            const SizedBox(height: 6),
            _buildFullWidthDropdown(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFullWidthDropdown(BuildContext context) {
    return CustomDropdown(
      items: dropdownItems ?? [],
      initialValue: dropdownInitialValue ?? dropdownItems?.first ?? '',
      onChanged: onDropdownChanged ?? (value) {},
      isFullWidth: true,
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    return [
      _buildNotificationIcon(),
      withoutMenu! ? _buildMenuToggleButton(context) : Container(),
    ];
  }

  Widget _buildMenuToggleButton(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 16, left: 5),
      decoration: BoxDecoration(
        color: isRecording
            ? ColorHelper.primaryBackground.withValues(alpha: 0.2)
            : ColorHelper.primaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecording
              ? ColorHelper.textLight.withValues(alpha: 0.3)
              : ColorHelper.textLight,
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: isRecording ? null : () => _showFullScreenOverlay(context),
        icon: Image.asset(
          Assets.appbarIconMenu,
          width: 20,
          height: 20,
          color: ColorHelper.iconPrimary,
        ),
      ),
    );
  }

  void _showFullScreenOverlay(BuildContext context) {
    // Unfocus any active text fields before opening drawer
    // Use primaryFocus?.unfocus() to ensure complete focus removal
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null && currentFocus.hasFocus) {
      currentFocus.unfocus();
    }

    // Open drawer after ensuring focus is cleared
    // Using addPostFrameCallback to ensure focus clearing completes before drawer opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Scaffold.of(context).openEndDrawer();
      }
    });
  }

  Widget _buildNotificationIcon() {
    // Always show the notification icon if showNotificationIcon is true
    if (!showNotificationIcon) return const SizedBox.shrink();

    // Use either hasUnreadNotifications or legacy hasNotifications for badge
    final showBadge = hasUnreadNotifications || _legacyHasNotifications;

    return _buildAppBarIcon(
      imageUrl: Assets.appbarIconNotification,
      isActive: isOnNotificationsScreen,
      onPressed: (isRecording || isOnNotificationsScreen)
          ? null
          : () => openScreen(Routes.notificationsScreen),
      // Only show badge when there are unread notifications and not on notifications screen
      badge: showBadge && !isOnNotificationsScreen
          ? _buildNotificationBadge()
          : null,
    );
  }

  Widget _buildAppBarIcon({
    required String imageUrl,
    VoidCallback? onPressed,
    Widget? badge,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: isActive
            ? const Color(0xFF3DA229)
            : ColorHelper.assetDamageCardColor.withValues(alpha: 0.3),

        border: Border.all(
          color: isActive
              ? Colors.white
              : (isRecording
                    ? ColorHelper.textLight.withValues(alpha: 0.3)
                    : ColorHelper.textLight),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: Image.asset(
              imageUrl,
              width: 20,
              height: 20,

              color: isActive ? Colors.white : ColorHelper.iconPrimary,
            ),
            onPressed: onPressed,
          ),

          if (badge != null) badge,
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Positioned(
      top: 9,
      right: 10,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: ColorHelper.notificationBadge,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
