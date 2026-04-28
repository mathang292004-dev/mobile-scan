import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';

/// Repository interface for ER Team Leader Dashboard
abstract class ErTeamLeaderDashboardRepository {
  Future<ApiResponse<DashboardResponse>> getTlDashboard(
    DashboardFilters filters,
  );
}

