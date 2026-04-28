import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/remote_data_source/dashboard_remote_data_source.dart';
import 'package:emergex/domain/repo/dashboard_repo.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<DashboardResponse>> getIncidentsList(
    DashboardRequestPayload payload,
  ) async {
    try {
      return await _remoteDataSource.getIncidentsList(payload);
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get incidents list: ${e.toString()}',
      );
    }
  }
}
