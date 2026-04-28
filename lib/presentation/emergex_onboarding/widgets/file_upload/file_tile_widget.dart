import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

/// File Tile Widget
class FileTileWidget extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final String fileUrl;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const FileTileWidget({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.fileUrl,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Image.asset(Assets.defaultPic, width: 24, height: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: ColorHelper.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileSize,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: ColorHelper.textColorDefault,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                showErrorDialog(
                  context,
                  () {
                    onRemove();
                    back();
                  },
                  () {
                    back();
                    // Do nothing
                  },
                  TextHelper.areYouSure,
                  TextHelper.areYouSureYouWantToDeleteThisFileFromCategory,
                  TextHelper.yes,
                  TextHelper.no,
                );
              },
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorHelper.closeIconColor,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: ColorHelper.closeIconColor,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
