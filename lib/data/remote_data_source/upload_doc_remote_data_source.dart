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
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';
import 'package:emergex/presentation/emergex_onboarding/model/upload_document_request.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

abstract class OnboardingOrganizationStructureRemoteDataSource {
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

class OnboardingOrganizationStructureRemoteDataSourceImpl
    implements OnboardingOrganizationStructureRemoteDataSource {
  final ApiClient _apiClient;

  OnboardingOrganizationStructureRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<OnboardingOrganizationStructure>> uploadDocument(
    UploadDocumentRequest request,
  ) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('projectId', request.projectId));
      formData.fields.add(MapEntry('section', request.sectionJson));
      request.section.forEach((categoryKey, fileList) {
        final fieldName = 'files[$categoryKey][]';
        formData.files.addAll(
          fileList.where((file) => file.existsSync()).map((file) {
            final fileName = file.path.split('/').last;
            final encodedFileName = Uri.encodeComponent(fileName);
            final mimeType =
                lookupMimeType(file.path) ?? 'application/octet-stream';
            return MapEntry(
              fieldName,
              MultipartFile.fromFileSync(
                file.path,
                filename: encodedFileName,
                contentType: MediaType.parse(mimeType),
              ),
            );
          }),
        );
      });
      return await _apiClient.request<OnboardingOrganizationStructure>(
        ApiEndpoints.uploadDoc,
        method: HttpMethod.post,
        data: formData,
        requiresProjectId: true,
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              return OnboardingOrganizationStructure.fromJson(data);
            } else if (json.containsKey('roles') ||
                json.containsKey('tasks') ||
                json.containsKey('users')) {
              // Direct response format
              return OnboardingOrganizationStructure.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Failed to upload document: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<OnboardingOrganizationStructure>>
  uploadDocumentWithPayload(Map<String, dynamic> payload) async {
    try {
      return await _apiClient.request<OnboardingOrganizationStructure>(
        ApiEndpoints.uploadDoc,
        method: HttpMethod.post,
        requiresProjectId: true,
        data: payload,
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              return OnboardingOrganizationStructure.fromJson(data);
            } else if (json.containsKey('roles') ||
                json.containsKey('tasks') ||
                json.containsKey('users')) {
              // Direct response format
              return OnboardingOrganizationStructure.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Failed to upload document: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<IncidentFileUploadResponse>>
  uploadOrganizationStructureFiles(
    List<File> files, {
    CancelToken? cancelToken,
  }) async {
    try {
      return await _apiClient.uploadMultipleFiles<IncidentFileUploadResponse>(
        ApiEndpoints.incidentFileUpload,
        fieldName: 'files',
        files: files,
        requiresAuth: true,
        requiresProjectId: true,
        cancelToken: cancelToken,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          // Handle response format: { "status": 200, "message": "Success", "data": [...] }
          if (json is Map<String, dynamic>) {
            if (json['data'] != null) {
              return IncidentFileUploadResponse.fromJson(json);
            } else if (json['status'] == 200 && json['data'] is List) {
              return IncidentFileUploadResponse.fromJson(json);
            } else {
              // If data is directly a list
              return IncidentFileUploadResponse.fromJson(json);
            }
          } else if (json is List) {
            // If response is directly a list
            return IncidentFileUploadResponse.fromJson(json);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
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
      return await _apiClient.request<CompleteOnboardingResponse>(
        ApiEndpoints.completeOnboarding,
        method: HttpMethod.post,
        requiresProjectId: true,
        requiresAuth: true,
        data: {'projectId': projectId},
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          // Handle response format: { "status": "success", "data": {...} }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              return CompleteOnboardingResponse.fromJson(data);
            } else if (json.containsKey('projectId')) {
              // Direct response format
              return CompleteOnboardingResponse.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
    } catch (e) {
      return ApiResponse<CompleteOnboardingResponse>.error(
        'Failed to complete onboarding: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<RoleDetailsResponse>> getRoleDetails(String roleId) async {
    try {
      final endpoint = ApiEndpoints.viewRoleDetails.replaceAll(
        '{roleId}',
        roleId,
      );
      return await _apiClient.request<RoleDetailsResponse>(
        endpoint,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          // Handle response format: { "status": "success", "data": {...} }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              return RoleDetailsResponse.fromJson(data);
            } else if (json.containsKey('roleDetails')) {
              // Direct response format
              return RoleDetailsResponse.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
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
      // Build request data with optional incidentId
      final Map<String, dynamic> requestData = {
        'projectId': projectId,
        'view': 'members',
      };

      // Add incidentId if provided (for add/reassign member operations)
      if (incidentId != null && incidentId.isNotEmpty) {
        requestData['incidentId'] = incidentId;
      }

      return await _apiClient.request<FetchMembersResponse>(
        ApiEndpoints.viewDetails,
        method: HttpMethod.post,
        requiresProjectId: true,
        requiresAuth: true,
        data: requestData,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          // Handle response format: { "status": "success", "data": {...} }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              // Adapt response: API returns 'users' but model expects 'members'
              final adaptedData = Map<String, dynamic>.from(data);
              if (data.containsKey('users') && !data.containsKey('members')) {
                adaptedData['members'] = data['users'];
                adaptedData['totalMembers'] =
                    (data['users'] as List?)?.length ?? 0;
              }
              return FetchMembersResponse.fromJson(adaptedData);
            } else if (json.containsKey('members')) {
              // Direct response format with 'members'
              return FetchMembersResponse.fromJson(json);
            } else if (json.containsKey('users')) {
              // Direct response format with 'users' - adapt to 'members'
              final adaptedData = Map<String, dynamic>.from(json);
              adaptedData['members'] = json['users'];
              adaptedData['totalMembers'] =
                  (json['users'] as List?)?.length ?? 0;
              return FetchMembersResponse.fromJson(adaptedData);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
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
      return await _apiClient.request<FetchRolesResponse>(
        ApiEndpoints.viewDetails,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'projectId': projectId, 'view': 'roles'},
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          // Handle response format: { "status": "success", "data": [...] }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              // Data is a list of roles, wrap it in the response format
              return FetchRolesResponse.fromJson(json);
            } else if (json.containsKey('roles') || json['data'] is List) {
              // Direct response format or data array
              return FetchRolesResponse.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
    } catch (e) {
      return ApiResponse<FetchRolesResponse>.error(
        'Failed to fetch roles: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<Role>> createRole(Map<String, dynamic> payload) async {
    try {
      return await _apiClient.request<Role>(
        ApiEndpoints.createRole,
        method: HttpMethod.post,
        requiresProjectId: true,
        data: payload,
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          // Handle response format: { "status": "success", "data": {...} }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              return Role.fromJson(data);
            } else if (json.containsKey('roleId') ||
                json.containsKey('role_id')) {
              // Direct response format
              return Role.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
    } catch (e) {
      return ApiResponse<Role>.error('Failed to create role: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<void>> deleteAssignedUser(
    String roleId,
    String userId,
  ) async {
    try {
      final payload = {'roleId': roleId, 'userId': userId};

      return await _apiClient.request<void>(
        ApiEndpoints.deleteAssignedUser,
        method: HttpMethod.delete,
        data: payload,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          // DELETE endpoint typically returns success message, no data to parse
          return;
        },
      );
    } catch (e) {
      return ApiResponse<void>.error(
        'Failed to delete assigned user: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<void>> deleteRole(String roleId, String projectId) async {
    try {
      final payload = {'roleId': roleId, 'projectId': projectId};

      return await _apiClient.request<void>(
        ApiEndpoints.deleteRole,
        method: HttpMethod.delete,
        data: payload,
        requiresProjectId: true,
        requiresAuth: true,
        fromJson: (json) {
          // DELETE endpoint typically returns success message, no data to parse
          return;
        },
      );
    } catch (e) {
      return ApiResponse<void>.error('Failed to delete role: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<ViewDetailsResponse>> viewDetails(
    String projectId,
    String view,
  ) async {
    try {
      return await _apiClient.request<ViewDetailsResponse>(
        ApiEndpoints.viewDetails,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'projectId': projectId, 'view': view},
        fromJson: (json) {
          if (json == null) {
            // Return empty response if json is null
            return const ViewDetailsResponse();
          }
          // Handle response format: { "status": "success", "data": {...} }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success') {
              if (json['data'] != null) {
                final data = json['data'] as Map<String, dynamic>;
                return ViewDetailsResponse.fromJson(data);
              } else {
                // Success but data is null - return empty response
                return const ViewDetailsResponse();
              }
            } else if (json.containsKey('projectId') ||
                json.containsKey('_id')) {
              // Direct response format
              return ViewDetailsResponse.fromJson(json);
            } else {
              // Invalid format but don't throw - return empty response
              return const ViewDetailsResponse();
            }
          } else {
            // Not a valid JSON object - return empty response
            return const ViewDetailsResponse();
          }
        },
      );
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
      return await _apiClient.request<ModulesAndFeaturesResponse>(
        ApiEndpoints.viewModulesPermissions,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        // data: {'projectId': projectId},
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          // Handle response format: { "status": "success", "data": [...] }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              return ModulesAndFeaturesResponse.fromJson(json);
            } else if (json['data'] is List) {
              // Direct response format with data array
              return ModulesAndFeaturesResponse.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else if (json is List) {
            // If response is directly a list
            return ModulesAndFeaturesResponse.fromJson({'data': json});
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
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
      return await _apiClient.request<OnboardingOrganizationStructure>(
        ApiEndpoints.uploadDocs,
        method: HttpMethod.post,
        requiresProjectId: true,
        data: payload,
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              final data = json['data'] as Map<String, dynamic>;
              return OnboardingOrganizationStructure.fromJson(data);
            } else if (json.containsKey('roles') ||
                json.containsKey('tasks') ||
                json.containsKey('users')) {
              // Direct response format
              return OnboardingOrganizationStructure.fromJson(json);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
    } catch (e) {
      return ApiResponse<OnboardingOrganizationStructure>.error(
        'Failed to upload documents for all projects: ${e.toString()}',
      );
    }
  }
}
