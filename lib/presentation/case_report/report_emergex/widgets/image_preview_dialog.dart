import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:flutter/material.dart';

class ImagePreviewDialog extends StatefulWidget {
  final List<FileUploadItem> images;
  final int initialIndex;
  final Function(String?) onDelete;

  const ImagePreviewDialog({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleDelete() {
    final currentImage = widget.images[_currentIndex];

    // Close the dialog first
    back();

    // Then call the delete callback
    widget.onDelete(currentImage.key);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorHelper.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ColorHelper.white, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title, delete and close buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Image Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorHelper.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    // Delete button
                    GestureDetector(
                      onTap: _handleDelete,
                      child: Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Image.asset(Assets.reportIncidentRecycleBin),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Close button
                    GestureDetector(
                      onTap: () => back(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Icon(
                          Icons.cancel_outlined,
                          color: ColorHelper.primaryDark,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image preview container with navigation
            Container(
              padding: const EdgeInsets.all(11.2),
              decoration: BoxDecoration(
                color: const Color(0xFFE5EFE3).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColorHelper.white, width: 0.8),
              ),
              child: Column(
                children: [
                  // Image filename
                  Text(
                    widget.images[_currentIndex].fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B4848),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Image with navigation arrows
                  SizedBox(
                    height: 320,
                    child: Stack(
                      children: [
                        // PageView for images
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: widget.images.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                widget.images[index].fileUrl ?? '',
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: ColorHelper.grey.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              ColorHelper.primaryColor,
                                            ),
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: ColorHelper.grey.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),

                        // Left arrow (Previous)
                        if (_currentIndex > 0)
                          Positioned(
                            left: 11,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _navigateToPrevious,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: ColorHelper.white.withValues(
                                      alpha: 0.9,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left,
                                    color: Color(0xFF232323),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Right arrow (Next)
                        if (_currentIndex < widget.images.length - 1)
                          Positioned(
                            right: 11,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _navigateToNext,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: ColorHelper.white.withValues(
                                      alpha: 0.9,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF232323),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Page indicator (if multiple images)
            // if (widget.images.length > 1) ...[
            //   const SizedBox(height: 12),
            //   Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: List.generate(
            //       widget.images.length,
            //       (index) => Container(
            //         margin: const EdgeInsets.symmetric(horizontal: 4),
            //         width: 8,
            //         height: 8,
            //         decoration: BoxDecoration(
            //           shape: BoxShape.circle,
            //           color: _currentIndex == index
            //               ? ColorHelper.primaryColor
            //               : ColorHelper.grey.withValues(alpha: 0.3),
            //         ),
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
