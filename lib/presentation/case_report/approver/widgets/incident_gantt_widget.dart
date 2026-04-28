import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/presentation/case_report/approver/utils/incident_teams_utils.dart';
import 'package:emergex/presentation/case_report/approver/widgets/emergency_response_gantt_chart.dart';
import 'package:flutter/material.dart';

class IncidentGanttWidget extends StatelessWidget {
  final IncidentDetails incident;

  const IncidentGanttWidget({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    final tasks = mapIncidentToGanttTasks(incident);
    final now = DateTime.now().toUtc();

    var start = tasks.isNotEmpty
        ? tasks.map((t) => t.dateStart).reduce((a, b) => a.isBefore(b) ? a : b)
        : now.subtract(const Duration(hours: 2));
    var end = tasks.isNotEmpty
        ? tasks.map((t) => t.dateEnd).reduce((a, b) => a.isAfter(b) ? a : b)
        : now.add(const Duration(hours: 2));

    if (!end.isAfter(start)) {
      end = start.add(const Duration(hours: 1));
    }

    return SizedBox(
      height: 600,
      child: EmergencyResponseGanttChart(
        tasks: tasks,
        startTime: start,
        endTime: end,
      ),
    );
  }
}
