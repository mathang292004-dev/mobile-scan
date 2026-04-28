import 'dart:convert';

import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/presentation/case_report/model/dashboard_request_payload.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

/// Remote data source for the **member** dashboard.
/// Always calls `/api/incident/member-dashboard`. The approver dashboard has
/// its own data source and does not pass through this class.
abstract class DashboardRemoteDataSource {
  Future<ApiResponse<DashboardResponse>> getIncidentsList(
    DashboardRequestPayload payload,
  );
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<DashboardResponse>> getIncidentsList(
    DashboardRequestPayload payload,
  ) async {
    try {
      // Member dashboard ALWAYS calls /incident/member-dashboard.
      // Dio URL-encodes query params on the wire — do NOT pre-encode the JSON.
      final queryParams = <String, dynamic>{
        'filters': jsonEncode(payload.toJson()),
      };

      return await _apiClient.request<DashboardResponse>(
        ApiEndpoints.getIncidentsList,
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
        'Failed to get incidents list: ${e.toString()}',
      );
    }
  }
}
