import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';

abstract class DashboardRepository {
  Future<ApiResponse<DashboardResponse>> getIncidentsList(
    DashboardRequestPayload payload,
  );
}
