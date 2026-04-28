import 'dart:convert';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

/// Common remote data source for ERT Dashboard (used by both TL and Member).
/// Calls GET /incident/tl-dashboard?type=ert and returns the unified DashboardResponse.
abstract class ErtDashboardRemoteDataSource {
  Future<ApiResponse<DashboardResponse>> getErtDashboard(
    DashboardFilters filters,
  );
}

class ErtDashboardRemoteDataSourceImpl implements ErtDashboardRemoteDataSource {
  final ApiClient _apiClient;

  ErtDashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<DashboardResponse>> getErtDashboard(
    DashboardFilters filters,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'ert',
        'filters': Uri.encodeComponent(jsonEncode(filters.toJson())),
      };

      return await _apiClient.request<DashboardResponse>(
        ApiEndpoints.tlDashboard,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: queryParams,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            return DashboardResponse.fromJson(
              json['data'] as Map<String, dynamic>,
            );
          }
          throw Exception('Invalid response format from server');
        },
      );
    } catch (e) {
      return ApiResponse<DashboardResponse>.error(
        'Failed to get ERT dashboard: ${e.toString()}',
      );
    }
  }
}
