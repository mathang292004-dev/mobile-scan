import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/repo/case_approver_dashboard_repo.dart';

class CaseApproverDashboardUseCase {
  final CaseApproverDashboardRepository _repository;

  CaseApproverDashboardUseCase(this._repository);

  Future<ApiResponse<DashboardResponse>> getCases(
    DashboardRequestPayload payload,
  ) async {
    try {
      return await _repository.getCases(payload);
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}
