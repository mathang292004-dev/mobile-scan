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
import 'package:emergex/domain/repo/upload_doc_repo.dart';
import 'package:emergex/presentation/emergex_onboarding/model/upload_document_request.dart';

class OnboardingOrganizationStructureUseCase {
  final OnboardingOrganizationStructureRepository _onboardingOrganizationStructureRepository;

  OnboardingOrganizationStructureUseCase(this._onboardingOrganizationStructureRepository);

  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocument(
    UploadDocumentRequest request,
  ) async {
    try {
      return await _onboardingOrganizationStructureRepository.uploadDocument(request);
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Upload document with JSON payload (file items already uploaded)
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocumentWithPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _onboardingOrganizationStructureRepository.uploadDocumentWithPayload(payload);
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Upload files to incident file-upload endpoint
  Future<ApiResponse<IncidentFileUploadResponse>> uploadOrganizationStructureFiles(
    List<File> files, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await _onboardingOrganizationStructureRepository.uploadOrganizationStructureFiles(
        files,
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return ApiResponse<IncidentFileUploadResponse>.error(
          'Upload cancelled',
        );
      }
      return ApiResponse<IncidentFileUploadResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Complete onboarding for a project
  Future<ApiResponse<CompleteOnboardingResponse>> completeOnboarding(
    String projectId,
  ) async {
    try {
      return await _onboardingOrganizationStructureRepository.completeOnboarding(projectId);
    } catch (e) {
      return ApiResponse<CompleteOnboardingResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Get role details by roleId
  Future<ApiResponse<RoleDetailsResponse>> getRoleDetails(String roleId) async {
    try {
      return await _onboardingOrganizationStructureRepository.getRoleDetails(roleId);
    } catch (e) {
      return ApiResponse<RoleDetailsResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Fetch members by projectId (optionally with incidentId for add/reassign member)
  Future<ApiResponse<FetchMembersResponse>> fetchMembers(
    String projectId, {
    String? incidentId,
  }) async {
    try {
      return await _onboardingOrganizationStructureRepository.fetchMembers(
        projectId,
        incidentId: incidentId,
      );
    } catch (e) {
      return ApiResponse<FetchMembersResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Fetch roles by projectId
  Future<ApiResponse<FetchRolesResponse>> fetchRoles(String projectId) async {
    try {
      return await _onboardingOrganizationStructureRepository.fetchRoles(projectId);
    } catch (e) {
      return ApiResponse<FetchRolesResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Create a new role
  Future<ApiResponse<Role>> createRole(Map<String, dynamic> payload) async {
    try {
      return await _onboardingOrganizationStructureRepository.createRole(payload);
    } catch (e) {
      return ApiResponse<Role>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Delete assigned user from role
  Future<ApiResponse<void>> deleteAssignedUser(String roleId, String userId) async {
    try {
      return await _onboardingOrganizationStructureRepository.deleteAssignedUser(roleId, userId);
    } catch (e) {
      return ApiResponse<void>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Delete a role
  Future<ApiResponse<void>> deleteRole(String roleId, String projectId) async {
    try {
      return await _onboardingOrganizationStructureRepository.deleteRole(roleId, projectId);
    } catch (e) {
      return ApiResponse<void>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// View details (docs) for a project
  Future<ApiResponse<ViewDetailsResponse>> viewDetails(
    String projectId,
    String view,
  ) async {
    try {
      return await _onboardingOrganizationStructureRepository.viewDetails(projectId, view);
    } catch (e) {
      return ApiResponse<ViewDetailsResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Fetch modules and features for a project
  Future<ApiResponse<ModulesAndFeaturesResponse>> fetchFeatures(
    String projectId,
  ) async {
    try {
      return await _onboardingOrganizationStructureRepository.fetchFeatures(projectId);
    } catch (e) {
      return ApiResponse<ModulesAndFeaturesResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  /// Upload documents for all projects
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocsForAllProjects(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _onboardingOrganizationStructureRepository.uploadDocsForAllProjects(payload);
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}

