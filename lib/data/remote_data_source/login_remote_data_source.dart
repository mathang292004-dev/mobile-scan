import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/onboarding/user_profile.dart';
import 'package:emergex/data/model/user_role_permission/user_permissions_response.dart';
import 'package:emergex/presentation/onboarding/model/reset_password_request_model.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';
import 'package:emergex/helpers/preference_helper.dart';

abstract class LoginRemoteDataSource {
  Future<ApiResponse<LoginUser>> login(LoginUser user);
  Future<ApiResponse<UserPermissionsResponse>> getUserPermissions();
  Future<ApiResponse<UserPermissionsResponse>> getUserPermissionsByProject(String projectId);
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequestModel request);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final ApiClient _apiClient;
  final PreferenceHelper _preferenceHelper;

  LoginRemoteDataSourceImpl(this._apiClient, this._preferenceHelper);
  @override
  Future<ApiResponse<LoginUser>> login(LoginUser user) async {
 
    try {
      final response = await _apiClient.request<LoginUser>(
        ApiEndpoints.login,
        method: HttpMethod.post,
        data: {
          'email': user.email,
          'password': user.password,
          'rememberMe': user.rememberMe,
        },
        fromJson: (json) async {
          if (json == null) {
            throw Exception('Invalid email or password');
          }

          if (json['status'] == 'success' && json['data'] != null) {
            final userData = json['data'] as Map<String, dynamic>;
            if (userData['accessToken'] != null) {
              await _preferenceHelper.setUserToken(userData['accessToken']);
            }
            if (userData['refreshToken'] != null) {
              await _preferenceHelper.setRefreshToken(userData['refreshToken']);
            }
          } else {
            String errorMessage = json['message'] ?? 'Login failed';
            throw Exception(errorMessage);
          }
        },
      );
      return response;
    } catch (e) {
      return ApiResponse<LoginUser>(
        success: false,
        data: null,
        message: e.toString(),
      );
    }
  }

  @override
  Future<ApiResponse<UserPermissionsResponse>> getUserPermissions() async {
    try {
      final response = await _apiClient.request<UserPermissionsResponse>(
        ApiEndpoints.me,
        method: HttpMethod.get,
        requiresAuth: true,
        fromJson: (json) {
          if (json == null) {
            throw Exception('User permissions not found');
          }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              return UserPermissionsResponse.fromJson(json['data'] as Map<String, dynamic>);
            } else if (json['data'] != null) {
              return UserPermissionsResponse.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
      return response;
    } catch (e) {
      return ApiResponse<UserPermissionsResponse>.error(
        'Failed to fetch user permissions: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UserPermissionsResponse>> getUserPermissionsByProject(String projectId) async {
    try {
      final response = await _apiClient.request<UserPermissionsResponse>(
        ApiEndpoints.getPermissions,
        method: HttpMethod.get,
        requiresAuth: true,
        headers: {'x-project-id': projectId},
        fromJson: (json) {
          if (json == null) {
            throw Exception('User permissions not found');
          }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success' && json['data'] != null) {
              return UserPermissionsResponse.fromJson(json['data'] as Map<String, dynamic>);
            } else if (json['data'] != null) {
              return UserPermissionsResponse.fromJson(json['data'] as Map<String, dynamic>);
            } else {
              throw Exception('Invalid response format from server');
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
      return response;
    } catch (e) {
      return ApiResponse<UserPermissionsResponse>.error(
        'Failed to fetch user permissions: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequestModel request) async {
    try {
      final response = await _apiClient.request<void>(
        ApiEndpoints.resetPassword,
        method: HttpMethod.post,
        requiresAuth: true,
        data: request.toJson(),
        fromJson: (json) {
          if (json == null) {
            throw Exception('Reset password failed');
          }
          if (json is Map<String, dynamic>) {
            if (json['status'] == 'success') {
              return;
            } else {
              String errorMessage = json['message'] ?? 'Reset password failed';
              throw Exception(errorMessage);
            }
          } else {
            throw Exception('Response is not a valid JSON object');
          }
        },
      );
      return response;
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }
}
