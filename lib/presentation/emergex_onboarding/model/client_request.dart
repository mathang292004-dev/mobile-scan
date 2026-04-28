import 'dart:io';
import 'package:emergex/data/model/client_management/client_response.dart';

/// Model for add/update client request
class ClientRequest {
  final String? clientName;
  final String? clientId;
  final String? email;
  final String? industry;
  final String? location;
  final File? profileFile;
  final String? status;
  final bool deleteImage;

  ClientRequest({
    this.clientName,
    this.clientId,
    this.email,
    this.industry,
    this.location,
    this.profileFile,
    this.status,
    this.deleteImage = false,
  });
}

/// Model for update client response
class UpdateClientResponse {
  final Client? result;
  final String? existingProfileKey;

  UpdateClientResponse({
    this.result,
    this.existingProfileKey,
  });

  factory UpdateClientResponse.fromJson(Map<String, dynamic> json) {
    return UpdateClientResponse(
      result: json['result'] is Map<String, dynamic>
          ? Client.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      existingProfileKey: json['existingProfileKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.toJson(),
      'existingProfileKey': existingProfileKey,
    };
  }
}

/// Model for delete client response
class DeleteClientResponse {
  final Map<String, dynamic>? deletedClient;

  DeleteClientResponse({
    this.deletedClient,
  });

  factory DeleteClientResponse.fromJson(Map<String, dynamic> json) {
    return DeleteClientResponse(
      deletedClient: json['deletedClient'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['deletedClient'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deletedClient': deletedClient,
    };
  }
}

