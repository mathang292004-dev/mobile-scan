import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/repo/er_team_leader_dashboard_repo.dart';

/// Use case for ER Team Leader Dashboard
class ErTeamLeaderDashboardUseCase {
  final ErTeamLeaderDashboardRepository _repository;

  ErTeamLeaderDashboardUseCase(this._repository);

  Future<ApiResponse<DashboardResponse>> getTlDashboard(
    DashboardFilters filters,
  ) async {
    try {
      return await _repository.getTlDashboard(filters);
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get TL dashboard: ${e.toString()}',
      );
    }
  }
}

