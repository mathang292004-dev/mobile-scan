import 'dart:convert';

import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

/// Remote data source for the **case approver** dashboard.
/// Always calls `/api/incident/approver-dashboard?type=admin`.
abstract class CaseApproverDashboardRemoteDataSource {
  Future<ApiResponse<DashboardResponse>> getCases(
    DashboardRequestPayload payload,
  );
}

class CaseApproverDashboardRemoteDataSourceImpl
    implements CaseApproverDashboardRemoteDataSource {
  final ApiClient _apiClient;

  CaseApproverDashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<DashboardResponse>> getCases(
    DashboardRequestPayload payload,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'admin',
        'filters': jsonEncode(payload.toJson()),
      };

      return await _apiClient.request<DashboardResponse>(
        ApiEndpoints.approverDashboard,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: queryParams,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return DashboardResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get approver dashboard: ${e.toString()}',
      );
    }
  }
}
