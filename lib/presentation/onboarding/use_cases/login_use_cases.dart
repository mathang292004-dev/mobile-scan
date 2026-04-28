import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/onboarding/user_profile.dart';
import 'package:emergex/domain/repo/login_repo.dart';

class LoginUseCase {
  final LoginRepository _loginRepository;

  LoginUseCase(this._loginRepository);

  Future<ApiResponse<LoginUser>> login(LoginUser user) async {
    try {
      return await _loginRepository.login(user);
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
  }
}
