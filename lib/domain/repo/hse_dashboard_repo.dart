import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';

/// Repository interface for HSE Dashboard
abstract class HseDashboardRepository {
  Future<ApiResponse<DashboardResponse>> getHseDashboard(
    DashboardFilters filters,
  );
}
