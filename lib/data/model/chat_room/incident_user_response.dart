class IncidentUserResponse {
  final int? statusCode;
  final String? message;
  final String? status;
  final List<IncidentUser>? data;

  IncidentUserResponse({
    this.statusCode,
    this.message,
    this.status,
    this.data,
  });

  factory IncidentUserResponse.fromJson(Map<String, dynamic> json) {
    return IncidentUserResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      status: json['status'] as String?,
      data: json['data'] is List
          ? (json['data'] as List)
              .map((e) => IncidentUser.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'status': status,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class IncidentUser {
  final String? id;
  final String? name;
  final String? email;

  IncidentUser({
    this.id,
    this.name,
    this.email,
  });

  factory IncidentUser.fromJson(Map<String, dynamic> json) {
    return IncidentUser(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  IncidentUser copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return IncidentUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
