class AddUserResponse {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String? profile;
  final String? clientId;

  AddUserResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.profile,
    this.clientId,
  });

  factory AddUserResponse.fromJson(Map<String, dynamic> json) {
    return AddUserResponse(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      profile: json['profile']?.toString(),
      clientId: json['clientId']?.toString(),
    );
  }
}
