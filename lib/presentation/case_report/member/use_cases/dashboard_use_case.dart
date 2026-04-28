import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/repo/dashboard_repo.dart';

class DashboardUseCase {
  final DashboardRepository _dashboardRepository;

  DashboardUseCase(this._dashboardRepository);

  Future<ApiResponse<DashboardResponse>> getIncidentsList(
    DashboardRequestPayload payload,
  ) async {
    try {
      return await _dashboardRepository.getIncidentsList(payload);
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}
