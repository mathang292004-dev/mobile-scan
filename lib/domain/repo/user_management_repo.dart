import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/user_management/add_bulk_users_request.dart';
import 'package:emergex/data/model/user_management/add_bulk_users_response.dart';
import 'package:emergex/data/model/user_management/add_user_request.dart';
import 'package:emergex/data/model/user_management/add_user_response.dart';
import 'package:emergex/data/model/user_management/get_users_request.dart';
import 'package:emergex/data/model/user_management/get_users_response.dart';
import 'package:emergex/data/model/user_management/validate_csv_request.dart';
import 'package:emergex/data/model/user_management/validate_csv_response.dart';

abstract class UserManagementRepo {
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
