import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/organization_structure/org_structure_response.dart';
import 'package:emergex/domain/repo/org_structure_repo.dart';

/// Use case for Organization Structure
class OrgStructureUseCase {
  final OrgStructureRepository _repository;

  OrgStructureUseCase(this._repository);

  Future<ApiResponse<List<OrgStructureResponse>>> getOrgStructure(
    String projectId,
  ) async {
    try {
      return await _repository.getOrgStructure(projectId);
    } catch (e) {
      return ApiResponse<List<OrgStructureResponse>>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}

