import 'package:equatable/equatable.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';

/// Response model for uploading documents for all projects
class UploadDocsResponse extends Equatable {
  final bool? success;
  final String? message;
  final OnboardingOrganizationStructure? data;

  const UploadDocsResponse({
    this.success,
    this.message,
    this.data,
  });

  factory UploadDocsResponse.fromJson(Map<String, dynamic> json) {
    return UploadDocsResponse(
      success: json['success'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] != null
          ? OnboardingOrganizationStructure.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }

  @override
  List<Object?> get props => [success, message, data];
}
