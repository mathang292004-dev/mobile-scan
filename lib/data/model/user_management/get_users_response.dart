import 'package:emergex/presentation/user_onboarding/model/user_management_model.dart';

class GetUsersResponse {
  final UserStatsModel stats;
  final List<UserModel> users;
  final int page;
  final int limit;
  final int totalFiltered;
  final int totalPages;

  const GetUsersResponse({
    required this.stats,
    required this.users,
    required this.page,
    required this.limit,
    required this.totalFiltered,
    required this.totalPages,
  });

  factory GetUsersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final statsJson = data['stats'] as Map<String, dynamic>? ?? {};
    final usersJson = data['users'] as List<dynamic>? ?? [];
    final paginationJson = data['pagination'] as Map<String, dynamic>? ?? {};

    return GetUsersResponse(
      stats: UserStatsModel.fromJson(statsJson),
      users: usersJson
          .whereType<Map<String, dynamic>>()
          .map((u) => UserModel.fromJson(u))
          .toList(),
      page: paginationJson['page'] ?? 1,
      limit: paginationJson['limit'] ?? 10,
      totalFiltered: paginationJson['totalFiltered'] ?? 0,
      totalPages: paginationJson['totalPages'] ?? 1,
    );
  }
}
