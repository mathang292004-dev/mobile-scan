import 'package:equatable/equatable.dart';

/// Complete Onboarding Response Model
class CompleteOnboardingResponse extends Equatable {
  final String projectId;
  final int usersUpdated;
  final int employeesAssigned;
  final String message;

  const CompleteOnboardingResponse({
    required this.projectId,
    required this.usersUpdated,
    required this.employeesAssigned,
    required this.message,
  });

  factory CompleteOnboardingResponse.fromJson(Map<String, dynamic> json) {
    return CompleteOnboardingResponse(
      projectId: json['projectId']?.toString() ?? '',
      usersUpdated: json['usersUpdated'] is int
          ? json['usersUpdated'] as int
          : json['usersUpdated'] is String
              ? int.tryParse(json['usersUpdated'] as String) ?? 0
              : 0,
      employeesAssigned: json['employeesAssigned'] is int
          ? json['employeesAssigned'] as int
          : json['employeesAssigned'] is String
              ? int.tryParse(json['employeesAssigned'] as String) ?? 0
              : 0,
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'usersUpdated': usersUpdated,
      'employeesAssigned': employeesAssigned,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [projectId, usersUpdated, employeesAssigned, message];
}

