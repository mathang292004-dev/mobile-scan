import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/organization_structure/org_structure_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

/// Remote data source interface for Organization Structure
abstract class OrgStructureRemoteDataSource {
  Future<ApiResponse<List<OrgStructureResponse>>> getOrgStructure(
    String projectId,
  );
}

/// Remote data source implementation for Organization Structure
class OrgStructureRemoteDataSourceImpl implements OrgStructureRemoteDataSource {
  final ApiClient _apiClient;

  OrgStructureRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<List<OrgStructureResponse>>> getOrgStructure(
    String projectId,
  ) async {
    try {
      final url = ApiEndpoints.getOrgStructure.replaceAll('{projectId}', projectId);
      return await _apiClient.request<List<OrgStructureResponse>>(
        url,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as List;
            return data
                .map((e) => OrgStructureResponse.fromJson(
                    e as Map<String, dynamic>))
                .toList();
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<List<OrgStructureResponse>>.error(
        'Failed to get organization structure: ${e.toString()}',
      );
    }
  }
}

