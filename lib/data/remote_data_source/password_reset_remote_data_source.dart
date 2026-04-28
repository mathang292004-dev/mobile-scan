import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/domain/api/api_client.dart';
import 'package:emergex/domain/api/api_endpoint.dart';

abstract class PasswordResetRemoteDataSource {
  Future<ApiResponse<void>> sendOtp(String email);
  Future<ApiResponse<String>> verifyOtp(String email, String otp);
  Future<ApiResponse<void>> updatePassword(
    String resetToken,
    String newPassword,
  );
}

class PasswordResetRemoteDataSourceImpl implements PasswordResetRemoteDataSource {
  final ApiClient _apiClient;

  PasswordResetRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ApiResponse<void>> sendOtp(String email) async {
    try {
      await _apiClient.request<void>(
        ApiEndpoints.sendOtp,
        method: HttpMethod.post,
        requiresAuth: false,
        data: {'email': email},
        fromJson: (json) {
          if (json == null || json['status'] != 'success') {
            throw Exception(json?['message'] ?? 'Failed to send OTP');
          }
        },
      );
      return ApiResponse<void>(success: true, data: null);
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        data: null,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<ApiResponse<String>> verifyOtp(String email, String otp) async {
    try {
      String? resetToken;
      await _apiClient.request<String>(
        ApiEndpoints.verifyOtp,
        method: HttpMethod.post,
        requiresAuth: false,
        data: {'email': email, 'otp': otp},
        fromJson: (json) {
          if (json == null || json['status'] != 'success') {
            throw Exception(json?['message'] ?? 'OTP verification failed');
          }
          final data = json['data'];
          if (data == null || data['resetToken'] == null) {
            throw Exception('Reset token not received');
          }
          resetToken = data['resetToken'] as String;
          return resetToken;
        },
      );
      return ApiResponse<String>(success: true, data: resetToken);
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        data: null,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Future<ApiResponse<void>> updatePassword(
    String resetToken,
    String newPassword,
  ) async {
    try {
      await _apiClient.request<void>(
        ApiEndpoints.updatePassword,
        method: HttpMethod.post,
        requiresAuth: false,
        data: {'resetToken': resetToken, 'newPassword': newPassword},
        fromJson: (json) {
          if (json == null || json['status'] != 'success') {
            throw Exception(json?['message'] ?? 'Failed to update password');
          }
        },
      );
      return ApiResponse<void>(success: true, data: null);
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        data: null,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
