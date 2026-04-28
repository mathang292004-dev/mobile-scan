import 'dart:convert';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/dashboard/dashboard_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

abstract class MyTaskDashboardRemoteDataSource {
  Future<ApiResponse<DashboardResponse>> getMyTaskDashboard(
    DashboardFilters filters, {
    String role = 'tl',
  });
}

class MyTaskDashboardRemoteDataSourceImpl
    implements MyTaskDashboardRemoteDataSource {
  final ApiClient _apiClient;

  MyTaskDashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<DashboardResponse>> getMyTaskDashboard(
    DashboardFilters filters, {
    String role = 'tl',
  }) async {
    try {
      final filterJson = {
        'status': filters.status ?? '',
        'page': filters.page ?? 0,
        'limit': filters.limit ?? 10,
        'search': filters.search ?? '',
        'daterange': filters.daterange ?? {'from': '', 'to': ''},
        'sortBy': filters.sortBy ?? '',
        'sortOrder': filters.sortOrder ?? 'asc',
      };

      final queryParams = <String, dynamic>{
        'type': 'ert',
        'role': role,
        'filters': Uri.encodeComponent(jsonEncode(filterJson)),
      };

      return await _apiClient.request<DashboardResponse>(
        ApiEndpoints.myTaskDashboard,
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
        'Failed to get my task dashboard: ${e.toString()}',
      );
    }
  }
}
