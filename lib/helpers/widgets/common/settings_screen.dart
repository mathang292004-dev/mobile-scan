import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/toggle_button.dart';
import 'package:flutter/material.dart';

class CommonSettingsScreen extends StatefulWidget {
  const CommonSettingsScreen({super.key});

  @override
  State<CommonSettingsScreen> createState() => _CommonSettingsScreenState();
}

class _CommonSettingsScreenState extends State<CommonSettingsScreen> {
  bool pushNotifications = true;
  bool emailAlerts = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      showDrawer: false,
      appBar: AppBarWidget(
        bottomTitle: TextHelper.settings,
        showBottomBackButton: true,
        hasNotifications: true,
        onPressed: () => back(),
      ),
      showBottomNav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Column(
          children: [
            // Profile & Contact Section
            _buildOuterCard(
              child: Column(
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: 12),
                  _buildContactInfo(context),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification Settings Section
            _buildOuterCard(
              title: TextHelper.notificationSettings,
              child: Column(
                children: [
                  _buildToggleItem(
                    context,
                    title: TextHelper.pushNotifications,
                    value: pushNotifications,
                    onChanged: (v) => setState(() => pushNotifications = v),
                  ),
                  const SizedBox(height: 12),
                  _buildToggleItem(
                    context,
                    title: TextHelper.emailAlerts,
                    value: emailAlerts,
                    onChanged: (v) => setState(() => emailAlerts = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Options Section
            _buildSettingsNavItem(
              context,
              title: TextHelper.userManagementLabel,
              onTap: () => openScreen(Routes.userManagementScreen, clearOldStacks: true),
            ),
            const SizedBox(height: 12),
            _buildSettingsNavItem(
              context,
              title: TextHelper.resetPasswordLabel,
              onTap: () => openScreen(Routes.resetPasswordAuth),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOuterCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(
          alpha: 0.4,
        ), // Semi-transparent green tint to match background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: ColorHelper.grey4,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorHelper.activeBadgeBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorHelper.primaryColor.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.person, color: ColorHelper.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  TextHelper.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  TextHelper.teamLeaderLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF1F2937).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D8A1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Image.asset(
            Assets.reportApEdit,
            width: 14,
            height: 14,
            color: ColorHelper.white,
          ),
          const SizedBox(width: 6),
          Text(
            TextHelper.edit,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TextHelper.emailLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D8A1E),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Michaelbrown@gmail.com',
            style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
          ),
          SizedBox(height: 16),
          Text(
            TextHelper.contactLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D8A1E),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '9562452220',
            style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
          ToggleButton(
            handleToggle: onChanged,
            checked: value,
            size: 40,
            innerCircleColor: ColorHelper.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsNavItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFE9F1E8).withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
