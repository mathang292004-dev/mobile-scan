import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/incident/audit_log_response.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';
import 'package:emergex/presentation/case_report/model/ai_summary_details.dart';
import 'package:uuid/uuid.dart';

import '../../presentation/case_report/approver/model/team_members_data_model.dart';
import '../../presentation/case_report/approver/model/reassign_eligible_users_model.dart';
import 'package:emergex/data/model/incident/preliminary_report_model.dart';

abstract class IncidentRemoteDataSource {
  Future<ApiResponse<IncidentDetails>> createIncidentFileByPath(
    String? filePath,
    String? incidentText,
    String? incidentInformations,
    String? projectId,
    AiSummaryResponse? aiSummaryResponse, {
    List<String>? immediateActionsTaken,
  });
  Future<ApiResponse> deleteFileFromServer(
    String publicId,
    String fileType,
    bool? isCancel,
  );
  Future<ApiResponse<IncidentDetails>> updateIncident(
    String incidentId,
    String? filePath,
    String? incidentText,
    String? incidentInformations,
    String? uuInfoId,
    String? projectId,
    AiSummaryResponse? aiSummaryResponse, {
    CancelToken? cancelToken,
    List<String>? immediateActionsTaken,
  });
  Future<ApiResponse<IncidentDetails>> getIncidentById(String incidentId);

  Future<ApiResponse<TeamMembersData>> fetchTeamMembers(
    String projectId, {
    String? incidentId,
  });

  Future<ApiResponse> removeMemberTask(String incidentId, String roleId);

  Future<ApiResponse> addTaskToMember({
    required String caseId,
    required String userId,
    required String type,
    required String role,
    required List<String> selectedLibraryTaskIds,
    List<ManualTaskEntry> manualTasks = const [],
  });

  Future<ApiResponse<IncidentDetails>> reportIncident(String incidentId);
  Future<ApiResponse> deleteIncident(String incidentId);
  Future<ApiResponse<IncidentDetails>> updateIncidentApproval(
    String incidentId,
    String type,
  );
  Future<ApiResponse<IncidentDetails>> incidentApproval(
    String incidentId,
    String type,
  );
  Future<ApiResponse<dynamic>> submitSetup(String incidentId, String type);
  Future<ApiResponse<String>> preSignedUrl(String key);
  Future<ApiResponse<IncidentDetails>> updateReportFields(
    Map<String, dynamic> payload,
  );
  Future<ApiResponse<IncidentDetails>> updateMembers(
    String incidentId,
    List<Map<String, dynamic>> members,
  );
  Future<ApiResponse<AuditLogResponse>> getAuditLogs(String incidentId);

  Future<ApiResponse<ReassignEligibleUsersResponse>> getEligibleUsers({
    required String clientId,
    required String type,
    required String role,
    required String caseId,
  });

  Future<ApiResponse<PreliminaryReportData>> getPreliminaryReport(
    String incidentId,
  );

  Future<ApiResponse<PreliminaryReportData>> updatePreliminaryReport(
    String incidentId,
    String tab,
    Map<String, dynamic> data,
  );

  Future<ApiResponse<String>> exportPreliminaryReportPdf(String incidentId);
}

class IncidentRemoteDataSourceImpl implements IncidentRemoteDataSource {
  final ApiClient _apiClient;

  IncidentRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<IncidentDetails>> createIncidentFileByPath(
    String? filePath,
    String? incidentText,
    String? incidentInformations,
    String? projectId,
    AiSummaryResponse? aiSummaryResponse, {
    List<String>? immediateActionsTaken,
  }) async {
    try {
      var uuid = Uuid();
      String v1Id = uuid.v1();
      return await _apiClient.uploadFile<IncidentDetails>(
        ApiEndpoints.createIncident,
        file: filePath != null ? File(filePath) : null,
        requiresAuth: true,
        requiresProjectId: true,
        fieldName: 'file',
        additionalData: {
          'emergeXCaseInformation': incidentInformations,
          'infoId': v1Id,
          if (projectId != null) 'projectId': projectId,
          'questions': aiSummaryResponse != null
              ? json.encode(aiSummaryResponse.toJson())
              : null,
          if (immediateActionsTaken != null && immediateActionsTaken.isNotEmpty)
            'immediateActionsTaken': immediateActionsTaken,
        },
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'] ?? json;
          return IncidentDetails.fromJson(data);
        },
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateIncident(
    String incidentId,
    String? filePath,
    String? incidentText,
    String? incidentInformations,
    String? uuInfoId,
    String? projectId,
    AiSummaryResponse? aiSummaryResponse, {
    CancelToken? cancelToken,
    List<String>? immediateActionsTaken,
  }) async {
    try {
      final additionalData = {
        'caseId': incidentId,
        'emergeXCaseInformation': incidentInformations,
        'infoId': uuInfoId,
        if (projectId != null) 'projectId': projectId,
        'questions': aiSummaryResponse != null
            ? json.encode(aiSummaryResponse.toJson())
            : null,
        if (immediateActionsTaken != null && immediateActionsTaken.isNotEmpty)
          'immediateActionsTaken': immediateActionsTaken,
      };
      return await _apiClient.uploadFile<IncidentDetails>(
        ApiEndpoints.updateIncident,
        file: filePath != null ? File(filePath) : null,
        requiresAuth: true,
        requiresProjectId: true,
        fieldName: 'files',
        additionalData: additionalData,
        cancelToken: cancelToken,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'] ?? json;
          return IncidentDetails.fromJson(data);
        },
      );
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
  }

  @override
  Future<ApiResponse> deleteFileFromServer(
    String publicId,
    String fileType,
    bool? isCancel,
  ) async {
    try {
      String? incidentId;
      final fileHandleData = AppDI.incidentFileHandleCubit.state.data;
      if (fileHandleData.isNotEmpty) {
        incidentId = fileHandleData.first.incidentId;
      } else {
        final detailsState = AppDI.incidentDetailsCubit.state;
        if (detailsState is IncidentDetailsLoaded) {
          incidentId = detailsState.incident.incidentId;
        }
      }
      return await _apiClient.request(
        ApiEndpoints.deleteFileFromServer,
        requiresAuth: true,
        requiresProjectId: true,
        method: HttpMethod.delete,
        data: {
          'infoId': publicId,
          'type': fileType,
          'isCancel': isCancel ?? false,
          'caseId': incidentId,
        },
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }

          if (json['status'] == 'success') {
            return {
              'success': true,
              'message': json['message'] ?? 'File deleted successfully',
              'data': json['data'],
            };
          } else {
            String errorMessage = json['message'] ?? 'Failed to delete file';
            throw Exception(errorMessage);
          }
        },
      );
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> getIncidentById(
    String incidentId,
  ) async {
    try {
      final url = ApiEndpoints.getIncidentById.replaceAll('{id}', incidentId);

      final response = await _apiClient.request<IncidentDetails>(
        url,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map && json.containsKey('data')) {
            if (json['data'] == null) {
              throw Exception('Incident data is null');
            }
            return IncidentDetails.fromJson(json['data']);
          } else {
            return IncidentDetails.fromJson(json);
          }
        },
      );

      if (response.data == null) {
        return ApiResponse.error(
          'Failed to parse incident data: response data is null',
        );
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get incident by id: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<TeamMembersData>> fetchTeamMembers(
    String projectId, {
    String? incidentId,
  }) async {
    try {
      final response = await _apiClient.request<TeamMembersData>(
        ApiEndpoints.fetchTeamMembers,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {
          'projectId': projectId,
          'view': 'members',
          if (incidentId != null) 'incidentId': incidentId,
        },
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }

          if (json['status'] == 'success' && json['data'] != null) {
            final innerData = json['data'];
            if (innerData != null) {
              // Adapt new response structure to existing model
              // New API returns: { users: [...], tasks: { ertTasks: [...] } }
              // Existing model expects: { userDetails: [...], task: [...] }
              final users = innerData['users'] as List? ?? [];
              final rawTasks = innerData['tasks'];
              final List tasks = rawTasks is List
                  ? rawTasks
                  : rawTasks is Map
                      ? (rawTasks['ertTasks'] as List? ?? [])
                      : [];

              final adaptedData = {
                'userDetails': users.map((user) {
                  return {
                    'roleId': user['userId'] ?? '',
                    'roleName': '', // Not provided in new API
                    'name': user['name'] ?? '',
                    'email': user['email'] ?? '',
                    'phone': {'desk_ph': [], 'mobile_ph': []},
                  };
                }).toList(),
                'task': tasks.map((task) {
                  return {
                    'taskId': task['taskId'] ?? '',
                    'short': task['taskName'] ?? '',
                    'long': task['taskDetails'] ?? task['taskName'] ?? '',
                  };
                }).toList(),
              };
              return TeamMembersData.fromJson(adaptedData);
            }
          }

          throw Exception('Invalid response format');
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch team members: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse> removeMemberTask(String incidentId, String roleId) async {
    try {
      final response = await _apiClient.request(
        ApiEndpoints.removeMemberTask,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'incidentId': incidentId, 'userId': roleId},
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }

          if (json['status'] == 'success') {
            return {
              'success': true,
              'message': json['message'] ?? 'Member removed successfully',
              'data': json['data'],
            };
          } else {
            String errorMessage = json['message'] ?? 'Failed to remove member';
            throw Exception(errorMessage);
          }
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to remove member task: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse> addTaskToMember({
    required String caseId,
    required String userId,
    required String type,
    required String role,
    required List<String> selectedLibraryTaskIds,
    List<ManualTaskEntry> manualTasks = const [],
  }) async {
    try {
      final data = <String, dynamic>{
        'caseId': caseId,
        'userId': userId,
        'type': type,
        'role': role,
        'selectedLibraryTaskIds': selectedLibraryTaskIds,
      };
      if (manualTasks.isNotEmpty) {
        data['manualTasks'] = manualTasks
            .map((m) => {'taskTitle': m.taskTitle, 'taskDetails': m.taskDetails})
            .toList();
      }

      final response = await _apiClient.request(
        ApiEndpoints.addTaskToMember,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: data,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json['status'] == 'success') {
            return {
              'success': true,
              'message': json['message'] ?? 'Task(s) added successfully',
              'data': json['assignedTasks'],
            };
          } else {
            throw Exception(json['message'] ?? 'Failed to add task');
          }
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to add task to member: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> reportIncident(String incidentId) async {
    try {
      return await _apiClient.request(
        ApiEndpoints.reportIncident,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'caseId': incidentId},
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'] ?? json;
          return IncidentDetails.fromJson(data);
        },
      );
    } catch (e) {
      return ApiResponse.error('Failed to report incident: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse> deleteIncident(String incidentId) async {
    try {
      final url = ApiEndpoints.deleteIncident.replaceAll('{id}', incidentId);
      return await _apiClient.request(
        url,
        method: HttpMethod.delete,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'caseId': incidentId},
      );
    } catch (e) {
      return ApiResponse.error('Failed to delete incident: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<String>> preSignedUrl(String key) async {
    try {
      final response = await _apiClient.request<String>(
        ApiEndpoints.preSignedUrl,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'key': key},
        fromJson: (json) {
          if (json == null || json['data'] == null) {
            throw Exception('Invalid response format');
          }
          return json['data']['preSignedUrl'] as String;
        },
      );

      return response; // ✅ already wrapped in ApiResponse<String>
    } catch (e) {
      return ApiResponse.error('Failed to get preSignedUrl: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateIncidentApproval(
    String incidentId,
    String type,
  ) async {
    try {
      final response = await _apiClient.request<IncidentDetails>(
        ApiEndpoints.updateReport,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'incidentId': incidentId, 'type': type},
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'] ?? json;
          return IncidentDetails.fromJson(data);
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> incidentApproval(
    String incidentId,
    String type,
  ) async {
    try {
      final response = await _apiClient.request<IncidentDetails>(
        ApiEndpoints.incidentApproval,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'caseId': incidentId, 'type': type},
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'] ?? json;
          return IncidentDetails.fromJson(data);
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<dynamic>> submitSetup(
    String incidentId,
    String type,
  ) async {
    try {
      final response = await _apiClient.request<dynamic>(
        ApiEndpoints.submitSetup,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'caseId': incidentId, 'type': type},
        fromJson: (json) => json,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateReportFields(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiClient.request<IncidentDetails>(
        ApiEndpoints.updateReportFields,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: payload,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'] ?? json;
          return IncidentDetails.fromJson(data);
        },
      );
      return response;
    } catch (e) {
      // Extract statusCode if available from DioException
      int? statusCode;
      if (e is DioException && e.response != null) {
        statusCode = e.response?.statusCode;
      }
      return ApiResponse.error(e.toString(), statusCode: statusCode);
    }
  }

  @override
  Future<ApiResponse<IncidentDetails>> updateMembers(
    String incidentId,
    List<Map<String, dynamic>> members,
  ) async {
    try {
      final response = await _apiClient.request<IncidentDetails>(
        ApiEndpoints.updateMembers,
        method: HttpMethod.post,
        requiresAuth: true,
        requiresProjectId: true,
        data: {
          'caseId': incidentId,
          'members': members,
        },
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'] ?? json;
          return IncidentDetails.fromJson(data);
        },
      );
      return response;
    } catch (e) {
      // Extract statusCode if available from DioException
      int? statusCode;
      if (e is DioException && e.response != null) {
        statusCode = e.response?.statusCode;
      }
      return ApiResponse.error(e.toString(), statusCode: statusCode);
    }
  }

  @override
  Future<ApiResponse<AuditLogResponse>> getAuditLogs(String incidentId) async {
    try {
      final url =
          ApiEndpoints.getAuditLogs.replaceAll('{incidentId}', incidentId);
      return await _apiClient.request<AuditLogResponse>(
        url,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          final data = json['data'];
          if (data == null) {
            throw Exception('Data is null');
          }
          return AuditLogResponse.fromJson(data);
        },
      );
    } catch (e) {
      return ApiResponse.error('Failed to fetch audit logs: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<PreliminaryReportData>> getPreliminaryReport(
    String incidentId,
  ) async {
    try {
      final url = ApiEndpoints.getPreliminaryReport
          .replaceAll('{incidentId}', incidentId);
      return await _apiClient.request<PreliminaryReportData>(
        url,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          final data = json['data'] as Map<String, dynamic>?;
          if (data == null) throw Exception('Data is null');
          return PreliminaryReportData.fromJson(data);
        },
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to fetch preliminary report: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<PreliminaryReportData>> updatePreliminaryReport(
    String incidentId,
    String tab,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = ApiEndpoints.updatePreliminaryReport
          .replaceAll('{incidentId}', incidentId);
      return await _apiClient.request<PreliminaryReportData>(
        url,
        method: HttpMethod.patch,
        requiresAuth: true,
        requiresProjectId: true,
        data: {'tab': tab, 'data': data},
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          final responseData = json['data'] as Map<String, dynamic>?;
          if (responseData == null) throw Exception('Data is null');
          return PreliminaryReportData.fromJson(responseData);
        },
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to save preliminary report: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<String>> exportPreliminaryReportPdf(
    String incidentId,
  ) async {
    try {
      final url = ApiEndpoints.exportPreliminaryReportPdf
          .replaceAll('{incidentId}', incidentId);
      return await _apiClient.request<String>(
        url,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          final pdfUrl = json['data']?['pdfUrl']?.toString();
          if (pdfUrl == null || pdfUrl.isEmpty) {
            throw Exception('PDF URL not found in response');
          }
          return pdfUrl;
        },
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to export preliminary report PDF: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<ReassignEligibleUsersResponse>> getEligibleUsers({
    required String clientId,
    required String type,
    required String role,
    required String caseId,
  }) async {
    try {
      return await _apiClient.request<ReassignEligibleUsersResponse>(
        ApiEndpoints.reassignEligibleUsers,
        method: HttpMethod.get,
        requiresAuth: true,
        requiresProjectId: true,
        queryParameters: {
          'clientId': clientId,
          'type': type,
          'role': role,
          'caseId': caseId,
        },
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json['status'] == 'success' && json['data'] != null) {
            return ReassignEligibleUsersResponse.fromJson(
              json['data'] as Map<String, dynamic>,
            );
          }
          throw Exception(
            json['message']?.toString() ?? 'Failed to fetch eligible users',
          );
        },
      );
    } catch (e) {
      return ApiResponse.error(
        'Failed to fetch eligible users: ${e.toString()}',
      );
    }
  }
}
