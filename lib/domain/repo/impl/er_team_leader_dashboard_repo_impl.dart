import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/remote_data_source/ert_dashboard_remote_data_source.dart';
import 'package:emergex/domain/repo/er_team_leader_dashboard_repo.dart';

/// Repository implementation for ER Team Leader Dashboard
class ErTeamLeaderDashboardRepositoryImpl
    implements ErTeamLeaderDashboardRepository {
  final ErtDashboardRemoteDataSource _remoteDataSource;

  ErTeamLeaderDashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<DashboardResponse>> getTlDashboard(
    DashboardFilters filters,
  ) async {
    try {
      return await _remoteDataSource.getErtDashboard(filters);
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get TL dashboard: ${e.toString()}',
      );
    }
  }
}
