class LoginUser {
  String? id;
  String? email;
  String? password;
  String? userName;
  String? role;
  bool? rememberMe;

  LoginUser({
    this.id,
    this.email,
    this.password,
    this.userName,
    this.role,
    this.rememberMe,
  });

  LoginUser.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    email = json['email']?.toString();
    password = json['password']?.toString();
    userName =
        json['userName']?.toString() ??
        json['name']?.toString(); // Handle both userName and name fields
    role = json['role']?.toString();
    rememberMe = json['rememberMe'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'userName': userName,
      'role': role,
      'rememberMe': rememberMe ?? false,
    };
  }

  bool get isValid => id != null && id!.isNotEmpty && email != null;
}
