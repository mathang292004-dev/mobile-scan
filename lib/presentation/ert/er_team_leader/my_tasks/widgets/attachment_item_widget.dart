import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable widget for displaying attachment items (Reporter attachments)
class AttachmentItemWidget extends StatelessWidget {
  final String fileName;
  final IconData? icon;
  final String? fileUrl;
  final VoidCallback? onTap;

  const AttachmentItemWidget({
    super.key,
    required this.fileName,
    this.icon,
    this.fileUrl,
    this.onTap,
  });

  Future<void> _openUrl() async {
    final url = fileUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? _openUrl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null)
              Image.asset(
                Assets.jpgImage,
                width: 24,
                height: 24,
              )
            else
              Image.asset(Assets.defaultPic, width: 24, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF0B0B0B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fileUrl != null && fileUrl!.isNotEmpty)
              const Icon(
                Icons.open_in_new,
                size: 14,
                color: Color(0xFF6D6D6D),
              ),
          ],
        ),
      ),
    );
  }
}
