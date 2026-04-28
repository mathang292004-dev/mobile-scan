import 'dart:convert';

import 'package:emergex/data/model/api_response.dart';

/// Safely extracts a human-readable message from a JSON response body.
/// The API may return `message` as a String or as a List<String> for
/// validation errors. Joining the list produces a clean user-facing message.

import 'package:emergex/data/model/user_management/add_bulk_users_request.dart';
import 'package:emergex/data/model/user_management/add_bulk_users_response.dart';
import 'package:emergex/data/model/user_management/add_user_request.dart';
import 'package:emergex/data/model/user_management/add_user_response.dart';
import 'package:emergex/data/model/user_management/get_users_request.dart';
import 'package:emergex/data/model/user_management/get_users_response.dart';
import 'package:emergex/data/model/user_management/validate_csv_request.dart';
import 'package:emergex/data/model/user_management/validate_csv_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

abstract class UserManagementRemoteDataSource {
  Future<ApiResponse<AddUserResponse>> addUser(AddUserRequest request);

  Future<ApiResponse<GetUsersResponse>> getUsers(GetUsersRequest request);

  Future<ApiResponse<void>> deleteUser({required String userId});

  Future<ApiResponse<ValidateCsvResponse>> validateCsvUsers(
    ValidateCsvRequest request,
  );

  Future<ApiResponse<AddBulkUsersResponse>> addBulkUsers(
    AddBulkUsersRequest request,
  );
}
String _extractMessage(dynamic raw, String fallback) {
  if (raw == null) return fallback;
  if (raw is List) return raw.join(' ');
  return raw.toString();
}
class UserManagementRemoteDataSourceImpl
    implements UserManagementRemoteDataSource {
  final ApiClient _apiClient;

  UserManagementRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<AddUserResponse>> addUser(AddUserRequest request) async {
    try {
      return await _apiClient.uploadFile<AddUserResponse>(
        ApiEndpoints.addUser,
        fieldName: 'profile',
        file: request.profileImage,
        additionalData: request.toFormData(),
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json is Map<String, dynamic> &&
              json['status'] == 'success' &&
              json['data'] != null) {
            return AddUserResponse.fromJson(
              json['data'] as Map<String, dynamic>,
            );
          }
          throw Exception(
            json is Map
                ? _extractMessage(json['message'], 'Failed to add user')
                : 'Invalid response',
          );
        },
      );
    } catch (e) {
      return ApiResponse<AddUserResponse>.error(
        'Failed to add user: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<GetUsersResponse>> getUsers(
    GetUsersRequest request,
  ) async {
    try {
      final filterJson = jsonEncode(request.toJson());

      return await _apiClient.request<GetUsersResponse>(
        ApiEndpoints.getUsers,
        method: HttpMethod.get,
        queryParameters: {'filter': filterJson},
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json is Map<String, dynamic> && json['status'] == 'success') {
            return GetUsersResponse.fromJson(json);
          }
          throw Exception(
            json is Map
                ? _extractMessage(json['message'], 'Failed to fetch users')
                : 'Invalid response',
          );
        },
      );
    } catch (e) {
      return ApiResponse<GetUsersResponse>.error(
        'Failed to fetch users: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<void>> deleteUser({required String userId}) async {
    try {
      return await _apiClient.request<void>(
        ApiEndpoints.deleteUser(userId),
        method: HttpMethod.delete,
        requiresAuth: true,
        fromJson: (_) => null,
      );
    } catch (e) {
      return ApiResponse<void>.error(
        'Failed to delete user: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<ValidateCsvResponse>> validateCsvUsers(
    ValidateCsvRequest request,
  ) async {
    try {
      return await _apiClient.uploadFile<ValidateCsvResponse>(
        ApiEndpoints.validateCsvUsers,
        fieldName: 'file',
        file: request.file,
        additionalData: {'clientId': request.clientId},
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json is Map<String, dynamic> && json['status'] == 'success') {
            return ValidateCsvResponse.fromJson(json);
          }
          throw Exception(
            json is Map
                ? _extractMessage(json['message'], 'CSV validation failed')
                : 'Invalid response',
          );
        },
      );
    } catch (e) {
      return ApiResponse<ValidateCsvResponse>.error(
        'CSV validation failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<AddBulkUsersResponse>> addBulkUsers(
    AddBulkUsersRequest request,
  ) async {
    try {
      return await _apiClient.request<AddBulkUsersResponse>(
        ApiEndpoints.addBulkUsers,
        method: HttpMethod.post,
        data: request.toJson(),
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) throw Exception('Response is null');
          if (json is Map<String, dynamic> && json['status'] == 'success') {
            return AddBulkUsersResponse.fromJson(json);
          }
          throw Exception(
            json is Map
                ? _extractMessage(json['message'], 'Failed to add bulk users')
                : 'Invalid response',
          );
        },
      );
    } catch (e) {
      return ApiResponse<AddBulkUsersResponse>.error(
        'Failed to add bulk users: ${e.toString()}',
      );
    }
  }
}
