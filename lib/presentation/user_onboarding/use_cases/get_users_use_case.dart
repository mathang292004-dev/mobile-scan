import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/user_management/get_users_request.dart';
import 'package:emergex/data/model/user_management/get_users_response.dart';
import 'package:emergex/domain/repo/user_management_repo.dart';

class GetUsersUseCase {
  final UserManagementRepo _repo;

  GetUsersUseCase(this._repo);

  Future<ApiResponse<GetUsersResponse>> execute(GetUsersRequest request) {
    return _repo.getUsers(request);
  }
}
