class IncidentDetails {
  UploadedFiles? uploadedFiles;
  List<EmergeXCaseInformation>? emergeXCaseInformations;
  String? sId;
  String? incidentId;
  String? title;
  String? reportedBy;
  String? country;
  String? department;
  String? projectName;
  String? branch;
  String? reportedDate;
  String? severityLevel;
  String? incidentStatus;
  IncidentLevel? incidentLevel;
  dynamic emergexCaseSummary;
  String? aiInsights;
  dynamic incident;
  dynamic intervention;
  dynamic observation;
  bool? isDeleted;
  dynamic projectManager;
  dynamic preparedBy;
  int? version; // __v
  String? adminStatus;
  String? emergexCaseNumber;
  int? incidentHirachy;
  String? projectId;
  int? showsHirachy;
  List<dynamic>? task;
  String? type;
  String? userId;
  String? userStatus;
  bool? investigationRequired;
  String? immediateAction;
  String? ertApproverId;
  String? investigationApproverId;
  Map<String, dynamic>? questionsData;
  Map<String, dynamic>? caseApprover;

  /// Extracts plain text from emergexCaseSummary regardless of whether it is
  /// a plain String (old API) or a structured object with a `summary` array
  /// (new API).
  String get caseSummaryText {
    if (emergexCaseSummary is Map) {
      final raw = (emergexCaseSummary as Map)['summary'];
      if (raw is List) return raw.join(' ');
      return raw?.toString() ?? '';
    }
    return emergexCaseSummary?.toString() ?? '';
  }

  IncidentDetails({
    this.department,
    this.uploadedFiles,
    this.emergeXCaseInformations,
    this.sId,
    this.incidentId,
    this.title,
    this.reportedBy,
    this.country,
    this.projectName,
    this.branch,
    this.reportedDate,
    this.severityLevel,
    this.incidentStatus,
    this.incidentLevel,
    this.emergexCaseSummary,
    this.aiInsights,
    this.incident,
    this.intervention,
    this.observation,
    this.isDeleted,
    this.projectManager,
    this.preparedBy,
    this.version,
    this.adminStatus,
    this.emergexCaseNumber,
    this.incidentHirachy,
    this.projectId,
    this.showsHirachy,
    this.task,
    this.type,
    this.userId,
    this.userStatus,
    this.investigationRequired,
    this.immediateAction,
    this.ertApproverId,
    this.investigationApproverId,
    this.questionsData,
    this.caseApprover,
  });

  /// Factory to create object from JSON
  factory IncidentDetails.fromJson(Map<String, dynamic> json) {
    // Resolve incident from caseTypeData → caseTypeDetails → root.
    dynamic resolvedIncident = (json['caseTypeData'] is Map
            ? (json['caseTypeData'] as Map)['incident']
            : null) ??
        (json['caseTypeDetails'] is Map
            ? (json['caseTypeDetails'] as Map)['incident']
            : null) ??
        json['incident'];

    // Merge top-level assetsDamage / propertyDamage into the incident map.
    // The API now returns these as top-level arrays; merging them keeps all
    // existing extraction logic (incident.incident['assetsDamage']) working.
    if (json['assetsDamage'] != null || json['propertyDamage'] != null) {
      final incidentMap = resolvedIncident is Map
          ? Map<String, dynamic>.from(resolvedIncident as Map)
          : <String, dynamic>{};
      if (json['assetsDamage'] != null) {
        incidentMap['assetsDamage'] = json['assetsDamage'];
      }
      if (json['propertyDamage'] != null) {
        incidentMap['propertyDamage'] = json['propertyDamage'];
      }
      resolvedIncident = incidentMap;
    }

    return IncidentDetails(
      uploadedFiles: (json['uploadedFiles'] is Map<String, dynamic>)
          ? UploadedFiles.fromJson(
              json['uploadedFiles'] as Map<String, dynamic>,
            )
          : null,
      emergeXCaseInformations: (json['emergeXCaseInformation'] as List<dynamic>)
          .map((e) => EmergeXCaseInformation.fromJson(e))
          .toList(),
      sId: json['_id'],
      department: json['department'],
      incidentId: json['caseId']?.toString() ?? json['incidentId']?.toString(),
      title: json['title'],
      reportedBy: json['reportedBy'],
      country: json['country'],
      projectName: json['projectName'],
      branch: json['branch'],
      reportedDate: json['reportedDate'],
      severityLevel: json['severityLevel'],
      incidentStatus: json['status'],
      incidentLevel: (json['caseLevel'] is Map<String, dynamic>)
          ? IncidentLevel.fromJson(json['caseLevel'] as Map<String, dynamic>)
          : (json['incidentLevel'] is Map<String, dynamic>)
              ? IncidentLevel.fromJson(
                  json['incidentLevel'] as Map<String, dynamic>,
                )
              : null,
      emergexCaseSummary: json['emergexCaseSummary'],
      aiInsights: json['aiInsights'],
      incident: resolvedIncident,
      intervention: (json['caseTypeData'] is Map
              ? (json['caseTypeData'] as Map)['intervention']
              : null) ??
          (json['caseTypeDetails'] is Map
              ? (json['caseTypeDetails'] as Map)['intervention']
              : null) ??
          json['intervention'],
      observation: (json['caseTypeData'] is Map
              ? (json['caseTypeData'] as Map)['observation']
              : null) ??
          (json['caseTypeDetails'] is Map
              ? (json['caseTypeDetails'] as Map)['observation']
              : null) ??
          json['observation'],
      isDeleted: json['isDeleted'],
      projectManager: json['projectManager'],
      preparedBy: json['preparedBy'],
      version: json['__v'],
      adminStatus: json['status'],
      emergexCaseNumber: json['emergexCaseNumber'],
      incidentHirachy: json['incidentHirachy'],
      projectId: json['projectId'],
      showsHirachy: json['showsHirachy'],
      type: json['caseType']?.toString() ?? json['type']?.toString(),
      userId: json['reportUserId']?.toString() ?? json['userId']?.toString(),
      userStatus: json['userStatus'],
      investigationRequired: json['investigationRequired'] as bool?,
      immediateAction: json['immediateAction'] is List
          ? (json['immediateAction'] as List)
              .where((e) => e.toString().isNotEmpty)
              .join('\n')
          : json['immediateAction']?.toString(),
      ertApproverId: json['ertApproverId']?.toString(),
      investigationApproverId: json['investigationApproverId']?.toString(),
      questionsData: json['questions'] is Map<String, dynamic>
          ? json['questions'] as Map<String, dynamic>
          : null,
      caseApprover: json['caseApprover'] is Map<String, dynamic>
          ? json['caseApprover'] as Map<String, dynamic>
          : null,
      task: json['task'] is List
          ? json['task'] as List<dynamic>
          : (json['members'] is List
              ? json['members'] as List<dynamic>
              : _flattenAssignedFlows(json['assignedFlows'])),
    );
  }

  /// Flattens the `assignedFlows` object (ert + investigation, tl + members)
  /// into a flat list of `{ user, userId, tasks: [{taskName, ...}] }` entries
  /// that the existing team card mapper understands.
  static List<dynamic>? _flattenAssignedFlows(dynamic assignedFlows) {
    if (assignedFlows is! Map<String, dynamic>) return null;

    final result = <Map<String, dynamic>>[];

    for (final flowKey in ['ert', 'investigation']) {
      final flow = assignedFlows[flowKey];
      if (flow is! Map<String, dynamic>) continue;

      final entries = <Map<String, dynamic>>[];
      if (flow['tl'] is Map<String, dynamic>) {
        entries.add(flow['tl'] as Map<String, dynamic>);
      }
      if (flow['members'] is List) {
        for (final m in (flow['members'] as List)) {
          if (m is Map<String, dynamic>) entries.add(m);
        }
      }

      for (final entry in entries) {
        final user = entry['user'];
        if (user == null) continue;

        final rawTasks = entry['tasks'] is List ? entry['tasks'] as List : [];
        final normalizedTasks = rawTasks.map((t) {
          if (t is Map<String, dynamic>) {
            return <String, dynamic>{
              ...t,
              'taskName': t['taskTitle']?.toString() ?? t['taskName']?.toString() ?? 'Task',
            };
          }
          return t;
        }).toList();

        result.add({
          'userId': entry['userId'],
          'user': user,
          'role': entry['role'],
          'flow': flowKey,
          'tasks': normalizedTasks,
          'overAllTaskStatus': entry['overAllTaskStatus'],
        });
      }
    }

    return result.isEmpty ? null : result;
  }

  get assetsDamage => null;

  /// Convert object to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (uploadedFiles != null) {
      data['uploadedFiles'] = uploadedFiles!.toJson();
    }
    if (emergeXCaseInformations != null) {
      data['emergeXCaseInformation'] = emergeXCaseInformations
          ?.map((e) => e.toJson())
          .toList();
    }
    data['department'] = department;
    data['_id'] = sId;
    data['incidentId'] = incidentId;
    data['caseId'] = incidentId;
    data['title'] = title;
    data['reportedBy'] = reportedBy;
    data['country'] = country;
    data['branch'] = branch;
    data['reportedDate'] = reportedDate;
    data['projectName'] = projectName;
    data['severityLevel'] = severityLevel;
    data['status'] = incidentStatus;
    data['aiInsights'] = aiInsights;
    data['incident'] = incident;
    data['emergexCaseSummary'] = emergexCaseSummary;
    data['intervention'] = intervention;
    data['observation'] = observation;
    data['isDeleted'] = isDeleted;
    if (incidentLevel != null) {
      data['incidentLevel'] = incidentLevel!.toJson();
    }
    if (projectManager != null) {
      data['projectManager'] = projectManager;
    }
    if (preparedBy != null) {
      data['preparedBy'] = preparedBy;
    }
    data['__v'] = version;
    data['status'] = adminStatus;
    data['emergexCaseNumber'] = emergexCaseNumber;
    data['incidentHirachy'] = incidentHirachy;
    data['projectId'] = projectId;
    data['showsHirachy'] = showsHirachy;
    data['task'] = task;
    data['type'] = type;
    data['userId'] = userId;
    data['userStatus'] = userStatus;
    return data;
  }

  @override
  String toString() {
    return 'IncidentDetails(sId: $sId, incidentId: $incidentId, title: $title, reportedBy: $reportedBy, country: $country, branch: $branch, reportedDate: $reportedDate, severityLevel: $severityLevel, incidentStatus: $incidentStatus, incidentLevel: $incidentLevel, uploadedFiles: $uploadedFiles, task: $task, userId: $userId, userStatus: $userStatus, department: $department, projectName: $projectName)';
  }
}

class EmergeXCaseInformation {
  String? infoId;
  String? text;

  EmergeXCaseInformation({this.infoId, this.text});

  factory EmergeXCaseInformation.fromJson(Map<String, dynamic> json) {
    return EmergeXCaseInformation(infoId: json['infoId'], text: json['text']);
  }

  Map<String, dynamic> toJson() {
    return {'infoId': infoId, 'text': text};
  }
}

class IncidentLevel {
  String? type;
  String? value;

  IncidentLevel({this.type, this.value});

  factory IncidentLevel.fromJson(Map<String, dynamic> json) {
    return IncidentLevel(type: json['type'], value: json['value']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['type'] = type;
    data['value'] = value;
    return data;
  }
}

class UploadedFiles {
  final List<FileItem> audio;
  final List<FileItem> images;
  final List<FileItem> video;

  UploadedFiles({
    required this.audio,
    required this.images,
    required this.video,
  });

  factory UploadedFiles.fromJson(Map<String, dynamic> json) {
    List<FileItem> mapToFiles(dynamic listOrString, String typeHint) {
      List<dynamic> src;
      if (listOrString is List) {
        src = listOrString;
      } else if (listOrString is String) {
        src = [listOrString];
      } else {
        src = const [];
      }
      return src.map((e) {
        if (e is Map<String, dynamic>) {
          return FileItem.fromJson(e);
        } else if (e is String) {
          return FileItem(
            fileUrl: e,
            fileType: typeHint,
            fileName: e.split('/').isNotEmpty ? e.split('/').last : null,
          );
        } else {
          return FileItem(fileType: typeHint);
        }
      }).toList();
    }

    return UploadedFiles(
      audio: mapToFiles(json['audio'], 'audio'),
      images: mapToFiles(json['images'], 'images'),
      video: mapToFiles(json['video'], 'video'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio': audio.map((e) => e.toJson()).toList(),
      'images': images.map((e) => e.toJson()).toList(),
      'video': video.map((e) => e.toJson()).toList(),
    };
  }

  UploadedFiles copyWith({
    List<FileItem>? audio,
    List<FileItem>? images,
    List<FileItem>? video,
  }) {
    return UploadedFiles(
      audio: audio ?? this.audio,
      images: images ?? this.images,
      video: video ?? this.video,
    );
  }

  @override
  String toString() {
    return 'UploadedFiles(audio: ${audio.length}, images: ${images.length}, video: ${video.length})';
  }
}

class FileItem {
  final String? fileUrl;
  final String? key;
  final String? fileType;
  final int? fileSize;
  final String? fileName;
  final String? text;
  final String? id;
  final String? infoId;

  FileItem({
    this.fileUrl,
    this.key,
    this.fileType,
    this.fileSize,
    this.fileName,
    this.text,
    this.id,
    this.infoId,
  });

  /// Create object from JSON
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileUrl: json['fileUrl'] as String?,
      key: json['key'] as String?,
      fileType: json['fileType'] as String?,
      fileSize: json['fileSize'] is int
          ? json['fileSize'] as int
          : int.tryParse(json['fileSize']?.toString() ?? ''),
      fileName: json['fileName'] as String?,
      text: json['text'] as String?,
      id: json['_id'] as String?,
      infoId: json['infoId'] as String? ?? '',
    );
  }

  /// Convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      'key': key,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileName': fileName,
      'text': text,
      '_id': id,
      'infoId': infoId,
    };
  }

  /// For easy cloning/updating
  FileItem copyWith({
    String? fileUrl,
    String? key,
    String? fileType,
    int? fileSize,
    String? fileName,
    String? sId,
    String? text,
    String? id,
  }) {
    return FileItem(
      fileUrl: fileUrl ?? this.fileUrl,
      key: key ?? this.key,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileName: fileName ?? this.fileName,
      text: text ?? this.text,
      id: id ?? this.id,
      infoId: infoId ?? infoId,
    );
  }

  @override
  String toString() {
    return 'FileItem(fileUrl: $fileUrl, key: $key, fileType: $fileType, fileSize: $fileSize, fileName: $fileName, text: $text, id: $id)';
  }
}

class IncidentOverview {
  String? summary;
  String? category;
  String? classification;
  String? reportedBy;
  String? location;
  String? dateTime;
  String? actionTaken;
  String? severity;
  String? locationType;
  String? status;

  IncidentOverview({
    this.summary,
    this.category,
    this.classification,
    this.reportedBy,
    this.location,
    this.dateTime,
    this.actionTaken,
    this.severity,
    this.locationType,
    this.status,
  });

  IncidentOverview.fromJson(Map<String, dynamic> json) {
    summary = json['summary'];
    category = json['category'];
    classification = json['classification'];
    reportedBy = json['reported By'];
    location = json['location'];
    dateTime = json['date/time'];
    actionTaken = json['action_taken'];
    severity = json['Severity'];
    locationType = json['location_type'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['summary'] = summary;
    data['category'] = category;
    data['classification'] = classification;
    data['reported By'] = reportedBy;
    data['location'] = location;
    data['date/time'] = dateTime;
    data['action_taken'] = actionTaken;
    data['Severity'] = severity;
    data['location_type'] = locationType;
    data['status'] = status;
    return data;
  }
}

/// =============================
/// Critical Safety Behaviours
/// =============================

class CriticalSafetyBehaviours {
  BehaviourCategory? awarenessAndBehavior;
  BehaviourCategory? toolsAndTaskExecution;
  BehaviourCategory? criticalSafetyBehavioursGroup;
  BehaviourCategory? personalProtectiveEquipmentPpe;

  CriticalSafetyBehaviours({
    this.awarenessAndBehavior,
    this.toolsAndTaskExecution,
    this.criticalSafetyBehavioursGroup,
    this.personalProtectiveEquipmentPpe,
  });

  CriticalSafetyBehaviours.fromJson(Map<String, dynamic> json) {
    awarenessAndBehavior = json['awarenessAndBehavior'] != null
        ? BehaviourCategory.fromJson(json['awarenessAndBehavior'])
        : null;
    toolsAndTaskExecution = json['toolsAndTaskExecution'] != null
        ? BehaviourCategory.fromJson(json['toolsAndTaskExecution'])
        : null;
    criticalSafetyBehavioursGroup =
        json['criticalSafetyBehavioursGroup'] != null
        ? BehaviourCategory.fromJson(json['criticalSafetyBehavioursGroup'])
        : null;
    personalProtectiveEquipmentPpe =
        json['personalProtectiveEquipmentPpe'] != null
        ? BehaviourCategory.fromJson(json['personalProtectiveEquipmentPpe'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (awarenessAndBehavior != null) {
      data['awarenessAndBehavior'] = awarenessAndBehavior!.toJson();
    }
    if (toolsAndTaskExecution != null) {
      data['toolsAndTaskExecution'] = toolsAndTaskExecution!.toJson();
    }
    if (criticalSafetyBehavioursGroup != null) {
      data['criticalSafetyBehavioursGroup'] = criticalSafetyBehavioursGroup!
          .toJson();
    }
    if (personalProtectiveEquipmentPpe != null) {
      data['personalProtectiveEquipmentPpe'] = personalProtectiveEquipmentPpe!
          .toJson();
    }
    return data;
  }
}

class BehaviourCategory {
  BehaviourItem? eyesOnPath;
  BehaviourItem? eyesOnTask;
  BehaviourItem? lineOfFire;
  BehaviourItem? communication;
  BehaviourItem? housekeeping;
  BehaviourItem? preJobPlanning;
  BehaviourItem? assistanceNeededUsed;
  BehaviourItem? walkingWorkingSurfaces;

  BehaviourCategory({
    this.eyesOnPath,
    this.eyesOnTask,
    this.lineOfFire,
    this.communication,
    this.housekeeping,
    this.preJobPlanning,
    this.assistanceNeededUsed,
    this.walkingWorkingSurfaces,
  });

  BehaviourCategory.fromJson(Map<String, dynamic> json) {
    eyesOnPath = json['eyesOnPath'] != null
        ? BehaviourItem.fromJson(json['eyesOnPath'])
        : null;
    eyesOnTask = json['eyesOnTask'] != null
        ? BehaviourItem.fromJson(json['eyesOnTask'])
        : null;
    lineOfFire = json['lineOfFire'] != null
        ? BehaviourItem.fromJson(json['lineOfFire'])
        : null;
    communication = json['communication'] != null
        ? BehaviourItem.fromJson(json['communication'])
        : null;
    housekeeping = json['housekeeping'] != null
        ? BehaviourItem.fromJson(json['housekeeping'])
        : null;
    preJobPlanning = json['preJobPlanning'] != null
        ? BehaviourItem.fromJson(json['preJobPlanning'])
        : null;
    assistanceNeededUsed = json['assistanceNeededUsed'] != null
        ? BehaviourItem.fromJson(json['assistanceNeededUsed'])
        : null;
    walkingWorkingSurfaces = json['walkingWorkingSurfaces'] != null
        ? BehaviourItem.fromJson(json['walkingWorkingSurfaces'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (eyesOnPath != null) data['eyesOnPath'] = eyesOnPath!.toJson();
    if (eyesOnTask != null) data['eyesOnTask'] = eyesOnTask!.toJson();
    if (lineOfFire != null) data['lineOfFire'] = lineOfFire!.toJson();
    if (communication != null) data['communication'] = communication!.toJson();
    if (housekeeping != null) data['housekeeping'] = housekeeping!.toJson();
    if (preJobPlanning != null) {
      data['preJobPlanning'] = preJobPlanning!.toJson();
    }
    if (assistanceNeededUsed != null) {
      data['assistanceNeededUsed'] = assistanceNeededUsed!.toJson();
    }
    if (walkingWorkingSurfaces != null) {
      data['walkingWorkingSurfaces'] = walkingWorkingSurfaces!.toJson();
    }
    return data;
  }
}

class BehaviourItem {
  bool? safe;
  bool? atRisk;

  BehaviourItem({this.safe, this.atRisk});

  BehaviourItem.fromJson(Map<String, dynamic> json) {
    safe = json['safe'];
    atRisk = json['atRisk'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['safe'] = safe;
    data['atRisk'] = atRisk;
    return data;
  }
}
