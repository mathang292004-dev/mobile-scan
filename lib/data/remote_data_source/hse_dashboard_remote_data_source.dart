import 'dart:convert';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

/// Remote data source interface for HSE Dashboard
abstract class HseDashboardRemoteDataSource {
  Future<ApiResponse<DashboardResponse>> getHseDashboard(
    DashboardFilters filters,
  );
}

/// Remote data source implementation for HSE Dashboard
class HseDashboardRemoteDataSourceImpl
    implements HseDashboardRemoteDataSource {
  final ApiClient _apiClient;

  HseDashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<DashboardResponse>> getHseDashboard(
    DashboardFilters filters,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'filters': Uri.encodeComponent(jsonEncode(filters.toErApproverJson())),
      };

      return await _apiClient.request<DashboardResponse>(
        ApiEndpoints.closureDashboard,
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
        'Failed to get HSE dashboard: ${e.toString()}',
      );
    }
  }
}
