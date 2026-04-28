import 'dart:io';

class AddUserRequest {
  final String name;
  final String email;
  final String phone;
  final String dialCode;
  final String status;
  final String? clientId;
  final File? profileImage;

  const AddUserRequest({
    required this.name,
    required this.email,
    required this.phone,
    this.dialCode = '+91',
    this.status = 'Draft',
    this.clientId,
    this.profileImage,
  });

  Map<String, dynamic> toFormData() {
    final data = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': '$dialCode$phone',
      'status': status,
    };
    if (clientId != null && clientId!.isNotEmpty) {
      data['clientId'] = clientId;
    }
    return data;
  }
}
