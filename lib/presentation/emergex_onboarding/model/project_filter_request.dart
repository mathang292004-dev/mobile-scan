import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';

/// Model for project filter request parameters
/// Used to send filter data to API
class ProjectFilterRequest {
  final String? status;
  final DateRange? dateRange;
  final String? workSites;
  final String? location;
  final String? search;
  final String? projectName;
  final String? projectId;

  ProjectFilterRequest({
    this.status,
    this.dateRange,
    this.workSites,
    this.location,
    this.search,
    this.projectName,
    this.projectId,
  });

  /// Convert object to JSON for API request
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    // Add status (empty string if null, ensure capitalized)
    json['status'] = _capitalizeStatus(status) ?? '';

    // Add date range
    if (dateRange != null) {
      json['daterange'] = dateRange!.toJson();
    } else {
      json['daterange'] = {};
    }

    // Add workSites (empty string if null)
    json['workSites'] = workSites ?? '';

    // Add location (empty string if null)
    json['location'] = location ?? '';

    // Add search (empty string if null)
    json['search'] = search ?? '';

    // Add projectName (empty string if null)
    json['projectName'] = projectName ?? '';

    // Add projectId (empty string if null)
    json['projectId'] = projectId ?? '';

    return json;
  }

  /// Create a copy with updated values
  ProjectFilterRequest copyWith({
    String? status,
    DateRange? dateRange,
    String? workSites,
    String? location,
    String? search,
    String? projectName,
    String? projectId,
  }) {
    return ProjectFilterRequest(
      status: status ?? this.status,
      dateRange: dateRange ?? this.dateRange,
      workSites: workSites ?? this.workSites,
      location: location ?? this.location,
      search: search ?? this.search,
      projectName: projectName ?? this.projectName,
      projectId: projectId ?? this.projectId,
    );
  }

  /// Capitalize status string (API expects "Active" or "Inactive")
  static String? _capitalizeStatus(String? status) {
    if (status == null || status.isEmpty) return null;
    
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'active') {
      return 'Active';
    } else if (lowerStatus == 'inactive') {
      return 'Inactive';
    } else {
      // Fallback: capitalize first letter
      return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }
}

