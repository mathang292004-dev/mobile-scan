import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/investigation/tl_task/cubit/investigation_tl_task_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvestigationTlTaskDetailScreen extends StatelessWidget {
  final String taskId;

  const InvestigationTlTaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: AppDI.investigationTlTaskCubit,
      child: BlocBuilder<InvestigationTlTaskCubit, InvestigationTlTaskState>(
        builder: (context, state) {
          // Find the task from state
          TlInvestigationTask? task;
          try {
            task = state.tasks.firstWhere((t) => t.taskId == taskId);
          } catch (_) {
            // Fall back to first task if not found (for preview/demo)
            task = state.tasks.isNotEmpty ? state.tasks.first : null;
          }

          if (task == null) {
            return AppScaffold(
              useGradient: true,
              showDrawer: false,
              appBar:
                  const AppBarWidget(showBackButton: true, hasNotifications: true),
              showBottomNav: false,
              child: const Center(
                child:
                    CircularProgressIndicator(color: ColorHelper.primaryColor),
              ),
            );
          }

          final finalTask = task;

          return AppScaffold(
            useGradient: true,
            gradientBegin: Alignment.topCenter,
            gradientEnd: Alignment.bottomCenter,
            showDrawer: false,
            appBar: const AppBarWidget(hasNotifications: true),
            showBottomNav: false,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 0, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: back button + task ID + chat icon
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => back(),
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: ColorHelper.white.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                                border: Border.all(color: ColorHelper.white),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: ColorHelper.black,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Task #${finalTask.taskId}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  ColorHelper.primaryColor,
                                  ColorHelper.buttonColor,
                                ],
                              ),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: ColorHelper.primaryColor),
                            ),
                            child: Image.asset(
                              Assets.chat,
                              width: 18,
                              height: 18,
                              color: ColorHelper.white,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: ColorHelper.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Task Info Card
                      AppContainer(
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              finalTask.taskName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              finalTask.taskId,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Timer pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(
                                        color: ColorHelper.primaryColor),
                                    color: ColorHelper.primaryColor
                                        .withValues(alpha: 0.08),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 14,
                                        color: ColorHelper.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        finalTask.timeTaken,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: ColorHelper.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${TextHelper.assignedBy} ${finalTask.completedBy}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: ColorHelper.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: ColorHelper.successColor
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                finalTask.status,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: ColorHelper.successColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Task Details Section
                      AppContainer(
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TextHelper.taskDetails,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              finalTask.taskDetails,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // AI Analysis Section
                      _buildAiAnalysisSection(context, finalTask),
                      const SizedBox(height: 16),

                      // Incident Attachments (Reporter)
                      AppContainer(
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TextHelper.incidentAttachments,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              3,
                              (i) => _buildAttachmentRow(
                                  context, 'Incident_Photo_${i + 1}.jpg'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ERT Attachments
                      AppContainer(
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  TextHelper.ertAttachments,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.add,
                                      size: 16,
                                      color: ColorHelper.primaryColor),
                                  label: Text(
                                    TextHelper.addFiles,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: ColorHelper.primaryColor),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: ColorHelper.primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildAttachmentRow(context, 'report_image.jpg'),
                            _buildAttachmentRow(context, 'site_photo.jpg'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Completed By section
                      AppContainer(
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: ColorHelper.primaryColor
                                  .withValues(alpha: 0.15),
                              child: Text(
                                finalTask.completedBy[0],
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: ColorHelper.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TextHelper.completedBy,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: ColorHelper.textSecondary),
                                ),
                                Text(
                                  finalTask.completedBy,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              finalTask.timeTaken,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: ColorHelper.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed footer buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: ColorHelper.white.withValues(alpha: 0.8),
                      border: Border(
                        top: BorderSide(
                          color:
                              ColorHelper.textSecondary.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => back(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: ColorHelper.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              TextHelper.save,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: ColorHelper.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: EmergexButton(
                            text: TextHelper.markAsCompleted,
                            onPressed: () {},
                            borderRadius: 9999,
                            buttonHeight: 50,
                            textSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAiAnalysisSection(
      BuildContext context, TlInvestigationTask task) {
    return AppContainer(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 18,
                color: ColorHelper.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                TextHelper.aiAnalysis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI Summary
          Text(
            TextHelper.aiSummary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            task.aiSummary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorHelper.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 12),

          // Delay Risk
          Row(
            children: [
              Text(
                '${TextHelper.delayRiskDetected}: ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorHelper.textSecondary,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: task.delayRiskDetected
                      ? ColorHelper.errorColor.withValues(alpha: 0.15)
                      : ColorHelper.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  task.delayRiskDetected ? TextHelper.yes : TextHelper.no,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: task.delayRiskDetected
                            ? ColorHelper.errorColor
                            : ColorHelper.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI Recommendations
          Text(
            TextHelper.aiRecommendations,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
          ...task.aiRecommendations.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 5, right: 8),
                        decoration: const BoxDecoration(
                          color: ColorHelper.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColorHelper.textSecondary,
                                    height: 1.4,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(BuildContext context, String fileName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorHelper.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 20,
              color: ColorHelper.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.open_in_new,
            size: 16,
            color: ColorHelper.primaryColor,
          ),
        ],
      ),
    );
  }
}
