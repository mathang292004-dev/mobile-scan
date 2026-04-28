import 'package:emergex/di/app_di.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import '../../../../../data/model/incident/incident_detail.dart';

class UploadedFilesSection extends StatefulWidget {
  final UploadedFiles uploadedFiles;
  final String status;
  final bool isEditRequired;
  final String? incidentStatus;
  final bool enableAnimation;

  const UploadedFilesSection({
    super.key,
    required this.uploadedFiles,
    this.status = "Verified",
    this.isEditRequired = false,
    this.incidentStatus,
    this.enableAnimation = false,
  });

  @override
  State<UploadedFilesSection> createState() => _UploadedFilesSectionState();
}

class _UploadedFilesSectionState extends State<UploadedFilesSection>
    with TickerProviderStateMixin {
  late final ValueNotifier<bool> _isExpandedNotifier;
  final ValueNotifier<bool> _isEditingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpandedNotifier = ValueNotifier<bool>(widget.enableAnimation);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.enableAnimation ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _isExpandedNotifier.dispose();
    _isEditingNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    _isExpandedNotifier.value = !_isExpandedNotifier.value;
    _isExpandedNotifier.value
        ? _animationController.forward()
        : _animationController.reverse();
  }

  Future<void> _handleFileUpload() async {
    if (_isLoadingNotifier.value) return;

    final incidentDetailsCubit = AppDI.incidentDetailsCubit;
    if (incidentDetailsCubit.state is! IncidentDetailsLoaded) return;

    final currentIncident =
        (incidentDetailsCubit.state as IncidentDetailsLoaded).incident;
    if (currentIncident.incidentId == null) return;

    _isLoadingNotifier.value = true;

    try {
      await AppDI.incidentFileHandleCubit.pickAndUploadFilesForExistingIncident(
        currentIncident.incidentId!,
      );

      if (context.mounted) {
        await AppDI.incidentDetailsCubit.getIncidentById(
          currentIncident.incidentId!,
        );
      }
    } finally {
      if (context.mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _handleFileDelete(String infoId, String fileType) async {
    if (_isLoadingNotifier.value) return;

    _isLoadingNotifier.value = true;

    try {
      await AppDI.incidentFileHandleCubit.deleteFileFromServer(
        infoId,
        fileType,
        false,
      );

      final incidentDetailsCubit = AppDI.incidentDetailsCubit;
      if (incidentDetailsCubit.state is IncidentDetailsLoaded) {
        final currentIncident =
            (incidentDetailsCubit.state as IncidentDetailsLoaded).incident;
        if (currentIncident.incidentId != null && context.mounted) {
          await AppDI.incidentDetailsCubit.getIncidentById(
            currentIncident.incidentId!,
          );
        }
      }
    } finally {
      if (context.mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.incidentStatus?.toLowerCase() == 'pending review';

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        return Stack(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: ColorHelper.surfaceColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: ColorHelper.surfaceColor, width: 1),
              ),
              child: Column(
                children: [
                  _buildHeader(context, isPending),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildUploadedFilesContent(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading) _buildLoadingOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isPending) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleExpansion,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            TextHelper.uploadedFiles,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 16,
              color: ColorHelper.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPending) ...[
                ValueListenableBuilder<bool>(
                  valueListenable: _isEditingNotifier,
                  builder: (context, isEditing, _) {
                    if (isEditing) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconButton(
                            icon: Icons.add,
                            onTap: _handleFileUpload,
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.check,
                            onTap: () => _isEditingNotifier.value = false,
                          ),
                        ],
                      );
                    }
                    return GestureDetector(
                      onTap: () => _isEditingNotifier.value = true,
                      child: Image.asset(
                        Assets.reportApEdit,
                        width: 20,
                        height: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              ValueListenableBuilder<bool>(
                valueListenable: _isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ColorHelper.textSecondary,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        return GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Icon(icon, size: 20, color: ColorHelper.textSecondary),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorHelper.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedFilesContent(BuildContext context) {
    final allFiles = _collectAllFiles();

    if (allFiles.isEmpty) {
      return Card(
        color: ColorHelper.white.withValues(alpha: 0.8),
        shadowColor: ColorHelper.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              TextHelper.noFilesUploaded,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorHelper.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: allFiles.map((file) => _buildFileItem(context, file)).toList(),
    );
  }

  List<Map<String, dynamic>> _collectAllFiles() {
    final allFiles = <Map<String, dynamic>>[];

    for (var image in widget.uploadedFiles.images) {
      allFiles.add({
        'url': image.fileUrl ?? '',
        'type': TextHelper.image,
        'name': image.fileName?.isNotEmpty == true
            ? image.fileName!
            : Uri.decodeComponent(image.fileUrl!.split('/').last),
        'fileType': image.fileType ?? TextHelper.image,
        'infoId': image.infoId ?? '',
      });
    }

    for (var video in widget.uploadedFiles.video) {
      allFiles.add({
        'url': video.fileUrl ?? '',
        'type': TextHelper.video,
        'name': video.fileName?.isNotEmpty == true
            ? video.fileName!
            : Uri.decodeComponent(video.fileUrl!.split('/').last),
        'fileType': video.fileType ?? TextHelper.video,
        'infoId': video.infoId ?? '',
      });
    }

    return allFiles;
  }

Widget _buildFileItem(BuildContext context, Map<String, dynamic> file) {
  final String type = file['type'] ?? '';
  final String name = file['name'] ?? '';
  final String url = file['url'] ?? '';
  final String decodedFileName = _decodeFileName(name);

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: ColorHelper.white.withValues(alpha: 0.8),
    ),
    child: GestureDetector(
      onTap: () {
        showBlurredDialog(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorHelper.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ColorHelper.textSecondary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        back();
                      },
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: ColorHelper.errorColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: ColorHelper.grey.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder:
                          (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                ColorHelper.primaryColor,
                              ),
                              value: loadingProgress
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
                      errorBuilder:
                          (context, error, stackTrace) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _isEditingNotifier,
        builder: (context, isEditing, _) {
          return Row(
            children: [
              Image.asset(
                _getFileIcon(type),
                width: 20,
                height: 20,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      decodedFileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                ColorHelper.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),

                  ],
                ),
              ),

              const SizedBox(width: 8),

              if (isEditing)
                ValueListenableBuilder<bool>(
                  valueListenable:
                      _isLoadingNotifier,
                  builder:
                      (context, isLoading, _) {
                    return Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 24,
                          color: ColorHelper
                              .textSecondary,
                        ),
                        IconButton(
                          padding:
                              EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(),
                          icon: Image.asset(
                            Assets
                                .reportDetailRecycleBin,
                            width: 20,
                            height: 20,
                          ),
                          onPressed: isLoading
                              ? null
                              : () =>
                                  showDeleteFileDialog(
                                    context,
                                    () =>
                                        _handleFileDelete(
                                      file[
                                          'infoId'],
                                      file[
                                          'fileType'],
                                    ),
                                  ),
                        ),
                      ],
                    );
                  },
                )
              else
                Icon(
                  Icons.open_in_new,
                  size: 24,
                  color:
                      ColorHelper.textSecondary,
                ),
            ],
          );
        },
      ),
    ),
  );
}

  String _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case TextHelper.image:
        return Assets.jpgImage;
      case TextHelper.audio:
        return Assets.mp3;
      case TextHelper.video:
        return Assets.mp4;
      default:
        return Assets.defaultPic;
    }
  }

  String _decodeFileName(String fileName) {
    if (fileName.isEmpty) return '';

    try {
      return Uri.decodeComponent(fileName);
    } catch (e) {
      return fileName;
    }
  }
}
