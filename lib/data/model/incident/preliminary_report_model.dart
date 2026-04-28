class PreliminaryReportData {
  final IncidentInfoData? incidentInfo;
  final ContractorInfoData? contractorInfo;
  final ContractorCoordinationData? contractorCoordination;
  final SamptData? sampt;
  final InvestigationStatusData? investigationStatus;

  const PreliminaryReportData({
    this.incidentInfo,
    this.contractorInfo,
    this.contractorCoordination,
    this.sampt,
    this.investigationStatus,
  });

  factory PreliminaryReportData.fromJson(Map<String, dynamic> json) {
    return PreliminaryReportData(
      incidentInfo: json['incidentInfo'] is Map<String, dynamic>
          ? IncidentInfoData.fromJson(json['incidentInfo'])
          : null,
      contractorInfo: json['contractorInfo'] is Map<String, dynamic>
          ? ContractorInfoData.fromJson(json['contractorInfo'])
          : null,
      contractorCoordination: json['contractorCoordination'] is Map<String, dynamic>
          ? ContractorCoordinationData.fromJson(json['contractorCoordination'])
          : null,
      sampt: json['sampt'] is Map<String, dynamic>
          ? SamptData.fromJson(json['sampt'])
          : null,
      investigationStatus: json['investigationStatus'] is Map<String, dynamic>
          ? InvestigationStatusData.fromJson(json['investigationStatus'])
          : null,
    );
  }
}

class AppropriateBlockData {
  final String? preliminary;
  final String? submitWithin24hrs;
  final String? finalField;
  final String? submitWithin3Days;

  const AppropriateBlockData({
    this.preliminary,
    this.submitWithin24hrs,
    this.finalField,
    this.submitWithin3Days,
  });

  factory AppropriateBlockData.fromJson(Map<String, dynamic> json) {
    return AppropriateBlockData(
      preliminary: json['preliminary']?.toString(),
      submitWithin24hrs: json['submitWithin24hrs']?.toString(),
      finalField: json['final']?.toString(),
      submitWithin3Days: json['submitWithin3Days']?.toString(),
    );
  }
}

class IncidentInfoData {
  final String? incidentCategory;
  final String? incidentClassification;
  final String? onshoreOffshore;
  final String? onjobOffjob;
  final String? dayNight;
  final String? incidentDate;
  final String? incidentLocation;
  final String? briefSummary;
  final String? immediateCorrectiveActions;
  final String? propertyDamageDescription;
  final String? injuryDescription;
  final String? natureOfInjury;
  final String? bodyAreaPart;
  final String? accidentTypes;
  final String? sourceOfInjuries;
  final String? hazardousConditions;
  final AppropriateBlockData? appropriateBlock;

  const IncidentInfoData({
    this.incidentCategory,
    this.incidentClassification,
    this.onshoreOffshore,
    this.onjobOffjob,
    this.dayNight,
    this.incidentDate,
    this.incidentLocation,
    this.briefSummary,
    this.immediateCorrectiveActions,
    this.propertyDamageDescription,
    this.injuryDescription,
    this.natureOfInjury,
    this.bodyAreaPart,
    this.accidentTypes,
    this.sourceOfInjuries,
    this.hazardousConditions,
    this.appropriateBlock,
  });

  factory IncidentInfoData.fromJson(Map<String, dynamic> json) {
    return IncidentInfoData(
      incidentCategory: json['incidentCategory']?.toString(),
      incidentClassification: json['incidentClassification']?.toString(),
      onshoreOffshore: json['onshoreOffshore']?.toString(),
      onjobOffjob: json['onjobOffjob']?.toString(),
      dayNight: json['dayNight']?.toString(),
      incidentDate: json['incidentDate']?.toString(),
      incidentLocation: json['incidentLocation']?.toString(),
      briefSummary: json['briefSummary']?.toString(),
      immediateCorrectiveActions: json['immediateCorrectiveActions']?.toString(),
      propertyDamageDescription: json['propertyDamageDescription']?.toString(),
      injuryDescription: json['injuryDescription']?.toString(),
      natureOfInjury: json['natureOfInjury']?.toString(),
      bodyAreaPart: json['bodyAreaPart']?.toString(),
      accidentTypes: json['accidentTypes']?.toString(),
      sourceOfInjuries: json['sourceOfInjuries']?.toString(),
      hazardousConditions: json['hazardousConditions']?.toString(),
      appropriateBlock: json['appropriateBlock'] is Map<String, dynamic>
          ? AppropriateBlockData.fromJson(json['appropriateBlock'])
          : null,
    );
  }
}

class ContractorInfoData {
  final String? nameOfInvolved;
  final String? badgeOrIqama;
  final String? contactNo;
  final String? jobTitle;
  final String? jobClassification;
  final String? employmentType;
  final String? supervisorName;
  final String? contractorEndDate;
  final String? insuranceProvider;
  final String? primeContractor;
  final String? clientName;
  final String? projectName;
  final List<String> witnesses;

  const ContractorInfoData({
    this.nameOfInvolved,
    this.badgeOrIqama,
    this.contactNo,
    this.jobTitle,
    this.jobClassification,
    this.employmentType,
    this.supervisorName,
    this.contractorEndDate,
    this.insuranceProvider,
    this.primeContractor,
    this.clientName,
    this.projectName,
    this.witnesses = const [],
  });

  factory ContractorInfoData.fromJson(Map<String, dynamic> json) {
    final rawWitnesses = json['witnesses'];
    final witnesses = rawWitnesses is List
        ? rawWitnesses.map((w) {
            if (w is Map<String, dynamic>) return w['name']?.toString() ?? '';
            return w?.toString() ?? '';
          }).toList()
        : <String>[];

    return ContractorInfoData(
      nameOfInvolved: json['nameOfInvolved']?.toString(),
      badgeOrIqama: json['badgeOrIqama']?.toString(),
      contactNo: json['contactNo']?.toString(),
      jobTitle: json['jobTitle']?.toString(),
      jobClassification: json['jobClassification']?.toString(),
      employmentType: json['employmentType']?.toString(),
      supervisorName: json['supervisorName']?.toString(),
      contractorEndDate: json['contractorEndDate']?.toString(),
      insuranceProvider: json['insuranceProvider']?.toString(),
      primeContractor: json['primeContractor']?.toString(),
      clientName: json['clientName']?.toString(),
      projectName: json['projectName']?.toString(),
      witnesses: witnesses,
    );
  }
}

class ContractorCoordinationData {
  final dynamic preparedBy;
  final dynamic contractorProjectManager;

  const ContractorCoordinationData({
    this.preparedBy,
    this.contractorProjectManager,
  });

  factory ContractorCoordinationData.fromJson(Map<String, dynamic> json) {
    return ContractorCoordinationData(
      preparedBy: json['preparedBy'],
      contractorProjectManager: json['contractorProjectManager'],
    );
  }
}

class SamptData {
  final String? department;
  final String? division;
  final String? divisionSapOrgCode;
  final String? blNumber;
  final String? contractNumber;
  final dynamic divisionHead;

  const SamptData({
    this.department,
    this.division,
    this.divisionSapOrgCode,
    this.blNumber,
    this.contractNumber,
    this.divisionHead,
  });

  factory SamptData.fromJson(Map<String, dynamic> json) {
    return SamptData(
      department: json['department']?.toString(),
      division: json['division']?.toString(),
      divisionSapOrgCode: json['divisionSapOrgCode']?.toString(),
      blNumber: json['blNumber']?.toString(),
      contractNumber: json['contractNumber']?.toString(),
      divisionHead: json['divisionHead'],
    );
  }
}

class InvestigationStatusData {
  final String? incidentCauseAnalysisSystemsUsed;
  final String? investigationActionStatus;
  final String? dateClosed;
  final dynamic signature;

  const InvestigationStatusData({
    this.incidentCauseAnalysisSystemsUsed,
    this.investigationActionStatus,
    this.dateClosed,
    this.signature,
  });

  factory InvestigationStatusData.fromJson(Map<String, dynamic> json) {
    return InvestigationStatusData(
      incidentCauseAnalysisSystemsUsed:
          json['incidentCauseAnalysisSystemsUsed']?.toString(),
      investigationActionStatus: json['investigationActionStatus']?.toString(),
      dateClosed: json['dateClosed']?.toString(),
      signature: json['signature'],
    );
  }
}
