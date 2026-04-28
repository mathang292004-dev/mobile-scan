import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

// --- Data Models and Enums ---

enum TaskStatus { delay, completed, inProgress }

class GanttTask {
  final String id;
  final String label;
  final DateTime dateStart;
  final DateTime dateEnd;
  final TaskStatus status;
  final String assigneeName;
  final String assigneeImageUrl;
  final bool isAssigned;

  GanttTask({
    required this.id,
    required this.label,
    required this.dateStart,
    required this.dateEnd,
    required this.status,
    required this.assigneeName,
    required this.assigneeImageUrl,
    required this.isAssigned,
  });

  Color get color {
    switch (status) {
      case TaskStatus.delay:
        return const Color(0xFFFF4444); // Red
      case TaskStatus.completed:
        return const Color(0xFF00D084); // Green
      case TaskStatus.inProgress:
        return const Color(0xFFFF8C42); // Orange
    }
  }
}

// --- Custom Painter for single row ---
class SingleRowGridPainter extends CustomPainter {
  final double hourWidth;
  final double taskHeight;
  final int totalHours;

  SingleRowGridPainter({
    required this.hourWidth,
    required this.taskHeight,
    required this.totalHours,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (int i = 0; i <= totalHours; i++) {
      final double x = i * hourWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Bottom horizontal line
    canvas.drawLine(
      Offset(0, taskHeight),
      Offset(size.width, taskHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- Gantt Chart Widget ---
class EmergencyResponseGanttChart extends StatefulWidget {
  final List<GanttTask> tasks;
  final DateTime startTime;
  final DateTime endTime;
  final double leftPanelWidth;
  final bool isEditMode;

  const EmergencyResponseGanttChart({
    super.key,
    required this.tasks,
    required this.startTime,
    required this.endTime,
    this.leftPanelWidth = 300.0,
    this.isEditMode = false,
  });

  @override
  State<EmergencyResponseGanttChart> createState() =>
      _EmergencyResponseGanttChartState();
}

class _EmergencyResponseGanttChartState
    extends State<EmergencyResponseGanttChart> {
  final double hourWidth = 120.0;
  final double taskHeight = 60.0;
  final double rowSpacing = 20.0;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Get filtered tasks based on edit mode
  List<GanttTask> get filteredTasks {
    if (!widget.isEditMode) {
      // When not in edit mode, only show assigned tasks
      return widget.tasks.where((task) => task.isAssigned).toList();
    }
    return widget.tasks;
  }

  DateTime get minStartTime {
    // When there are no tasks, fall back to the provided startTime to avoid
    // calling reduce on an empty iterable.
    if (filteredTasks.isEmpty) return widget.startTime;
    return filteredTasks
        .map((t) => t.dateStart)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime get maxEndTime {
    // When there are no tasks, fall back to the provided endTime to avoid
    // calling reduce on an empty iterable.
    if (filteredTasks.isEmpty) return widget.endTime;
    return filteredTasks
        .map((t) => t.dateEnd)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  int get totalHours {
    // Ensure totalHours is always at least 1 to keep the timeline layout stable
    // even if the end is not after the start.
    final diff = maxEndTime.difference(minStartTime).inHours + 1;
    return diff > 0 ? diff : 1;
  }

  double get timelineWidth => totalHours * hourWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.4),
        border: Border.all(color: ColorHelper.white, width: 1),
      ),
      child: _buildGanttContent(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        TextHelper.chartTitle,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: ColorHelper.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 20,
        runSpacing: 8,
        children: <Widget>[
          _buildLegendItem(TextHelper.statusDelay, const Color(0xFFFF4444)),
          _buildLegendItem(TextHelper.statusCompleted, const Color(0xFF00D084)),
          _buildLegendItem(TextHelper.inProgress, const Color(0xFFFF8C42)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildGanttContent() {
    // Empty state when there are no tasks
    if (widget.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                TextHelper.noTasksToDisplay,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _horizontalScrollController,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      thickness: 0,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widget.leftPanelWidth + timelineWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildLegend()),
                ],
              ),
              _buildTimelineHeaderRow(),
              Expanded(
                child: Scrollbar(
                  controller: _verticalScrollController,
                  child: ListView.builder(
                    controller: _verticalScrollController,
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _buildTaskRow(task);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineHeaderRow() {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          SizedBox(width: widget.leftPanelWidth),
          _buildTimelineHeader(),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Container(
      width: timelineWidth,
      height: 60,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: List<Widget>.generate(totalHours, (int index) {
          final DateTime hour = minStartTime.add(Duration(hours: index));
          return Container(
            width: hourWidth,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Center(
              child: Text(
                '${hour.hour.toString().padLeft(2, '0')}:00',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskRow(GanttTask task) {
    return SizedBox(
      child: Row(children: [_buildTaskLabel(task), _buildTimelineRow(task)]),
    );
  }

  Widget _buildTaskLabel(GanttTask task) {
    return SizedBox(
      width: widget.leftPanelWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white54,
        ),
        child: Text(
          task.label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Colors.black87),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }

  Widget _buildTimelineRow(GanttTask task) {
    final double taskStartMinutes = task.dateStart
        .difference(minStartTime)
        .inMinutes
        .toDouble();
    final double taskDurationMinutes = task.dateEnd
        .difference(task.dateStart)
        .inMinutes
        .toDouble();

    final double taskLeft = (taskStartMinutes / 60) * hourWidth;
    final double taskWidth = (taskDurationMinutes / 60) * hourWidth;

    return Container(
      height: taskHeight + rowSpacing,
      width: timelineWidth,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          _buildGridBackgroundSingleRow(),
          Positioned(
            left: taskLeft,
            top: 20,
            child: Container(
              width: taskWidth,
              height: taskHeight - 20,
              decoration: BoxDecoration(
                color: task.color,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: task.color.withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: task.assigneeImageUrl.isNotEmpty
                          ? NetworkImage(task.assigneeImageUrl)
                          : null,
                      backgroundColor: Colors.white,
                      child: task.assigneeImageUrl.isEmpty
                          ? Icon(Icons.person, size: 14, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.assigneeName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackgroundSingleRow() {
    return SizedBox(
      width: timelineWidth,
      height: taskHeight + rowSpacing,
      child: CustomPaint(
        painter: SingleRowGridPainter(
          hourWidth: hourWidth,
          taskHeight: taskHeight + rowSpacing,
          totalHours: totalHours,
        ),
      ),
    );
  }
}
