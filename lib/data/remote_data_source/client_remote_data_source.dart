import 'dart:convert';

import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/client_management/client_response.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_request.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

abstract class ClientRemoteDataSource {
  Future<ApiResponse<ClientResponse>> getClients({
    ClientFilterRequest? filters,
  });

  Future<ApiResponse<Client>> addClient(ClientRequest request);

  Future<ApiResponse<UpdateClientResponse>> updateClient(ClientRequest request);

  Future<ApiResponse<DeleteClientResponse>> deleteClient(String clientId);
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final ApiClient _apiClient;

  ClientRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<ClientResponse>> getClients({
    ClientFilterRequest? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      // Add filters as JSON stringified and URL encoded query parameter
      if (filters != null) {
        final filtersJson = filters.toJson();
        queryParams['filters'] = Uri.encodeComponent(jsonEncode(filtersJson));
      }

      return await _apiClient.request<ClientResponse>(
        ApiEndpoints.getClients,
        method: HttpMethod.get,
        requiresProjectId: true,
        requiresAuth: true,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return ClientResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<ClientResponse>.error(
        'Failed to get clients: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<Client>> addClient(ClientRequest request) async {
    try {
      return await _apiClient.uploadFile<Client>(
        ApiEndpoints.addClient,
        fieldName: 'profile',
        file: request.profileFile,
        additionalData: {
          'clientName': request.clientName ?? '',
          'clientId': request.clientId ?? '',
          'email': request.email ?? '',
          'industry': request.industry ?? '',
          'location': request.location ?? '',
        },
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return Client.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<Client>.error('Failed to add client: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<UpdateClientResponse>> updateClient(
    ClientRequest request,
  ) async {
    try {
      return await _apiClient.uploadFile<UpdateClientResponse>(
        ApiEndpoints.updateClient,
        fieldName: 'profile',
        requiresProjectId: true,
        file: request.profileFile,
        additionalData: {
          'clientName': request.clientName ?? '',
          'clientId': request.clientId ?? '',
          'email': request.email ?? '',
          'industry': request.industry ?? '',
          'location': request.location ?? '',
          if (request.status != null && request.status!.isNotEmpty)
            'status': request.status!,
          if (request.deleteImage) 'profile': '',
        },
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return UpdateClientResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<UpdateClientResponse>.error(
        'Failed to update client: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<DeleteClientResponse>> deleteClient(
    String clientId,
  ) async {
    try {
      final endpoint = ApiEndpoints.deleteClient.replaceAll(
        '{clientId}',
        clientId,
      );

      return await _apiClient.request<DeleteClientResponse>(
        endpoint,
        method: HttpMethod.delete,
        requiresAuth: true,
        requiresProjectId: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('Response is null');
          }
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            final data = json['data'] as Map<String, dynamic>;
            return DeleteClientResponse.fromJson(data);
          } else {
            throw Exception('Invalid response format from server');
          }
        },
      );
    } catch (e) {
      return ApiResponse<DeleteClientResponse>.error(
        'Failed to delete client: ${e.toString()}',
      );
    }
  }
}
