import 'package:equatable/equatable.dart';

/// Modules and Features Response Model
/// Response from POST /api/onboarding/view-details with view: "features"
class ModulesAndFeaturesResponse extends Equatable {
  final List<Module> modules;

  const ModulesAndFeaturesResponse({required this.modules});

  factory ModulesAndFeaturesResponse.fromJson(Map<String, dynamic> json) {
    // Handle response format: { "status": "success", "data": [...] }
    List<dynamic>? dataList;
    if (json['data'] is List) {
      dataList = json['data'] as List;
    }

    return ModulesAndFeaturesResponse(
      modules: dataList != null
          ? dataList
                .whereType<Map<String, dynamic>>()
                .map((e) => Module.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': modules.map((e) => e.toJson()).toList()};
  }

  @override
  List<Object?> get props => [modules];
}

/// Module Model
class Module extends Equatable {
  final String id;
  final String name;
  final String desc;
  final List<Feature> features;

  const Module({
    required this.id,
    required this.name,
    required this.desc,
    required this.features,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      features: json['features'] is List
          ? (json['features'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => Feature.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'desc': desc,
      'features': features.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, desc, features];
}

/// Feature Model
class Feature extends Equatable {
  final String featureId;
  final String name;
  final String desc;

  const Feature({
    required this.featureId,
    required this.name,
    required this.desc,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      featureId: json['featureId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'featureId': featureId, 'name': name, 'desc': desc};
  }

  @override
  List<Object?> get props => [featureId, name, desc];
}
