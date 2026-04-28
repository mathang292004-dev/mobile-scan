import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/presentation/case_report/model/file_upload_item.dart';
import 'package:emergex/presentation/case_report/approver/widgets/custom_audio_player.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/audio_item_widget.dart';
import 'package:emergex/presentation/case_report/report_emergex/widgets/no_files_widget.dart';
import 'package:flutter/material.dart';

class RecordedFilesWidget extends StatefulWidget {
  final List<FileUploadItem> recordings;

  const RecordedFilesWidget({super.key, required this.recordings});

  @override
  State<RecordedFilesWidget> createState() => _RecordedFilesWidgetState();
}

class _RecordedFilesWidgetState extends State<RecordedFilesWidget> {
  late final ValueNotifier<FileUploadItem?> _currentFile;

  @override
  void initState() {
    super.initState();
    _currentFile = ValueNotifier(null);
  }

  @override
  void dispose() {
    _currentFile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordings = widget.recordings;
    return recordings.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: const NoFilesWidget(title: TextHelper.recordedFiles),
          )
        : Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: AppContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextHelper.recordedFiles,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorHelper.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // recordings list
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recordings.length,
                      itemBuilder: (context, index) {
                        final recording = recordings[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              if (_currentFile.value?.id != recording.id) {
                                _currentFile.value = recording;
                              }
                            },
                            child: ValueListenableBuilder<FileUploadItem?>(
                              valueListenable: _currentFile,
                              builder: (context, current, _) {
                                final isSelected = current?.id == recording.id;

                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: ColorHelper.primaryColor,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: FileRowWidget(
                                    recording: recording,
                                    isPlaying: isSelected,
                                    onPlayAudio: (_) {},
                                    onDeleted: (bool isDeleted) {
                                      _currentFile.value = null;
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // conditional player
                  ValueListenableBuilder<FileUploadItem?>(
                    valueListenable: _currentFile,
                    builder: (context, current, _) {
                      if (current == null) return const SizedBox();
                      final fileName = current.fileUrl != null
                          ? Uri.decodeComponent(
                              current.fileUrl!.split('-').last,
                            )
                          : current.fileName;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          CustomAudioPlayer(
                            fileName: fileName,
                            fileUrl: current.fileUrl!,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
  }
}
