import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/onboarding/user_profile.dart';
import 'package:emergex/data/remote_data_source/login_remote_data_source.dart';
import 'package:emergex/domain/repo/login_repo.dart';
import 'package:emergex/presentation/onboarding/model/reset_password_request_model.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource _remoteDataSource;

  LoginRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<LoginUser>> login(LoginUser user) async {
    try {
      return await _remoteDataSource.login(user);
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
  }

  @override
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequestModel request) async {
    try {
      return await _remoteDataSource.resetPassword(request);
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
  }
}
