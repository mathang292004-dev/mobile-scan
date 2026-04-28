import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/user_onboarding/model/user_management_model.dart';

class UserListCardWidget extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const UserListCardWidget({
    super.key,
    required this.user,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorHelper.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Status Badge + Delete
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: ColorHelper.userCardTitle,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(context),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ColorHelper.surfaceColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      Assets.reportIncidentRecycleBin,
                      width: 16,
                      height: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Info rows
            _buildInfoRow(
              context,
              Assets.emailIcon,
              Icons.email_outlined,
              user.email,
            ),
            const SizedBox(height: 8),
           
            if (user.roles.isNotEmpty) ...[
              _buildInfoRow(
                context,
                Assets.roleIcon,
                Icons.people_outline,
                user.roles.join(', '),
              ),
              const SizedBox(height: 8),
            ],
            if (user.projects.isNotEmpty)
              _buildInfoRow(
                context,
                Assets.projectIcon,
                Icons.folder_outlined,
                user.projects.join(', '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isActive = user.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? ColorHelper.activeBadgeBg
            : ColorHelper.inactiveBadgeBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: isActive
              ? ColorHelper.activeBadgeBorder
              : ColorHelper.inactiveBadgeBorder,
        ),
      ),
      child: Text(
        isActive ? TextHelper.active : TextHelper.inactive,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isActive
              ? ColorHelper.activeBadgeText
              : ColorHelper.inactiveBadgeText,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String assetPath,
    IconData fallbackIcon,
    String text,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: Image.asset(
            assetPath,
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) => Icon(
              fallbackIcon,
              size: 16,
              color: ColorHelper.userInfoText,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColorHelper.userInfoText,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
