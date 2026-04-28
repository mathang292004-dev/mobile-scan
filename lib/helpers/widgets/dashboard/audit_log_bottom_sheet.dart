import 'package:emergex/data/model/incident/audit_log_response.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/common/cubit/audit_log_cubit.dart';
import 'package:emergex/presentation/common/cubit/audit_log_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ordered timeline stages shown in the Activity Timeline dialog.
/// Keys MUST match backend `timeline` response keys.
const List<_StageMeta> _kStages = [
  _StageMeta(
    'reportCreated',
    TextHelper.stageReportCreated,
    'Case report created',
    Icons.add,
  ),
  _StageMeta(
    'adminApproval',
    TextHelper.stageAdminApproval,
    'Approved by Incident Admin',
    Icons.person,
  ),
  _StageMeta(
    'ertTeamAssigned',
    TextHelper.stageTeamAssigned,
    'ER Team TL  assigned member',
    Assets.teamAssigned,
  ),
  _StageMeta(
    'responseSubmitted',
    TextHelper.stageResponseSubmitted,
    'Task Completed by ER Member',
    Icons.groups,
  ),
  _StageMeta(
    'responseVerified',
    TextHelper.stageResponseVerified,
    'Task Verified and approved',
    Icons.done_all,
  ),
  _StageMeta(
    'investigationStarted',
    TextHelper.stageInvestigationStarted,
    'Investigation TL  setup Team',
    Assets.teamAssigned,
  ),
  _StageMeta(
    'investigationCompleted',
    TextHelper.stageInvestigationCompleted,
    'Submitted by investigation Team',
    Icons.groups,
  ),
  _StageMeta(
    'investigationApproved',
    TextHelper.stageInvestigationApproved,
    'Tasks verified and approved',
    Icons.done_all,
  ),
  _StageMeta(
    'closureCompleted',
    TextHelper.stageAdminClosureCompleted,
    'Closure Admin Closed The Cases',
    Assets.adminClosureCompleted,
  ),
];

/// Shows the shared Activity Timeline dialog for a given case.
/// Kept function name for existing call-sites.
Future<void> showAuditLogBottomSheet(BuildContext context, String caseId) {
  final cubit = AppDI.auditLogCubit..fetchAuditLogs(caseId);
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _AuditLogDialog()),
  );
}

class _AuditLogDialog extends StatelessWidget {
  const _AuditLogDialog();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      backgroundColor: const Color(0xFFF4F6F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: media.size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Flexible(
                child: BlocBuilder<AuditLogCubit, AuditLogState>(
                  builder: (context, state) {
                    if (state is AuditLogLoading || state is AuditLogInitial) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: ColorHelper.primaryColor,
                          ),
                        ),
                      );
                    }
                    if (state is AuditLogError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ColorHelper.textSecondary),
                          ),
                        ),
                      );
                    }
                    if (state is AuditLogLoaded) {
                      return _buildTimelineList(state.data);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                TextHelper.activityTimeline,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ColorHelper.black5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorHelper.primaryColor,
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: ColorHelper.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          TextHelper.activityTimelineSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineList(AuditLogResponse data) {
    final timeline = data.timeline ?? const {};
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        children: List.generate(_kStages.length, (i) {
          final meta = _kStages[i];
          final stage = timeline[meta.key];
          final completed = stage?.completed == true;
          return _TimelineCard(
            meta: meta,
            stage: stage,
            completed: completed,
            isLast: i == _kStages.length - 1,
          );
        }),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final _StageMeta meta;
  final TimelineStage? stage;
  final bool completed;
  final bool isLast;

  const _TimelineCard({
    required this.meta,
    required this.stage,
    required this.completed,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = completed ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: ColorHelper.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StageIcon(icon: meta.icon),
                    Spacer(),
                    const SizedBox(width: 12),
                    Expanded(child: _DateTimeLabel(iso: stage?.completedAt)),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  meta.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ColorHelper.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (stage?.description ?? '').isNotEmpty
                      ? stage!.description!
                      : meta.defaultSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorHelper.black5,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) const _DottedConnector(),
        ],
      ),
    );
  }
}

class _StageIcon extends StatelessWidget {
  final dynamic icon;
  const _StageIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: ColorHelper.primaryColor,
        shape: BoxShape.circle,
      ),
      child: icon is IconData
          ? Icon(icon as IconData, size: 16, color: ColorHelper.white)
          : Center(
              child: Image.asset(
                icon as String,
                width: 18,
                height: 18,
                color: ColorHelper.white,
              ),
            ),
    );
  }
}

class _DateTimeLabel extends StatelessWidget {
  final String? iso;
  const _DateTimeLabel({required this.iso});

  @override
  Widget build(BuildContext context) {
    final parts = _formatDate(iso);
    if (parts == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          parts.$1,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        Text(
          parts.$2,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColorHelper.primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Vertical dotted connector between timeline cards.
class _DottedConnector extends StatelessWidget {
  const _DottedConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 2, bottom: 2),
      child: SizedBox(
        height: 16,
        width: 2,
        child: CustomPaint(
          painter: _DottedLinePainter(
            color: ColorHelper.primaryColor.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dash = 2.0;
    const gap = 3.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter old) => old.color != color;
}

/// Returns (date, time) formatted like "Oct 28, 2025" and "06.30PM".
(String, String)? _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return null;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final date = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  final h24 = dt.hour;
  final period = h24 >= 12 ? 'PM' : 'AM';
  final h12 = ((h24 % 12) == 0) ? 12 : h24 % 12;
  final mm = dt.minute.toString().padLeft(2, '0');
  final time = '${h12.toString().padLeft(2, '0')}.$mm$period';
  return (date, time);
}

class _StageMeta {
  final String key;
  final String title;
  final String defaultSubtitle;
  final dynamic icon;
  const _StageMeta(this.key, this.title, this.defaultSubtitle, this.icon);
}
