import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/domain/repo/login_repo.dart';
import 'package:emergex/presentation/onboarding/model/reset_password_request_model.dart';

class ResetPasswordAuthUseCase {
  final LoginRepository _repository;

  ResetPasswordAuthUseCase(this._repository);

  Future<ApiResponse<void>> execute(ResetPasswordRequestModel request) async {
    try {
      return await _repository.resetPassword(request);
    } catch (e) {
      return ApiResponse<void>.error(e.toString());
    }
  }
}
