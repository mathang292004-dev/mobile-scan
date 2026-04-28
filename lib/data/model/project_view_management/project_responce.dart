/// Model for project API response
/// Contains list of projects, workSites, and locations
class ProjectResponse {
  final List<Project>? projects;
  final List<String>? workSites;
  final List<String>? locations;
  final String? clientName;
  final String? clientImage;

  ProjectResponse({
    this.projects,
    this.workSites,
    this.locations,
    this.clientName,
    this.clientImage,
  });

  /// Factory to create object from JSON
  factory ProjectResponse.fromJson(Map<String, dynamic> json) {
    // Extract clientName and clientImage from clientDetails object
    String? clientName;
    String? clientImage;
    if (json['clientDetails'] is Map<String, dynamic>) {
      final clientDetails = json['clientDetails'] as Map<String, dynamic>;
      clientName =
          clientDetails['clientName']?.toString() ??
          clientDetails['clientname']?.toString() ??
          clientDetails['ClientName']?.toString();

      // Parse client image from profileData or profile
      final profileRaw =
          clientDetails['profileData'] ?? clientDetails['profile'];
      if (profileRaw is Map<String, dynamic>) {
        clientImage = profileRaw['fileUrl']?.toString();
      }
    }

    return ProjectResponse(
      projects: json['projects'] is List
          ? (json['projects'] as List)
                .map((e) => Project.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      workSites: json['workSites'] is List
          ? (json['workSites'] as List).map((e) => e.toString()).toList()
          : null,
      locations: json['locations'] is List
          ? (json['locations'] as List).map((e) => e.toString()).toList()
          : null,
      clientName: clientName,
      clientImage: clientImage,
    );
  }

  /// Convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      'projects': projects?.map((e) => e.toJson()).toList(),
      'workSites': workSites,
      'locations': locations,
      'clientName': clientName,
      'clientImage': clientImage,
    };
  }
}

/// Model for individual project
class Project {
  final String? id;
  final String? projectId;
  final String? clientId;
  final String? projectName;
  final String? description;
  final String? location;
  final String? workSites;
  final int? employeesAssigned;
  final String? status;
  final String? uploadStatus;
  final bool? isDeleted;
  final String? createdAt;
  final int? version; // __v

  Project({
    this.id,
    this.projectId,
    this.clientId,
    this.projectName,
    this.description,
    this.location,
    this.workSites,
    this.employeesAssigned,
    this.status,
    this.uploadStatus,
    this.isDeleted,
    this.createdAt,
    this.version,
  });

  /// Factory to create object from JSON
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] as String?,
      projectId: json['projectId'] as String?,
      clientId: json['clientId'] as String?,
      projectName: json['projectName'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      workSites: json['workSites'] as String?,
      employeesAssigned: json['employeesAssigned'] is int
          ? json['employeesAssigned'] as int
          : (json['employeesAssigned'] != null
                ? int.tryParse(json['employeesAssigned'].toString())
                : null),
      status: json['status'] as String?,
      uploadStatus: json['uploadStatus'] as String?,
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
      'projectId': projectId,
      'clientId': clientId,
      'projectName': projectName,
      'description': description,
      'location': location,
      'workSites': workSites,
      'employeesAssigned': employeesAssigned,
      'status': status,
      'uploadStatus': uploadStatus,
      'isDeleted': isDeleted ?? false,
      'createdAt': createdAt,
      '__v': version,
    };
  }

  /// Create a copy with updated values
  Project copyWith({
    String? id,
    String? projectId,
    String? clientId,
    String? projectName,
    String? description,
    String? location,
    String? workSites,
    int? employeesAssigned,
    String? status,
    String? uploadStatus,
    bool? isDeleted,
    String? createdAt,
    int? version,
  }) {
    return Project(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      clientId: clientId ?? this.clientId,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      location: location ?? this.location,
      workSites: workSites ?? this.workSites,
      employeesAssigned: employeesAssigned ?? this.employeesAssigned,
      status: status ?? this.status,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
    );
  }
}
