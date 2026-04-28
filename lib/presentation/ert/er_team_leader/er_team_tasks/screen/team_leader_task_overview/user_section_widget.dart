import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class UserSectionWidget extends StatelessWidget {
  final String userName;
  final String userId;
  final String progressText;
  final double progressValue;

  const UserSectionWidget({
    super.key,
    required this.userName,
    required this.userId,
    required this.progressText,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _UserInfoContainer(userName: userName, userId: userId),
        const SizedBox(height: 12),
        _TaskProgressContainer(
          progressText: progressText,
          progressValue: progressValue,
        ),
      ],
    );
  }
}

class _UserInfoContainer extends StatelessWidget {
  final String userName;
  final String userId;

  const _UserInfoContainer({required this.userName, required this.userId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final nameParts = userName.split(' ');
    final displayName = nameParts.length > 1
        ? '${nameParts.first} ${nameParts.last}'
        : userName;

    final displayUserId = userId.length > 6
        ? 'ER${userId.substring(userId.length - 6).toUpperCase()}'
        : 'ER${userId.toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),

          const SizedBox(width: 12),

          // Name + ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayUserId,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: ColorHelper.black4,
                  ),
                ),
              ],
            ),
          ),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: ColorHelper.successColor, width: 1),
              borderRadius: BorderRadius.circular(20),
              color: ColorHelper.white.withValues(alpha: 0.1),
            ),
            child: Text(
              'Investigation Officer',
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                color: ColorHelper.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskProgressContainer extends StatelessWidget {
  final String progressText;
  final double progressValue;

  const _TaskProgressContainer({
    required this.progressText,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Progress',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.taskProgresscolor,
                ),
              ),
              Text(
                progressText,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ColorHelper.taskProgresscolor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey.shade400,
              color: ColorHelper.green,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
