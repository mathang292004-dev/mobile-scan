import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/onboarding/user_profile.dart';
import 'package:emergex/presentation/onboarding/model/reset_password_request_model.dart';

abstract class LoginRepository {
  Future<ApiResponse<LoginUser>> login(LoginUser user);
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequestModel request);
}
