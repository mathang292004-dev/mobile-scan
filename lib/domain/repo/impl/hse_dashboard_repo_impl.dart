import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/remote_data_source/hse_dashboard_remote_data_source.dart';
import 'package:emergex/domain/repo/hse_dashboard_repo.dart';

/// Repository implementation for HSE Dashboard
class HseDashboardRepositoryImpl implements HseDashboardRepository {
  final HseDashboardRemoteDataSource _remoteDataSource;

  HseDashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<DashboardResponse>> getHseDashboard(
    DashboardFilters filters,
  ) async {
    try {
      return await _remoteDataSource.getHseDashboard(filters);
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get HSE dashboard: ${e.toString()}',
      );
    }
  }
}
