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
import 'package:emergex/data/remote_data_source/upload_doc_remote_data_source.dart';
import 'package:emergex/domain/repo/upload_doc_repo.dart';
import 'package:emergex/presentation/emergex_onboarding/model/upload_document_request.dart';

class OnboardingOrganizationStructureRepositoryImpl implements OnboardingOrganizationStructureRepository {
  final OnboardingOrganizationStructureRemoteDataSource _remoteDataSource;

  OnboardingOrganizationStructureRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocument(
    UploadDocumentRequest request,
  ) async {
    try {
      return await _remoteDataSource.uploadDocument(request);
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Failed to upload document: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocumentWithPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _remoteDataSource.uploadDocumentWithPayload(payload);
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Failed to upload document: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<IncidentFileUploadResponse>> uploadOrganizationStructureFiles(
    List<File> files, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await _remoteDataSource.uploadOrganizationStructureFiles(
        files,
        cancelToken: cancelToken,
      );
    } catch (e) {
      return ApiResponse<IncidentFileUploadResponse>.error(
        'Failed to upload incident files: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<CompleteOnboardingResponse>> completeOnboarding(
    String projectId,
  ) async {
    try {
      return await _remoteDataSource.completeOnboarding(projectId);
    } catch (e) {
      return ApiResponse<CompleteOnboardingResponse>.error(
        'Failed to complete onboarding: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<RoleDetailsResponse>> getRoleDetails(String roleId) async {
    try {
      return await _remoteDataSource.getRoleDetails(roleId);
    } catch (e) {
      return ApiResponse<RoleDetailsResponse>.error(
        'Failed to get role details: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<FetchMembersResponse>> fetchMembers(
    String projectId, {
    String? incidentId,
  }) async {
    try {
      return await _remoteDataSource.fetchMembers(
        projectId,
        incidentId: incidentId,
      );
    } catch (e) {
      return ApiResponse<FetchMembersResponse>.error(
        'Failed to fetch members: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<FetchRolesResponse>> fetchRoles(String projectId) async {
    try {
      return await _remoteDataSource.fetchRoles(projectId);
    } catch (e) {
      return ApiResponse<FetchRolesResponse>.error(
        'Failed to fetch roles: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<Role>> createRole(Map<String, dynamic> payload) async {
    try {
      return await _remoteDataSource.createRole(payload);
    } catch (e) {
      return ApiResponse<Role>.error(
        'Failed to create role: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<void>> deleteAssignedUser(String roleId, String userId) async {
    try {
      return await _remoteDataSource.deleteAssignedUser(roleId, userId);
    } catch (e) {
      return ApiResponse<void>.error(
        'Failed to delete assigned user: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<void>> deleteRole(String roleId, String projectId) async {
    try {
      return await _remoteDataSource.deleteRole(roleId, projectId);
    } catch (e) {
      return ApiResponse<void>.error(
        'Failed to delete role: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<ViewDetailsResponse>> viewDetails(
    String projectId,
    String view,
  ) async {
    try {
      return await _remoteDataSource.viewDetails(projectId, view);
    } catch (e) {
      return ApiResponse<ViewDetailsResponse>.error(
        'Failed to fetch view details: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<ModulesAndFeaturesResponse>> fetchFeatures(
    String projectId,
  ) async {
    try {
      return await _remoteDataSource.fetchFeatures(projectId);
    } catch (e) {
      return ApiResponse<ModulesAndFeaturesResponse>.error(
        'Failed to fetch features: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocsForAllProjects(
    Map<String, dynamic> payload,
  ) async {
    try {
      return await _remoteDataSource.uploadDocsForAllProjects(payload);
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Failed to upload documents for all projects: ${e.toString()}',
      );
    }
  }
}

