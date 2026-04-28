/// Model for client API response
/// Contains list of clients, locations, and industries
class ClientResponse {
  final List<Client>? clients;
  final List<String>? locations;
  final List<String>? industries;

  ClientResponse({
    this.clients,
    this.locations,
    this.industries,
  });

  /// Factory to create object from JSON
  factory ClientResponse.fromJson(Map<String, dynamic> json) {
    return ClientResponse(
      clients: json['clients'] is List
          ? (json['clients'] as List)
              .map((e) => Client.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      locations: json['locations'] is List
          ? (json['locations'] as List)
              .map((e) => e.toString())
              .toList()
          : null,
      industries: json['industries'] is List
          ? (json['industries'] as List)
              .map((e) => e.toString())
              .toList()
          : null,
    );
  }

  /// Convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      'clients': clients?.map((e) => e.toJson()).toList(),
      'locations': locations,
      'industries': industries,
    };
  }
}

/// Model for individual client
class Client {
  final String? id;
  final String? clientId;
  final String? clientName;
  final String? email;
  final String? industry;
  final String? location;
  final int? projectCount;
  final ProfileData? profileData;
  final String? status;
  final bool? isDeleted;
  final String? createdAt;
  final int? version; // __v

  Client({
    this.id,
    this.clientId,
    this.clientName,
    this.email,
    this.industry,
    this.location,
    this.projectCount,
    this.profileData,
    this.status,
    this.isDeleted,
    this.createdAt,
    this.version,
  });

  /// Factory to create object from JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    // Handle both profileData and profile keys
    ProfileData? profileData;
    if (json['profileData'] is Map<String, dynamic>) {
      profileData = ProfileData.fromJson(
        json['profileData'] as Map<String, dynamic>,
      );
    } else if (json['profile'] is Map<String, dynamic>) {
      profileData = ProfileData.fromJson(
        json['profile'] as Map<String, dynamic>,
      );
    }

    return Client(
      id: json['_id'] as String?,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String?,
      email: json['email'] as String?,
      industry: json['industry'] as String?,
      location: json['location'] as String?,
      projectCount: json['projectCount'] is int
          ? json['projectCount'] as int
          : (json['projectCount'] != null
              ? int.tryParse(json['projectCount'].toString())
              : null),
      profileData: profileData,
      status: json['status'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      version: json['__v'] is int
          ? json['__v'] as int
          : (json['__v'] != null ? int.tryParse(json['__v'].toString()) : null),
    );
  }

  /// Convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'clientId': clientId,
      'clientName': clientName,
      'email': email,
      'industry': industry,
      'location': location,
      'projectCount': projectCount,
      'profileData': profileData?.toJson(),
      'status': status,
      'isDeleted': isDeleted ?? false,
      'createdAt': createdAt,
      '__v': version,
    };
  }

  /// Create a copy with updated values
  Client copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? industry,
    String? location,
    int? projectCount,
    ProfileData? profileData,
    String? status,
    bool? isDeleted,
    String? createdAt,
    int? version,
  }) {
    return Client(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      projectCount: projectCount ?? this.projectCount,
      profileData: profileData ?? this.profileData,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
    );
  }
}

/// Model for client profile data
class ProfileData {
  final String? fileUrl;
  final String? key;

  ProfileData({
    this.fileUrl,
    this.key,
  });

  /// Factory to create object from JSON
  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      fileUrl: json['fileUrl'] as String?,
      key: json['key'] as String?,
    );
  }

  /// Convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl ?? '',
      'key': key ?? '',
    };
  }

  /// Create a copy with updated values
  ProfileData copyWith({
    String? fileUrl,
    String? key,
  }) {
    return ProfileData(
      fileUrl: fileUrl ?? this.fileUrl,
      key: key ?? this.key,
    );
  }
}


