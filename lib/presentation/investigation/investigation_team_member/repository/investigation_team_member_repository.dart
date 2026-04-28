import '../cubit/investigation_team_member_cubit.dart';

abstract class InvestigationTeamMemberRepository {
  Future<List<InvestigationMemberIncident>> fetchDummyIncidents();
  Future<List<InvestigationMemberTask>> fetchDummyTasks(String incidentId);
  Future<InvestigationMemberTask> fetchDummyTaskDetails(String taskId);
  Future<void> updateDummyTaskStatus(
    String taskId,
    String status,
    String? statusUpdate,
  );
}

class InvestigationTeamMemberRepositoryImpl
    implements InvestigationTeamMemberRepository {
  @override
  Future<List<InvestigationMemberIncident>> fetchDummyIncidents() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const InvestigationMemberIncident(
        id: 'INC511',
        title: 'Chemical Spill in Lab B',
        projectId: 'Project Alpha',
        status: 'Inprogress',
        severity: 'High',
        priority: 'Critical',
      ),
      const InvestigationMemberIncident(
        id: 'INC512',
        title: 'Equipment Failure',
        projectId: 'Project Beta',
        status: 'Resolved',
        severity: 'Medium',
        priority: 'Medium',
      ),
    ];
  }

  @override
  Future<List<InvestigationMemberTask>> fetchDummyTasks(
    String incidentId,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      InvestigationMemberTask(
        id: '1',
        taskId: 'TSK-1001',
        incidentId: incidentId,
        title: 'Isolate area',
        code: 'TSK-1001',
        date: 'Oct 14, 2026',
        description: 'Secure area and restrict unauthorized access.',
        status: 'In Progress',
        assignedBy: 'System',
        attachments: [],
      ),
    ];
  }

  @override
  Future<InvestigationMemberTask> fetchDummyTaskDetails(String taskId) async {
    await Future.delayed(const Duration(seconds: 1));
    return const InvestigationMemberTask(
      id: '1',
      taskId: 'TSK-1001',
      incidentId: 'INC511',
      title: 'Isolate area',
      code: 'TSK-1001',
      date: 'Oct 14, 2026',
      description: 'Secure area and restrict unauthorized access.',
      status: 'In Progress',
      assignedBy: 'System',
      attachments: [],
    );
  }

  @override
  Future<void> updateDummyTaskStatus(
    String taskId,
    String status,
    String? statusUpdate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
