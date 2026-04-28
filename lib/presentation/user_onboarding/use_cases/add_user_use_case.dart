import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/user_management/add_user_request.dart';
import 'package:emergex/data/model/user_management/add_user_response.dart';
import 'package:emergex/domain/repo/user_management_repo.dart';

class AddUserUseCase {
  final UserManagementRepo _repo;

  AddUserUseCase(this._repo);

  Future<ApiResponse<AddUserResponse>> execute(AddUserRequest request) {
    return _repo.addUser(request);
  }
}
