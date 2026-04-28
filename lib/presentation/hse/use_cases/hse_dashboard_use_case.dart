import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/repo/hse_dashboard_repo.dart';

/// Use case for HSE Dashboard
/// Encapsulates business logic for fetching HSE dashboard data
class HseDashboardUseCase {
  final HseDashboardRepository _repository;

  HseDashboardUseCase(this._repository);

  /// Get HSE dashboard with filters
  Future<ApiResponse<DashboardResponse>> execute(
    DashboardFilters filters,
  ) async {
    return await _repository.getHseDashboard(filters);
  }
}
