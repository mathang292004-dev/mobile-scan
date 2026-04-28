import 'package:equatable/equatable.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';
import 'package:emergex/data/model/upload_doc/role_details_response.dart';

/// Fetch Roles Response Model
class FetchRolesResponse extends Equatable {
  final List<Role> roles;
  final int totalRoles;
  final AiInsights? aiInsights;

  const FetchRolesResponse({
    required this.roles,
    required this.totalRoles,
    this.aiInsights,
  });

  factory FetchRolesResponse.fromJson(Map<String, dynamic> json) {
    AiInsights? extractedAiInsights;
    
    // Try to extract aiInsights from various possible locations
    if (json['aiInsights'] != null && json['aiInsights'] is Map<String, dynamic>) {
      extractedAiInsights = AiInsights.fromJson(json['aiInsights'] as Map<String, dynamic>);
    }
    
    // Handle nested data.data structure
    if (json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      
      // Extract aiInsights from data level if not already found
      if (extractedAiInsights == null && dataMap['aiInsights'] != null && dataMap['aiInsights'] is Map<String, dynamic>) {
        extractedAiInsights = AiInsights.fromJson(dataMap['aiInsights'] as Map<String, dynamic>);
      }
      
      // Check if data.data exists (nested structure)
      if (dataMap['roles'] is List) {
        final rolesList = (dataMap['roles'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Role.fromJson(e))
            .toList();
        return FetchRolesResponse(
          roles: rolesList,
          totalRoles: rolesList.length,
          aiInsights: extractedAiInsights,
        );
      }
    }
    // Handle response where data is directly a list
    if (json['roles'] is List) {
      final rolesList = (json['roles'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => Role.fromJson(e))
          .toList();
      return FetchRolesResponse(
        roles: rolesList,
        totalRoles: rolesList.length,
        aiInsights: extractedAiInsights,
      );
    }
    // Handle response where roles is a key
    return FetchRolesResponse(
      roles: json['roles'] is List
          ? (json['roles'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => Role.fromJson(e))
              .toList()
          : [],
      totalRoles: json['totalRoles'] as int? ?? 
          (json['roles'] is List ? (json['roles'] as List).length : 0),
      aiInsights: extractedAiInsights,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roles': roles.map((e) => e.toJson()).toList(),
      'totalRoles': totalRoles,
      'aiInsights': aiInsights,
    };
  }

  @override
  List<Object?> get props => [roles, totalRoles, aiInsights];
}

