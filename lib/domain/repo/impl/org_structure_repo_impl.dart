import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/organization_structure/org_structure_response.dart';
import 'package:emergex/data/remote_data_source/org_structure_remote_data_source.dart';
import 'package:emergex/domain/repo/org_structure_repo.dart';

/// Repository implementation for Organization Structure
class OrgStructureRepositoryImpl implements OrgStructureRepository {
  final OrgStructureRemoteDataSource _remoteDataSource;

  OrgStructureRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<List<OrgStructureResponse>>> getOrgStructure(
    String projectId,
  ) async {
    try {
      return await _remoteDataSource.getOrgStructure(projectId);
    } catch (e) {
      return ApiResponse<List<OrgStructureResponse>>.error(
        'Failed to get organization structure: ${e.toString()}',
      );
    }
  }
}

