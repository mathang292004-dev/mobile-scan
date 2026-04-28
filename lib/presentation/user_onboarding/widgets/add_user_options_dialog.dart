import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';

class AddUserOptionsDialog extends StatelessWidget {
  final VoidCallback onAddSingleUser;
  final VoidCallback onUploadMultiUser;

  const AddUserOptionsDialog({
    super.key,
    required this.onAddSingleUser,
    required this.onUploadMultiUser,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorHelper.white),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TextHelper.addUserOptions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorHelper.black4,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.cancel_outlined,
                    size: 24,
                    color: ColorHelper.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Add Single User Card
            _buildOptionCard(
              context,
              iconAsset: Assets.addSingleUserIcon,
              fallbackIcon: Icons.person_add_outlined,
              title: TextHelper.addSingleUserManually,
              description: TextHelper.addSingleUserDescription,
              buttonText: TextHelper.addUser,
              onPressed: () {
                Navigator.pop(context);
                onAddSingleUser();
              },
            ),

            const SizedBox(height: 18),

            // Upload Multi User Card
            _buildOptionCard(
              context,
              iconAsset: Assets.addMultiUserIcon,
              fallbackIcon: Icons.folder,
              title: TextHelper.uploadMultiUser,
              description: TextHelper.uploadMultiUserDescription,
              buttonText: TextHelper.uploadFile,
              onPressed: () {
                Navigator.pop(context);
                onUploadMultiUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String iconAsset,
    required IconData fallbackIcon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorHelper.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Column(
        children: [
          // Icon
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorHelper.primaryLight5,
                  ),
                ),
                // Middle circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorHelper.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                // Inner white circle with icon
                Center(
                  child: Image.asset(
                    iconAsset,
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      fallbackIcon,
                      size: 60,
                      color: ColorHelper.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ColorHelper.userCardTitle,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColorHelper.userSubText,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Button
          EmergexButton(
            onPressed: onPressed,
            text: buttonText,
            textSize: 14,
            fontWeight: FontWeight.w600,
            borderRadius: 24,
            buttonHeight: 48,
          ),
        ],
      ),
    );
  }
}
