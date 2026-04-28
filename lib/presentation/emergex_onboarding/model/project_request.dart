import 'package:emergex/data/model/project_view_management/project_responce.dart';

/// Model for add/update project request
class ProjectRequest {
  final String? clientId;
  final String? projectName;
  final String? projectId;
  final String? location;
  final String? workSites;
  final String? description;

  ProjectRequest({
    this.clientId,
    this.projectName,
    this.projectId,
    this.location,
    this.workSites,
    this.description,
  });
}

/// Model for update project response
class UpdateProjectResponse {
  final Project? result;

  UpdateProjectResponse({
    this.result,
  });

  factory UpdateProjectResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProjectResponse(
      result: json['result'] is Map<String, dynamic>
          ? Project.fromJson(json['result'] as Map<String, dynamic>)
          : Project.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.toJson(),
    };
  }
}

/// Model for delete project response
class DeleteProjectResponse {
  final bool? acknowledged;
  final int? modifiedCount;
  final String? upsertedId;
  final int? upsertedCount;
  final int? matchedCount;

  DeleteProjectResponse({
    this.acknowledged,
    this.modifiedCount,
    this.upsertedId,
    this.upsertedCount,
    this.matchedCount,
  });

  factory DeleteProjectResponse.fromJson(Map<String, dynamic> json) {
    return DeleteProjectResponse(
      acknowledged: json['acknowledged'] as bool?,
      modifiedCount: json['modifiedCount'] is int
          ? json['modifiedCount'] as int
          : (json['modifiedCount'] != null
              ? int.tryParse(json['modifiedCount'].toString())
              : null),
      upsertedId: json['upsertedId'] as String?,
      upsertedCount: json['upsertedCount'] is int
          ? json['upsertedCount'] as int
          : (json['upsertedCount'] != null
              ? int.tryParse(json['upsertedCount'].toString())
              : null),
      matchedCount: json['matchedCount'] is int
          ? json['matchedCount'] as int
          : (json['matchedCount'] != null
              ? int.tryParse(json['matchedCount'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acknowledged': acknowledged,
      'modifiedCount': modifiedCount,
      'upsertedId': upsertedId,
      'upsertedCount': upsertedCount,
      'matchedCount': matchedCount,
    };
  }
}

