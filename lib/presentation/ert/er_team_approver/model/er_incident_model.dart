import 'package:emergex/helpers/text_helper.dart';

/// Model for ER Team Approver Incident
/// This is currently using static data and will be replaced with API integration
class ErIncidentModel {
  final String id;
  final String title;
  final String incidentCode;
  final String submittedBy;
  final String submittedDate;
  final String timeElapsed;
  final ErIncidentStatus status;
  final bool isSelected;

  ErIncidentModel({
    required this.id,
    required this.title,
    required this.incidentCode,
    required this.submittedBy,
    required this.submittedDate,
    required this.timeElapsed,
    required this.status,
    this.isSelected = false,
  });

  ErIncidentModel copyWith({
    String? id,
    String? title,
    String? incidentCode,
    String? submittedBy,
    String? submittedDate,
    String? timeElapsed,
    ErIncidentStatus? status,
    bool? isSelected,
  }) {
    return ErIncidentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      incidentCode: incidentCode ?? this.incidentCode,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedDate: submittedDate ?? this.submittedDate,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Enum for incident status
enum ErIncidentStatus {
  verified,
  notVerified,
  rejected,
}

/// Extension for status display
extension ErIncidentStatusExtension on ErIncidentStatus {
  String get displayName {
    switch (this) {
      case ErIncidentStatus.verified:
        return TextHelper.tabVerified;
      case ErIncidentStatus.notVerified:
        return TextHelper.tabNotVerified;
      case ErIncidentStatus.rejected:
        return TextHelper.tabRejected;
    }
  }
}
