import 'dart:io';
import 'package:dio/dio.dart';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/upload_doc/complete_onboarding_response.dart';
import 'package:emergex/data/model/upload_doc/fetch_members_response.dart';
import 'package:emergex/data/model/upload_doc/fetch_roles_response.dart';
import 'package:emergex/data/model/upload_doc/incident_file_upload_response.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';
import 'package:emergex/data/model/upload_doc/modules_and_features_response.dart';
import 'package:emergex/data/model/upload_doc/view_details_response.dart';
import 'package:emergex/presentation/emergex_onboarding/model/upload_document_request.dart';

abstract class OnboardingOrganizationStructureRepository {
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocument(
    UploadDocumentRequest request,
  );

  /// Upload document with JSON payload (file items already uploaded)
  Future<ApiResponse<OnboardingOrganizationStructure>>
  uploadDocumentWithPayload(Map<String, dynamic> payload);

  /// Upload files to incident file-upload endpoint
  Future<ApiResponse<IncidentFileUploadResponse>>
  uploadOrganizationStructureFiles(
    List<File> files, {
    CancelToken? cancelToken,
  });

  /// Complete onboarding for a project
  Future<ApiResponse<CompleteOnboardingResponse>> completeOnboarding(
    String projectId,
  );

  /// Get role details by roleId
  Future<ApiResponse<RoleDetailsResponse>> getRoleDetails(String roleId);

  /// Fetch members by projectId (optionally with incidentId for add/reassign member)
  Future<ApiResponse<FetchMembersResponse>> fetchMembers(
    String projectId, {
    String? incidentId,
  });

  /// Fetch roles by projectId
  Future<ApiResponse<FetchRolesResponse>> fetchRoles(String projectId);

  /// Create a new role
  Future<ApiResponse<Role>> createRole(Map<String, dynamic> payload);

  /// Delete assigned user from role
  Future<ApiResponse<void>> deleteAssignedUser(String roleId, String userId);

  /// Delete a role
  Future<ApiResponse<void>> deleteRole(String roleId, String projectId);

  /// View details (docs) for a project
  Future<ApiResponse<ViewDetailsResponse>> viewDetails(
    String projectId,
    String view,
  );

  /// Fetch modules and features for a project
  Future<ApiResponse<ModulesAndFeaturesResponse>> fetchFeatures(
    String projectId,
  );

  /// Upload documents for all projects
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocsForAllProjects(
    Map<String, dynamic> payload,
  );
}
