/// Model for client filter request parameters
/// Used to send filter data to API
class ClientFilterRequest {
  final String? status;
  final DateRange? dateRange;
  final List<String>? industries;
  final String? location;
  final String? search;

  ClientFilterRequest({
    this.status,
    this.dateRange,
    this.industries,
    this.location,
    this.search,
  });

  /// Convert object to JSON for API request
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    // Add status (empty string if null)
    json['status'] = status ?? '';

    // Add date range
    if (dateRange != null) {
      json['daterange'] = dateRange!.toJson();
    } else {
      json['daterange'] = {};
    }

    // Add industries (empty array if null)
    json['industries'] = industries ?? [];

    // Add location (empty string if null)
    json['location'] = location ?? '';

    // Add search (empty string if null)
    json['search'] = search ?? '';

    return json;
  }

  /// Create a copy with updated values
  ClientFilterRequest copyWith({
    String? status,
    DateRange? dateRange,
    List<String>? industries,
    String? location,
    String? search,
  }) {
    return ClientFilterRequest(
      status: status ?? this.status,
      dateRange: dateRange ?? this.dateRange,
      industries: industries ?? this.industries,
      location: location ?? this.location,
      search: search ?? this.search,
    );
  }
}

/// Model for date range filter
class DateRange {
  final String? from;
  final String? to;

  DateRange({
    this.from,
    this.to,
  });

  /// Convert object to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'from': from ?? '',
      'to': to ?? '',
    };
  }

  /// Create a copy with updated values
  DateRange copyWith({
    String? from,
    String? to,
  }) {
    return DateRange(
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

