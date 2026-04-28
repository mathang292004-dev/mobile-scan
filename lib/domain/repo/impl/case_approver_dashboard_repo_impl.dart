import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/data/remote_data_source/case_approver_dashboard_remote_data_source.dart';
import 'package:emergex/domain/repo/case_approver_dashboard_repo.dart';

class CaseApproverDashboardRepositoryImpl
    implements CaseApproverDashboardRepository {
  final CaseApproverDashboardRemoteDataSource _remoteDataSource;

  CaseApproverDashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<DashboardResponse>> getCases(
    DashboardRequestPayload payload,
  ) async {
    try {
      return await _remoteDataSource.getCases(payload);
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get approver dashboard: ${e.toString()}',
      );
    }
  }
}
