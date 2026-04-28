import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/organization_structure/org_structure_response.dart';

/// Repository interface for Organization Structure
abstract class OrgStructureRepository {
  Future<ApiResponse<List<OrgStructureResponse>>> getOrgStructure(
    String projectId,
  );
}

