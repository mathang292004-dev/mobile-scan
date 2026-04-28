class ValidatedUser {
  final String name;
  final String email;
  final String phone;
  final String status;

  const ValidatedUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory ValidatedUser.fromJson(Map<String, dynamic> json) {
    return ValidatedUser(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
    };
  }
}

class ValidateCsvResponse {
  final List<ValidatedUser> validUsers;
  final List<dynamic> existingUsers;
  final List<dynamic> errors;

  const ValidateCsvResponse({
    required this.validUsers,
    required this.existingUsers,
    required this.errors,
  });

  factory ValidateCsvResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return ValidateCsvResponse(
      validUsers: (data['validUsers'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((u) => ValidatedUser.fromJson(u))
              .toList() ??
          [],
      existingUsers: data['existingUsers'] as List<dynamic>? ?? [],
      errors: data['errors'] as List<dynamic>? ?? [],
    );
  }
}
