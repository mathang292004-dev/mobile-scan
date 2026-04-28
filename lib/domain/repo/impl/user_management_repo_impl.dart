import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/user_management/add_bulk_users_request.dart';
import 'package:emergex/data/model/user_management/add_bulk_users_response.dart';
import 'package:emergex/data/model/user_management/add_user_request.dart';
import 'package:emergex/data/model/user_management/add_user_response.dart';
import 'package:emergex/data/model/user_management/get_users_request.dart';
import 'package:emergex/data/model/user_management/get_users_response.dart';
import 'package:emergex/data/model/user_management/validate_csv_request.dart';
import 'package:emergex/data/model/user_management/validate_csv_response.dart';
import 'package:emergex/data/remote_data_source/user_management_remote_data_source.dart';
import 'package:emergex/domain/repo/user_management_repo.dart';

class UserManagementRepoImpl implements UserManagementRepo {
  final UserManagementRemoteDataSource _remoteDataSource;

  UserManagementRepoImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<AddUserResponse>> addUser(AddUserRequest request) async {
    try {
      return await _remoteDataSource.addUser(request);
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
      return await _remoteDataSource.getUsers(request);
    } catch (e) {
      return ApiResponse<GetUsersResponse>.error(
        'Failed to fetch users: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<void>> deleteUser({required String userId}) async {
    try {
      return await _remoteDataSource.deleteUser(userId: userId);
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
      return await _remoteDataSource.validateCsvUsers(request);
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
      return await _remoteDataSource.addBulkUsers(request);
    } catch (e) {
      return ApiResponse<AddBulkUsersResponse>.error(
        'Failed to add bulk users: ${e.toString()}',
      );
    }
  }
}
