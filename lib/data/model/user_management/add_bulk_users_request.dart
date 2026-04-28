import 'package:emergex/data/model/user_management/validate_csv_response.dart';

class AddBulkUsersRequest {
  final List<ValidatedUser> users;
  final String clientId;

  const AddBulkUsersRequest({
    required this.users,
    required this.clientId,
  });

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((u) => u.toJson()).toList(),
      'clientId': clientId,
    };
  }
}
