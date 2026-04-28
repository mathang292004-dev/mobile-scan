class AddBulkUsersResponse {
  final List<dynamic> success;
  final List<dynamic> failed;

  const AddBulkUsersResponse({
    required this.success,
    required this.failed,
  });

  factory AddBulkUsersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AddBulkUsersResponse(
      success: data['success'] as List<dynamic>? ?? [],
      failed: data['failed'] as List<dynamic>? ?? [],
    );
  }
}
